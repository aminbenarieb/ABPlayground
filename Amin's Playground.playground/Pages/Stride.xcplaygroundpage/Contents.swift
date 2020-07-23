//: [Previous](@previous)

import Foundation
import Accelerate

let array = (0..<10).map { Float($0) }
let interleavedPixels = stride(from: 0, to: array.count, by: 2).map {
    return DSPComplex(real: array[$0],
                      imag: array[$0.advanced(by: 1)])
}

var splitComplex: DSPSplitComplex!
var reals = [Float](repeating: 0, count: array.count)
var imags = [Float](repeating: 0, count: array.count)
//reals.withUnsafeMutableBufferPointer { realPtr in
//imags.withUnsafeMutableBufferPointer { imagPtr in
//    splitComplex = DSPSplitComplex(
//        realp: realPtr.baseAddress!,
//        imagp: imagPtr.baseAddress!
//    )
//}
//}
splitComplex = DSPSplitComplex(
    realp: &reals,
    imagp: &imags
)


vDSP.convert(interleavedComplexVector: interleavedPixels, toSplitComplexVector: &splitComplex)

var interleavedPixelsRev = [DSPComplex](repeating: DSPComplex(real: 0, imag: 0), count: array.count / 2)
vDSP.convert(splitComplexVector: splitComplex, toInterleavedComplexVector: &interleavedPixelsRev)

//: [Next](@next)
