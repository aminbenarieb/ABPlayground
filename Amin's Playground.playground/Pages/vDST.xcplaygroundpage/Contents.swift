import Accelerate
import CoreGraphics
import CoreServices
import Foundation
import ImageIO
import PlaygroundSupport
import UIKit

typealias PixelType = Double
typealias SplitComplexType = DSPDoubleSplitComplex
typealias ComplexType = DSPDoubleComplex

let srcRaw: CGImage = UIImage(named: "src.jpg")!.cgImage!
let dstRaw: CGImage = UIImage(named: "dst.jpg")!.cgImage!
var sizeRaw = CGSize(width: srcRaw.width, height: srcRaw.height)

// let resolution: CGFloat = 120.0
// let resolution: CGFloat = CGFloat(srcRaw.height)
// let size = CGSize(width: Int(sizeRaw.width * resolution / sizeRaw.height), height: Int(resolution))
let size = CGSize(width: 1024, height: 512)
let src = try srcRaw.grayScale().scaled(size: size)
let dst = try dstRaw.grayScale().scaled(size: size)

guard
    size == CGSize(width: src.width, height: src.height),
    size == CGSize(width: dst.width, height: dst.height)
else {
    throw CellyError(message: "Source or destination image size mismatch with set up size")
}

let pixelCount = Int(size.width) * Int(size.height)
let n = pixelCount / 2
//  --------------------
let srcPixels: [PixelType] = try src.pixels()
var src_real: [PixelType] = srcPixels
var src_imaginary = [PixelType](
    repeating: 0,
    count: n
)
var srcImageSplitComplex: SplitComplexType!
src_real.withUnsafeMutableBufferPointer { real_ptr in
    src_imaginary.withUnsafeMutableBufferPointer { imag_ptr in
        srcImageSplitComplex = SplitComplexType(
            realp: real_ptr.baseAddress!,
            imagp: imag_ptr.baseAddress!
        )
    }
}

src_real
src_imaginary

let dstPixels: [PixelType] = try dst.pixels()
var dst_real: [PixelType] = dstPixels
var dst_imaginary = [PixelType](repeating: 0, count: pixelCount)
var dstImageSplitComplex: SplitComplexType!
dst_real.withUnsafeMutableBufferPointer { real_ptr in
    dst_imaginary.withUnsafeMutableBufferPointer { imag_ptr in
        dstImageSplitComplex = SplitComplexType(
            realp: real_ptr.baseAddress!,
            imagp: imag_ptr.baseAddress!
        )
    }
}

dst_real
dst_imaginary
//  --------------------
var fftSetUp = vDSP.FFT2D(
    width: Int(size.width),
    height: Int(size.height),
    ofType: SplitComplexType.self
)!
let log2n = vDSP_Length(log2(Float(size.width * size.height)))
let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2))!
var src_frequency_real = [PixelType](
    repeating: 0,
    count: n
)
var src_frequency_imaginary = [PixelType](
    repeating: 0,
    count: n
)
var srcFreqImageSplitComplex: SplitComplexType!

var dst_frequency_real = [PixelType](
    repeating: 0,
    count: n
)
var dst_frequency_imaginary = [PixelType](
    repeating: 0,
    count: n
)
var dstFreqImageSplitComplex: SplitComplexType!

var multi_product_real = [PixelType](
    repeating: 0,
    count: n
)
var multi_product_imaginary = [PixelType](
    repeating: 0,
    count: n
)
var multiProductSplitCompltex: SplitComplexType!

var ifft_product_real = [PixelType](
    repeating: 0,
    count: n
)
var ifft_product_imaginary = [PixelType](
    repeating: 0,
    count: n
)
var ifftMultiProductSplitComplex: SplitComplexType!

src_frequency_real.withUnsafeMutableBufferPointer { srcFreqRealPtr in
    src_frequency_imaginary.withUnsafeMutableBufferPointer { srcFreqImagPtr in
        srcFreqImageSplitComplex = SplitComplexType(
            realp: srcFreqRealPtr.baseAddress!,
            imagp: srcFreqImagPtr.baseAddress!
        )
        fftSetUp.transform(
            input: srcImageSplitComplex,
            output: &srcFreqImageSplitComplex,
            direction: .forward
        )
    }
}

// withUnsafePointer(to: &srcImageSplitComplex) { src_ptr in
// withUnsafeMutablePointer(to: &srcFreqImageSplitComplex) { dst_ptr in
//    vDSP_fft2d_zropD(
//        fftSetup,
//        src_ptr, 1, 0,
//        dst_ptr, 1, 0,
//        vDSP_Length(log2(Float(size.width))),
//        vDSP_Length(log2(Float(size.height))),
//        vDSP.FourierTransformDirection.forward.fftDirection
//    )
// }
// }
src_frequency_real
src_frequency_imaginary
var src_real_rev = [PixelType](repeating: 0, count: n)
var src_imaginary_rev = [PixelType](repeating: 0, count: n)
var src_complex_rev: SplitComplexType!
src_real_rev.withUnsafeMutableBufferPointer { realPtr in
    src_imaginary_rev.withUnsafeMutableBufferPointer { imagPtr in
        src_complex_rev = SplitComplexType(
            realp: realPtr.baseAddress!,
            imagp: imagPtr.baseAddress!
        )
        fftSetUp.transform(
            input: srcFreqImageSplitComplex,
            output: &src_complex_rev,
            direction: .inverse
        )
    }
}

src_real_rev
src_imaginary_rev

dst_frequency_real.withUnsafeMutableBufferPointer { dstFreqRealPtr in
    dst_frequency_imaginary.withUnsafeMutableBufferPointer { dstFreqImagPtr in
        dstFreqImageSplitComplex = SplitComplexType(
            realp: dstFreqRealPtr.baseAddress!,
            imagp: dstFreqImagPtr.baseAddress!
        )
        fftSetUp.transform(
            input: dstImageSplitComplex,
            output: &dstFreqImageSplitComplex,
            direction: .forward
        )
    }
}

// withUnsafePointer(to: &dstImageSplitComplex) { src_ptr in
// withUnsafeMutablePointer(to: &dstFreqImageSplitComplex) { dst_ptr in
//    vDSP_fft2d_zropD(
//        fftSetup,
//        src_ptr, 1, 0,
//        dst_ptr, 1, 0,
//        vDSP_Length(log2(Float(size.width))),
//        vDSP_Length(log2(Float(size.height))),
//        vDSP.FourierTransformDirection.forward.fftDirection
//    )
// }
// }
dst_frequency_real
dst_frequency_imaginary

multi_product_real.withUnsafeMutableBufferPointer { multiProductRealPtr in
    multi_product_imaginary.withUnsafeMutableBufferPointer { multiProductImagPtr in
        multiProductSplitCompltex = SplitComplexType(
            realp: multiProductRealPtr.baseAddress!,
            imagp: multiProductImagPtr.baseAddress!
        )
    }
}

vDSP.multiply(
    srcFreqImageSplitComplex,
    by: dstFreqImageSplitComplex,
    count: pixelCount,
    useConjugate: true,
    result: &multiProductSplitCompltex
)
multi_product_real
multi_product_imaginary

ifft_product_real.withUnsafeMutableBufferPointer { ifftMultiProductRealPtr in
    ifft_product_imaginary.withUnsafeMutableBufferPointer { ifftMultiProductImagPtr in
        ifftMultiProductSplitComplex = SplitComplexType(
            realp: ifftMultiProductRealPtr.baseAddress!,
            imagp: ifftMultiProductImagPtr.baseAddress!
        )
    }
}

// withUnsafePointer(to: &multiProductSplitCompltex) { src_ptr in
// withUnsafeMutablePointer(to: &ifftMultiProductSplitComplex) { dst_ptr in
//    vDSP_fft2d_zropD(
//        fftSetup,
//        src_ptr, 1, 0,
//        dst_ptr, 1, 0,
//        vDSP_Length(log2(Float(size.width))),
//        vDSP_Length(log2(Float(size.height))),
//        vDSP.FourierTransformDirection.inverse.fftDirection
//    )
// }
// }
fftSetUp.transform(
    input: multiProductSplitCompltex,
    output: &ifftMultiProductSplitComplex,
    direction: .inverse
)
ifft_product_real
ifft_product_imaginary
// CGImage.create(
//    pixelSource: &ifftMultiProductSplitComplex,
//    width: src.width,
//    height: src.height,
//    bitmapInfo: CGBitmapInfo(rawValue: 0)
// )

// STEP 5
let correlation = [PixelType](
    fromSplitComplex: ifftMultiProductSplitComplex,
    scale: 1,
    count: pixelCount
)

// var correlation = [PixelType](repeating: 0, count: pixelCount)
// vDSP.squareMagnitudes(ifftMultiProductSplitComplex, result: &correlation)
let maxima = vDSP.indexOfMaximum(correlation)
src.bytesPerRow
src.width

for _ in 0..<1 {
    let bytesPerRow = UInt(src.bytesPerRow)
    var xMaxima = CGFloat(maxima.0 % bytesPerRow)
    var yMaxima = CGFloat(maxima.0 / bytesPerRow)
    if xMaxima > size.width / 2 {
        xMaxima -= size.width
    }
    if yMaxima > size.height / 2 {
        yMaxima -= size.height
    }

    let point = CGPoint(
        x: xMaxima,
        y: yMaxima
    )
    print(point)
}

for _ in 0..<1 {
    let bytesPerRow = UInt(src.width * MemoryLayout<Int8>.size)
    var xMaxima = CGFloat(maxima.0 % bytesPerRow)
    var yMaxima = CGFloat(maxima.0 / bytesPerRow)
    if xMaxima > size.width / 2 {
        xMaxima -= size.width
    }
    if yMaxima > size.height / 2 {
        yMaxima -= size.height
    }

    let point = CGPoint(
        x: xMaxima,
        y: yMaxima
    )
    print(point)
}

//: [Next](@next)
