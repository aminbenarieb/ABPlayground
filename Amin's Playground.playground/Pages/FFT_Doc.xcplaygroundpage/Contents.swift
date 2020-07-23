//: [Previous](@previous)

import Foundation
import Accelerate

let width = 256
let height = 256
let pixelCount = width * height
let n = pixelCount / 2

let pixels: [Float] = (0 ..< pixelCount).map { i in
    return abs(sin(Float(i) * 0.001 * 2))
}

var sourceImageReal = [Float](repeating: 0, count: n)
var sourceImageImaginary = [Float](repeating: 0, count: n)

var sourceImage = DSPSplitComplex(fromInputArray: pixels,
                                  realParts: &sourceImageReal,
                                  imaginaryParts: &sourceImageImaginary)
sourceImageReal
sourceImageImaginary
let pixelsRecreated = [Float](fromSplitComplex: sourceImage,
                              scale: 1, count: pixelCount)

pixelsRecreated.elementsEqual(pixels)

// Create FFT2D object
let fft2D = vDSP.FFT2D(width: 256,
                       height: 256,
                       ofType: DSPSplitComplex.self)!

// New style transform
var transformedImageReal = [Float](repeating: 0,
                                   count: n)
var transformedImageImaginary = [Float](repeating: 0,
                                        count: n)
var transformedImage = DSPSplitComplex(
    realp: &transformedImageReal,
    imagp: &transformedImageImaginary)

fft2D.transform(input: sourceImage,
                output: &transformedImage,
                direction: .forward)
transformedImageReal
transformedImageImaginary


var transformedImageRealRev = [Float](repeating: 0,
                                   count: n)
var transformedImageImaginaryRev = [Float](repeating: 0,
                                        count: n)
var transformedImageRev = DSPSplitComplex(
    realp: &transformedImageRealRev,
    imagp: &transformedImageImaginaryRev)

fft2D.transform(input: transformedImage,
                output: &transformedImageRev,
                direction: .inverse)
transformedImageRealRev
transformedImageImaginaryRev

//var abs = [Float](repeating: 0, count: n)
//vDSP.absolute(transformedImageRev, result: &abs)

//: [Next](@next)
