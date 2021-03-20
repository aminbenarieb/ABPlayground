import Accelerate
import Foundation

// Shift from correlation matrix
// for _ in 0..<1 {
//    print("Reading...")
//    let correlation: [Double] = try! Array<Double>.array_double(from: "python_real.txt", delimeter: "\n")
//    let maxima = vDSP.indexOfMaximum(correlation)
//    //let bytesPerRow = UInt(src.bytesPerRow)
//    let size = CGSize(width: 1082, height: 570)
//    let bytesPerRow = UInt(size.width * CGFloat(MemoryLayout<Int8>.size))
//    var xMaxima = CGFloat(maxima.0 % bytesPerRow)
//    var yMaxima = CGFloat(maxima.0 / bytesPerRow)
//    if xMaxima > size.width / 2 {
//        xMaxima -= size.width
//    }
//    if yMaxima > size.height / 2 {
//        yMaxima -= size.height
//    }
//    let point = CGPoint(x: xMaxima, y: yMaxima)
//    print("Reading done")
// }

// Shift from complex correlation matrix
// for _ in 0..<1 {
//    print("Reading...")
//    let file = "correlation_complex.txt"
//    let delimeter = "\n"
//    var (realParts, imagParts) = try! Array<Double>.array_complex_double(from: file, delimeter: delimeter)
//    var correlation_complex: DSPDoubleSplitComplex!
//    realParts.withUnsafeMutableBufferPointer { realPtr in
//        imagParts.withUnsafeMutableBufferPointer { imagPtr in
//            correlation_complex = DSPDoubleSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
//        }
//    }
//    assert(realParts.count == imagParts.count)
//    let pixelCount = realParts.count// + imagParts.count
//    var correlation = [Double](repeating: 0, count: pixelCount)
//
//    var interleavedPixelsRev = [DSPDoubleComplex](
//        repeating: DSPDoubleComplex(real: 0, imag: 0),
//        count: pixelCount
//    )
//    realParts
//    imagParts
//    vDSP.convert(
//        splitComplexVector: correlation_complex,
//        toInterleavedComplexVector: &interleavedPixelsRev
//    )
//
//    vDSP.squareMagnitudes(correlation_complex, result: &correlation)
//    let maxima = vDSP.indexOfMaximum(correlation)
//    //let bytesPerRow = UInt(src.bytesPerRow)
//    let size = CGSize(width: 1082, height: 570)
//    let bytesPerRow = UInt(size.width * CGFloat(MemoryLayout<Int8>.size))
//    var xMaxima = CGFloat(maxima.0 % bytesPerRow)
//    var yMaxima = CGFloat(maxima.0 / bytesPerRow)
//    if xMaxima > size.width / 2 {
//        xMaxima -= size.width
//    }
//    if yMaxima > size.height / 2 {
//        yMaxima -= size.height
//    }
//    CGPoint(x: xMaxima, y: yMaxima)
//    print("Reading done")
// }

// Shift from complex multiplication product
for _ in 0..<1 {
    let size = CGSize(width: 1082, height: 570)
    print("Reading...")
    let file = "mul_complex.txt"
    let delimeter = "\n"
    var (realParts, imagParts) = try! Array<Double>
        .array_complex_double(from: file, delimeter: delimeter)
    var mul_complex_freq: DSPDoubleSplitComplex!
    realParts.withUnsafeMutableBufferPointer { realPtr in
        imagParts.withUnsafeMutableBufferPointer { imagPtr in
            mul_complex_freq = DSPDoubleSplitComplex(
                realp: realPtr.baseAddress!,
                imagp: imagPtr.baseAddress!
            )
        }
    }
    assert(realParts.count == imagParts.count)
    let width = Int(size.width)
    let height = Int(size.height)
    let pixelCount = width * height
    let n = pixelCount / 2
//    [Double](
//        fromSplitComplex: mul_complex,
//        scale: 1,
//        count: n
//    )
    var interleavedPixels = [DSPDoubleComplex](
        repeating: DSPDoubleComplex(real: 0, imag: 0),
        count: n
    )
    vDSP.convert(
        splitComplexVector: mul_complex_freq,
        toInterleavedComplexVector: &interleavedPixels
    )
    var correlation_complex_real = [Double](repeating: 0, count: n)
    var correlation_complex_imag = [Double](repeating: 0, count: n)
    var correlation_complex: DSPDoubleSplitComplex!
    correlation_complex_real.withUnsafeMutableBufferPointer { realPtr in
        correlation_complex_imag.withUnsafeMutableBufferPointer { imagPtr in
            correlation_complex = DSPDoubleSplitComplex(
                realp: realPtr.baseAddress!,
                imagp: imagPtr.baseAddress!
            )
        }
    }
    /// #####
//    let log2n = vDSP_Length(log2(Float(size.width * size.height)))
//    let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2))!
//    withUnsafePointer(to: &mul_complex_freq) { mul_complex_freq_ptr in
//        withUnsafeMutablePointer(to: &correlation_complex) { correlation_complex_ptr in
    ////            vDSP_fft2d_zripD(
    ////                <#T##__Setup: FFTSetupD##FFTSetupD#>,
    ////                <#T##__C: UnsafePointer<DSPDoubleSplitComplex>##UnsafePointer<DSPDoubleSplitComplex>#>,
    ////                <#T##__IC0: vDSP_Stride##vDSP_Stride#>,
    ////                <#T##__IC1: vDSP_Stride##vDSP_Stride#>,
    ////                <#T##__Log2N0: vDSP_Length##vDSP_Length#>,
    ////                <#T##__Log2N1: vDSP_Length##vDSP_Length#>,
    ////                <#T##__flag: FFTDirection##FFTDirection#>
    ////            )
//            vDSP_fft2d_zropD(
//                fftSetup,
//                mul_complex_freq_ptr, 2, 0,
//                correlation_complex_ptr, 1, 0,
//                vDSP_Length(log2(Float(n))),
//                vDSP_Length(log2(Float(n))),
//                vDSP.FourierTransformDirection.inverse.fftDirection
//            )
//        }
//    }
    let fft2d = vDSP.FFT2D(
        width: Int(size.width),
        height: Int(size.height),
        ofType: DSPDoubleSplitComplex.self
    )!
    fft2d.transform(
        input: mul_complex_freq,
        output: &correlation_complex,
        direction: .inverse
    )
    /// #####
    var interleavedPixelsRev = [DSPDoubleComplex](
        repeating: DSPDoubleComplex(real: 0, imag: 0),
        count: n
    )
    correlation_complex_real
    correlation_complex_imag
    vDSP.convert(
        splitComplexVector: correlation_complex,
        toInterleavedComplexVector: &interleavedPixelsRev
    )
    let correlation = [Double](
        fromSplitComplex: correlation_complex,
        scale: 1,
        count: n
    )
//    var correlation = [Double](repeating: 0, count: n)
//    vDSP.squareMagnitudes(correlation_complex, result: &correlation)
    let maxima = vDSP.indexOfMaximum(correlation)
//    let bytesPerRow = UInt(src.bytesPerRow)
    let bytesPerRow = UInt(size.width * CGFloat(MemoryLayout<Int8>.size))
    var xMaxima = CGFloat(maxima.0 % bytesPerRow)
    var yMaxima = CGFloat(maxima.0 / bytesPerRow)
    if xMaxima > size.width / 2 {
        xMaxima -= size.width
    }
    if yMaxima > size.height / 2 {
        yMaxima -= size.height
    }
    CGPoint(x: xMaxima, y: yMaxima)
    print("Reading done")
}

////: [Next](@next)
