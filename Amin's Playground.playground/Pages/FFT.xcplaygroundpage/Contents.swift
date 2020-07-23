//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import CoreGraphics
import Accelerate
import ImageIO
import CoreServices
import UIKit

typealias PixelType = Double
typealias SplitComplexType = DSPDoubleSplitComplex
typealias ComplexType = DSPDoubleComplex

let srcRaw: CGImage = UIImage(named: "src.jpg")!.cgImage!
let dstRaw: CGImage = UIImage(named: "dst.jpg")!.cgImage!
var sizeRaw = CGSize(width: srcRaw.width, height: srcRaw.height)

//let resolution: CGFloat = 120.0
//let resolution: CGFloat = CGFloat(srcRaw.height)
//let size = CGSize(width: Int(sizeRaw.width * resolution / sizeRaw.height), height: Int(resolution))
let size = CGSize(width: 1024, height: 512)
let src = try srcRaw.grayScale().scaled(size: size)
let dst = try dstRaw.grayScale().scaled(size: size)

guard size == CGSize(width: src.width, height: src.height),
    size == CGSize(width: dst.width, height: dst.height) else {
        throw CellyError(message: "Source or destination image size mismatch with set up size")
}

let pixelCount = Int(size.width) * Int(size.height)
let n = pixelCount / 2
//  --------------------
let srcPixels: [PixelType] = try src.pixels()
var src_real: [PixelType] = srcPixels
var src_imaginary = [PixelType](repeating: 0,
                            count: n)
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
//  --------------------
var fftSetUp = vDSP.FFT2D(
    width: Int(size.width),
    height: Int(size.height),
    ofType: SplitComplexType.self
)!
let log2n = vDSP_Length(log2(Float(size.width * size.height)))
let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2))!
var src_frequency_real = [PixelType](repeating: 0,
                                     count: n)
var src_frequency_imaginary = [PixelType](repeating: 0,
                                          count: n)
var srcFreqImageSplitComplex: SplitComplexType!

src_frequency_real.withUnsafeMutableBufferPointer { srcFreqRealPtr in
src_frequency_imaginary.withUnsafeMutableBufferPointer { srcFreqImagPtr in
    srcFreqImageSplitComplex = SplitComplexType(
        realp: srcFreqRealPtr.baseAddress!,
        imagp: srcFreqImagPtr.baseAddress!)
//    fftSetUp.transform(input: srcImageSplitComplex,
//                            output: &srcFreqImageSplitComplex,
//                            direction: .forward)
}
}
withUnsafePointer(to: &srcImageSplitComplex) { src_ptr in
withUnsafeMutablePointer(to: &srcFreqImageSplitComplex) { dst_ptr in
    vDSP_fft2d_zropD(
        fftSetup,
        src_ptr, 1, 0,
        dst_ptr, 1, 0,
        vDSP_Length(log2(Float(size.width))),
        vDSP_Length(log2(Float(size.height))),
        vDSP.FourierTransformDirection.forward.fftDirection
    )
}
}
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
//    fftSetUp.transform(
//        input: srcFreqImageSplitComplex,
//        output: &src_complex_rev,
//        direction: .inverse
//    )
}
}
withUnsafePointer(to: &srcFreqImageSplitComplex) { src_ptr in
withUnsafeMutablePointer(to: &src_complex_rev) { dst_ptr in
    vDSP_fft2d_zropD(
        fftSetup,
        src_ptr, 1, 0,
        dst_ptr, 1, 0,
        vDSP_Length(log2(Float(size.width))),
        vDSP_Length(log2(Float(size.height))),
        vDSP.FourierTransformDirection.inverse.fftDirection
    )
}
}
src_real_rev
src_imaginary_rev
