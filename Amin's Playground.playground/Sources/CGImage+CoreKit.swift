import Accelerate
import CoreGraphics
import CoreImage
import Foundation
import VideoToolbox

// MARK: - Vars

public extension CGImage {
    var size: CGSize {
        CGSize(width: self.width, height: self.height)
    }
}

// MARK: - Construction

public extension CGImage {
    static func create(from url: URL) throws -> CGImage {
        guard let dataProvider = CGDataProvider(filename: url.absoluteString) else {
            throw CellyError(message: "Unable to get data from \(url)")
        }

        let imageRaw: CGImage?
        switch url.pathExtension {
        case "jpg":
            imageRaw = CGImage(
                jpegDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        case "png":
            imageRaw = CGImage(
                jpegDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        default:
            throw CellyError(message: "Unsupported image extension \(url.pathExtension)")
        }
        guard let image = imageRaw else {
            throw CellyError(message: "Unable to retrive image from \(url)")
        }
        return image
    }

//    static func createRandom(size: CGSize) throws -> CGImage {
//        let width = Int(size.width)
//        let height = Int(size.height)
//        let pixels: [UInt8] = (0..<width*height)
//            .map {_ in
//                [UInt8.random(in: 0...255),
//                 UInt8.random(in: 0...255),
//                 UInt8.random(in: 0...255),
//                 UInt8.random(in: 0...255)]
//        }
//        .flatMap  { $0 }
//        return try CGImage.createRGBA(
//            pixels:pixels,
//            width: width,
//            height: height,
//            bitsPerPixel: 4
//        )
//    }

    static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
        let spid = OSSignpostID(log: .corekit)
        os_signpost(
            .begin,
            log: .corekit,
            name: "CVPixelBuffer2CGImage",
            signpostID: spid
        )
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        os_signpost(
            .end,
            log: .corekit,
            name: "CVPixelBuffer2CGImage",
            signpostID: spid
        )
        return cgImage
    }

    static func createRGBA<T>(
        pixels: [T],
        width: Int,
        height: Int,
        bytesPerRow: Int,
        bitsPerComponent: Int = 8,
        colorSpace: CGColorSpace,
        bitmapInfo: CGBitmapInfo
    ) throws -> CGImage {
        var pixels = pixels
        let cgImage = pixels.withUnsafeMutableBytes { (ptr) -> CGImage? in
            let ctx = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            )
            return ctx?.makeImage()
        }
        guard let result = cgImage else {
            throw CellyError(message: "Unable to create image from provided pixels")
        }
        return result
    }

    static func create(
        pixelSource: inout DSPDoubleSplitComplex,
        width: Int,
        height: Int,
        denominator: Float = pow(2, 29),
        bitmapInfo: CGBitmapInfo
    ) -> CGImage? {
        let pixelCount = width * height
        let n = vDSP_Length(pixelCount / 2)
        let stride = vDSP_Stride(1)

        // multiply all float values (1 / denominator) * 255
        let multiplier = [Double](
            repeating: Double((1 / denominator) * 255),
            count: pixelCount / 2
        )

        vDSP.multiply(
            pixelSource,
            by: multiplier,
            result: &pixelSource
        )

        // Clip values to 0...255
        var low: Double = 0
        var high: Double = 255

        vDSP_vclipD(
            pixelSource.realp,
            stride,
            &low,
            &high,
            pixelSource.realp,
            stride,
            n
        )

        vDSP_vclipD(
            pixelSource.imagp,
            stride,
            &low,
            &high,
            pixelSource.imagp,
            stride,
            n
        )

        var uIntPixels = [UInt8](
            repeating: 0,
            count: pixelCount
        )

        let floatPixels = [Double](
            fromSplitComplex: pixelSource,
            scale: 1,
            count: pixelCount
        )

        vDSP.convertElements(
            of: floatPixels,
            to: &uIntPixels,
            rounding: .towardZero
        )

        let result: CGImage? = uIntPixels.withUnsafeMutableBufferPointer { uIntPixelsPtr in

            let buffer = vImage_Buffer(
                data: uIntPixelsPtr.baseAddress!,
                height: vImagePixelCount(height),
                width: vImagePixelCount(width),
                rowBytes: width
            )

            if
                let format = vImage_CGImageFormat(
                    bitsPerComponent: 8,
                    bitsPerPixel: 8,
                    colorSpace: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: bitmapInfo
                ),
                let cgImage = try? buffer.createCGImage(format: format)
            {
                return cgImage
            }
            else {
                print("Unable to create `CGImage`.")
                return nil
            }
        }

        return result
    }
}

// MARK: - Cropping

@available(iOS 13.0, *)
extension CGImage {
    public func cropped(rect: CGRect) throws -> CGImage {
        guard let image = self.cropping(to: rect) else {
            throw CellyError(message: "Unable to crop image with rect \(rect)")
        }

        return image
    }
}

// MARK: - Scale

@available(iOS 13.0, *)
extension CGImage {
    public func scaled(
        size: CGSize,
        interpolationQuality: CGInterpolationQuality = .high
    ) throws -> CGImage {
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: self.bitsPerComponent,
            bytesPerRow: self.bytesPerRow,
            space: self.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: self.bitmapInfo.rawValue
        )
        context?.interpolationQuality = interpolationQuality
        context?.draw(self, in: CGRect(origin: .zero, size: size))
        guard let scaledImage = context?.makeImage() else {
            throw CellyError(message: "Unable to scale image with size \(size)")
        }

        return scaledImage
    }
}

// MARK: Pixel

public struct Pixel {
    var r: Float
    var g: Float
    var b: Float
    var a: Float
    var row: Int
    var col: Int

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8, row: Int, col: Int) {
        self.r = Float(r)
        self.g = Float(g)
        self.b = Float(b)
        self.a = Float(a)
        self.row = row
        self.col = col
    }

    var description: String {
        return "RGBA(\(self.r), \(self.g), \(self.b), \(self.a))"
    }
}

public extension CGImage {
    func pixels(by component: Int) -> [UInt8] {
        guard let uncastedData = self.dataProvider?.data else {
            return []
        }

        var data: UnsafePointer<UInt8> = CFDataGetBytePtr(uncastedData)
        var pixelComponents = [UInt8]()
        data = data.advanced(by: component)
        for _ in 0..<Int(self.height) {
            for _ in 0..<Int(self.width) {
                pixelComponents.append(data.pointee)
                data = data.advanced(by: 4)
            }
        }
        return pixelComponents
    }

    func pixels() -> [UInt8] {
        let pixelCount = Int(self.width * self.height)
        let pixelData = self.dataProvider!.data
        let pixelsArray = Array(UnsafeBufferPointer(
            start: CFDataGetBytePtr(pixelData),
            count: pixelCount * 4
        ))
        return pixelsArray
    }

    func pixelData() -> [Pixel] {
        guard let provider = self.dataProvider else {
            return []
        }
        let bmp = provider.data
        var data: UnsafePointer<UInt8> = CFDataGetBytePtr(bmp)
        var r, g, b, a: UInt8
        var pixels: [Pixel] = []

        for row in 0..<Int(self.height) {
            for col in 0..<Int(self.width) {
                r = data.pointee
                data = data.advanced(by: 1)
                g = data.pointee
                data = data.advanced(by: 1)
                b = data.pointee
                data = data.advanced(by: 1)
                a = data.pointee
                data = data.advanced(by: 1)
                pixels.append(Pixel(r: r, g: g, b: b, a: a, row: row, col: col))
            }
        }

        return pixels
    }

    @available(iOS 13.0, *)
    func pixels<F>() throws -> [F] where F: vDSP_FloatingPointConvertable {
        let pixelCount = Int(self.width * self.height)
        guard let pixelData = self.dataProvider?.data else {
            throw CellyError(message: "Image data provider is nil")
        }
        let pixelsArray = Array(UnsafeBufferPointer(
            start: CFDataGetBytePtr(pixelData),
            count: pixelCount
        ))
        let pixels = vDSP.integerToFloatingPoint(
            pixelsArray,
            floatingPointType: F.self
        )
        return pixels
    }
}

// MARK: Grayscale

public extension CGImage {
    func grayScale() throws -> CGImage {
        // Preparing Coefficients Matrix & Co
        // Coefficients that model the eye's sensitivity to color.
        let redCoefficient: Float = 0.299
        let greenCoefficient: Float = 0.587
        let blueCoefficient: Float = 0.114
        // Three luma coefficients that
        // specify the color-to-grayscale conversion.
        let divisor: Int32 = 1000
        let fDivisor = Float(divisor)
        var coefficientsMatrix = [
            Int16(redCoefficient * fDivisor),
            Int16(greenCoefficient * fDivisor),
            Int16(blueCoefficient * fDivisor),
        ]

        // Preparing Source Image Buffer
        guard let format = vImage_CGImageFormat(cgImage: self) else {
            throw CellyError(message: "Unable to create image format!")
        }
        var sourceBuffer = try vImage_Buffer(
            cgImage: self,
            format: format
        )
        var scaledSourceBuffer = try vImage_Buffer(
            width: Int(sourceBuffer.width),
            height: Int(sourceBuffer.height),
            bitsPerPixel: format.bitsPerPixel
        )
        defer {
            sourceBuffer.free()
        }
        let error = vImageScale_ARGB8888(
            &sourceBuffer,
            &scaledSourceBuffer,
            nil,
            vImage_Flags(kvImageNoFlags)
        )
        guard error == kvImageNoError else {
            throw CellyError(message: "Error on scale operation: \(error)")
        }

        // Preparing Destination Image Buffer
        var destinationBuffer = try vImage_Buffer(
            width: Int(scaledSourceBuffer.width),
            height: Int(scaledSourceBuffer.height),
            bitsPerPixel: format.bitsPerPixel
        )

        // Conversion to 8-bit:
        // Scalar luminance by returning the dot product
        // of each RGB pixel and the coefficients
        let preBias: [Int16] = [0, 0, 0, 0]
        let postBias: Int32 = 0
        vImageMatrixMultiply_ARGB8888ToPlanar8(
            &scaledSourceBuffer,
            &destinationBuffer,
            &coefficientsMatrix,
            divisor,
            preBias,
            postBias,
            vImage_Flags(kvImageNoFlags)
        )

        // Create a 1-channel, 8-bit grayscale format that's used to
        // generate a displayable image.
        guard
            let monoFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                colorSpace: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                renderingIntent: .defaultIntent
            )
        else {
            throw CellyError(message: "Unable to create mono format!")
        }

        return try destinationBuffer.createCGImage(format: monoFormat)
    }
}

private extension CGImage {
    // MARK: Contructorss CVPixelBuffer

    /**
     Resizes the image to width x height and converts it to an RGB CVPixelBuffer.
     */
    func pixelBuffer(
        width: Int,
        height: Int,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer? {
        return self.pixelBuffer(
            width: width,
            height: height,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            alphaInfo: .noneSkipFirst,
            orientation: orientation
        )
    }

    /**
     Resizes the image to width x height and converts it to a grayscale CVPixelBuffer.
     */
    func pixelBufferGray(
        width: Int,
        height: Int,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer? {
        return self.pixelBuffer(
            width: width,
            height: height,
            pixelFormatType: kCVPixelFormatType_OneComponent8,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            alphaInfo: .none,
            orientation: orientation
        )
    }

    func pixelBuffer(
        width: Int,
        height: Int,
        pixelFormatType: OSType,
        colorSpace: CGColorSpace,
        alphaInfo: CGImageAlphaInfo,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer? {
        // TODO: If the orientation is not .up, then rotate the CGImage.
        // See also: https://stackoverflow.com/a/40438893/
        assert(orientation == .up)

        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormatType,
            attrs as CFDictionary,
            &maybePixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }

        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
            return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }

        guard
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(pixelBuffer),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: colorSpace,
                bitmapInfo: alphaInfo.rawValue
            )
        else {
            return nil
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelBuffer
    }

    // MARK: Contructorss CVPixelBuffer, CIContext

    static func create(
        pixelBuffer: CVPixelBuffer,
        context: CIContext
    ) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let rect = CGRect(
            x: 0,
            y: 0,
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        return context.createCGImage(ciImage, from: rect)
    }

    // MARK: Contructorss vImage_Buffer

    static func create(
        planarBuffer: vImage_Buffer,
        orientation: CGImagePropertyOrientation
    ) throws -> CGImage? {
        guard
            let monoFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                colorSpace: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: []
            )
        else {
            return nil
        }

        var outputBuffer: vImage_Buffer
        var outputRotation: Int

        if orientation == .right || orientation == .left {
            outputBuffer = try vImage_Buffer(
                width: Int(planarBuffer.height),
                height: Int(planarBuffer.width),
                bitsPerPixel: 8
            )

            outputRotation = orientation == .right ?
                kRotate90DegreesClockwise : kRotate90DegreesCounterClockwise
        }
        else if orientation == .up || orientation == .down {
            outputBuffer = try vImage_Buffer(
                width: Int(planarBuffer.width),
                height: Int(planarBuffer.height),
                bitsPerPixel: 8
            )
            outputRotation = orientation == .down ?
                kRotate180DegreesClockwise : kRotate0DegreesClockwise
        }
        else {
            throw CellyError(message: "Unsupported orientation")
        }
        defer {
            outputBuffer.free()
        }

        var error = kvImageNoError
        _ = withUnsafePointer(to: planarBuffer) { src in
            error = vImageRotate90_Planar8(
                src,
                &outputBuffer,
                UInt8(outputRotation),
                0,
                vImage_Flags(kvImageNoFlags)
            )
        }

        if error != kvImageNoError {
            return nil
        }

        return try? outputBuffer.createCGImage(format: monoFormat)
    }
}
