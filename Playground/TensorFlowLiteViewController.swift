import Foundation
import UIKit
import TensorFlowLite
import Accelerate
import CoreGraphics
import CoreImage
import Foundation
// FakeCamera
import AVFoundation
import Combine
import Foundation
import Photos
import ReplayKit
import Accelerate
import CoreGraphics
import CoreImage
import Foundation
import UIKit
import VideoToolbox
import SnapKit
//
import NSLogger

struct OverlayViewModel {
    let objectOverlays: [ObjectOverlay]
}

struct ObjectOverlay {
    let name: String?
    let borderRect: CGRect
    let nameStringSize: CGSize?
    let color: UIColor
    let dashed: [CGFloat]?
    let font: UIFont
}

class TensorFlowLiteViewController: UIViewController, CameraFeedManagerDelegate {
    
    var overlayView: OverlayView!
    var impl: InferenceInterpreterTFWrapperOverCoreMLImpl!
    var playerView: PlayerView!
    
    override func viewDidLoad() {
        self.view.backgroundColor = .white
        self.impl = try! InferenceInterpreterTFWrapperOverCoreMLImpl(config: .init(
            model: "254.tflite",
//            model: "253_old.tflite",
            cellClasses: [.init(id: 0, name: "WBC", class: .wbc, color: nil, weigth: nil)],
            iouThreshold: 0.6,
            confidenceThreshold: 0.2,
            threadCount: nil
        ))
        playerView = PlayerView()
        playerView.playerLayer.videoGravity = .resize
        view.addSubview(playerView)
        playerView.snp.makeConstraints( { make in
            make.size.equalToSuperview()
        })
        self.overlayView = OverlayView()
        overlayView.backgroundColor = .clear
        playerView.addSubview(overlayView)
        overlayView.snp.makeConstraints( { make in
            make.edges.equalToSuperview()
            make.size.equalToSuperview()
        })
        overlayView.clearsContextBeforeDrawing = true
        let cameraFeedManager = CameraFeedManagerFakeImpl()
        let videoURL: URL!  = Bundle.main.url(
//            forResource: "on_debug/wbc_microscope_01.mov",
//            forResource: "on_debug/wbc.mp4",
            forResource: "on_debug/005_720p_30fps.mov",
            withExtension: nil
        )
        try! cameraFeedManager.configure(configuration: .init(
            videoURL: videoURL,
            playerView: playerView,
            fps: nil,
            frame: nil
        ), nil)
//        let imageFile = "on_debug/ab71317b-33d4-41d5-a3aa-4fa9c6a94836.jpg"
//        let imageFile = "on_debug/9c864b73-76d9-4003-871f-6c8d43d55777.jpg"
//        let imageURL: URL!  = Bundle.main.url(
//            forResource: imageFile,
//            withExtension: nil
//        )
//        let uiimage = UIImage(contentsOfFile: imageURL.path)!
//        let cgImage = uiimage.cgImage!
//        let cameraFeedManager = CameraFeedManagerFakeImageImpl(image: cgImage, playerView: playerView)
        cameraFeedManager.delegate = self
        try! cameraFeedManager.start()
    }
    
    func didVideoOutput(cgImage: CGImage?, error: Error?) {
        guard let cgImage = cgImage else { return  }
        Logger.shared.log(.service, .debug, "tensorflow-lite-viewcontroller | size | \(cgImage.width) x \(cgImage.height)")
        Logger.shared.log(.service, .debug, UIImage(cgImage: cgImage))
        let result = try! impl.inference(cgImage: cgImage)
        if !result.inferences.isEmpty {
            print("result | \(result.inferences.map { $0.confidence })")
        }
        DispatchQueue.main.async {
            self.draw(overlayViewModel: self.overlayModel(
                inferences: result.inferences,
                frameSize: CGSize(width: CGFloat(cgImage.width),
                                  height: CGFloat(cgImage.height))
            ))
        }
    }
    
    // Overlay
    

    func draw(overlayViewModel: OverlayViewModel?) {
        self.overlayView?.overlayViewModel = overlayViewModel
        self.overlayView?.setNeedsDisplay()
    }
    
    func overlayModel(inferences: [Inference], frameSize: CGSize) -> OverlayViewModel {
        // Tracked Bboxes
        var objectOverlays = [ObjectOverlay]()
        let overlays = inferences.map { inference -> ObjectOverlay in
            return self.overlayObject(
                rect: inference.rect,//self.overlayRect(inference: inference, origin: origin),
                number: nil,
                name: nil,
                confidence: inference.confidence,
                color: UIColor.blue.cgColor,
                dashed: [0.0, 12.0],
                overlayView: self.overlayView,
                frameSize: frameSize
            )
        }
        objectOverlays.append(contentsOf: overlays)
        return OverlayViewModel(objectOverlays: objectOverlays)
    }
    
    func overlayObject(
        rect: CGRect,
        number: Int?,
        name: String?,
        confidence: Float,
        classificationConfidence: Float? = nil,
        color: CGColor,
        dashed: [CGFloat]? = nil,
        overlayView: UIView,
        frameSize: CGSize
    ) -> ObjectOverlay {
        let convertedRect = rect
            .applying(CGAffineTransform(
                scaleX: overlayView.bounds.size.width / frameSize.width,
                y: overlayView.bounds.size.height / frameSize.height
            ))
        let color = UIColor(cgColor: color)
        let confidenceValue = Int(confidence * 100.0)
        let string = String(format: "%03ld%%", confidenceValue)
        let displayFont = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        let size = NSAttributedString(
                string: string,
                attributes: [NSAttributedString.Key.font: displayFont]
            ).size()
        let objectOverlay = ObjectOverlay(
            name: string,
            borderRect: convertedRect,
            nameStringSize: size,
            color: color,
            dashed: dashed,
            font: displayFont
        )

        return objectOverlay
    }

//    func overlayRect(inference: Inference, origin: CGPoint) -> CGRect {
//        let prevOrigin = rect.cgRect.origin - inference.rect.origin
//        let originChange = CGAffineTransform(
//            translationX: prevOrigin.x - origin.x,
//            y: prevOrigin.y - origin.y
//        )
//        return inference.rect.applying(originChange)
//    }
    
}

// CGImage (Utls)

extension CGImage {
    
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
    
    static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        return cgImage
    }
    
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
    
    
    func isBlack() -> Bool {
        guard let provider = self.dataProvider else {
            return true
        }
        let bmp = provider.data
        var data: UnsafePointer<UInt8> = CFDataGetBytePtr(bmp)
        return self.isPixelBlack(data: &data, shift: (self.width / 2) * (self.height / 2))
    }
    
    func isPixelBlack(data: inout UnsafePointer<UInt8>, shift: Int) -> Bool {
        // r
        data = data.advanced(by: shift)
        let r = data.pointee
        data = data.advanced(by: shift + 1)
        // g
        let g = data.pointee
        data = data.advanced(by: shift + 1)
        // b
        let b = data.pointee
        // a
        _ = data.advanced(by: shift + 1)
        return r == 0 && g == 0 && b == 0
    }

}

// CVPixelBuffer (Utls)

public extension CVPixelBuffer {
    
    func cgimage() throws -> CGImage {
        guard let cgImage = CGImage.create(pixelBuffer: self) else {
            throw CellyError(message: "Unable to create cgimage from pixelBuffer")
        }
        return cgImage
    }
    
    static func pixelBuffer(from image: CGImage) -> CVPixelBuffer? {
        let frameSize = CGSize(width: image.width, height: image.height)

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(frameSize.width),
            Int(frameSize.height),
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )

        if status != kCVReturnSuccess {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGBitmapInfo.byteOrder32Little
                .rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        let context = CGContext(
            data: data,
            width: Int(frameSize.width),
            height: Int(frameSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )

        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
    
    func rgbDataFromBuffer(
        byteCount _: Int,
        channels _: Int,
        alphaComponent _: Int,
        rgbPixelChannels _: Int,
        lastBgrComponent _: Int,
        isModelQuantized: Bool
    ) -> Data? {
//        let buffer = self
//        CVPixelBufferLockBaseAddress(buffer, .readOnly)
//        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
//        guard let mutableRawPointer = CVPixelBufferGetBaseAddress(buffer) else {
//            return nil
//        }
//        assert(CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA)
//        let count = CVPixelBufferGetDataSize(buffer)
//        let bufferData = Data(bytesNoCopy: mutableRawPointer, count: count, deallocator: .none)
//        var rgbBytes = [UInt8](repeating: 0, count: byteCount)
//        var pixelIndex = 0
//        for component in bufferData.enumerated() {
//            let bgraComponent = component.offset % channels;
//            let isAlphaComponent = bgraComponent == alphaComponent;
//            guard !isAlphaComponent else {
//                pixelIndex += 1
//                continue
//            }
//            // Swizzle BGR -> RGB.
//            let rgbIndex = pixelIndex * rgbPixelChannels + (lastBgrComponent - bgraComponent)
//            rgbBytes[rgbIndex] = component.element
//        }
//        let floatRGBBytes = rgbBytes.map { byte -> Float in // Float - 4 bytes per value
//            return Float(byte) / 128.0 - 1.0
//        }

        CVPixelBufferLockBaseAddress(self, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(self, .readOnly)
        }
        guard let sourceData = CVPixelBufferGetBaseAddress(self) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let destinationChannelCount = 3
        let destinationBytesPerRow = destinationChannelCount * width

        var sourceBuffer = vImage_Buffer(
            data: sourceData,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: sourceBytesPerRow
        )

        guard let destinationData = malloc(height * destinationBytesPerRow) else {
            Log.log(.error, "celly-core | cvpixel-buffer | rgbDataFromBuffer: out_of_memory ")
            return nil
        }

        defer {
            free(destinationData)
        }

        var destinationBuffer = vImage_Buffer(
            data: destinationData,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: destinationBytesPerRow
        )

        let pixelBufferFormat = CVPixelBufferGetPixelFormatType(self)

        switch pixelBufferFormat {
        case kCVPixelFormatType_32BGRA:
            vImageConvert_BGRA8888toRGB888(
                &sourceBuffer,
                &destinationBuffer,
                UInt32(kvImageNoFlags)
            )
        case kCVPixelFormatType_32ARGB:
            vImageConvert_ARGB8888toRGB888(
                &sourceBuffer,
                &destinationBuffer,
                UInt32(kvImageNoFlags)
            )
        case kCVPixelFormatType_32RGBA:
            vImageConvert_RGBA8888toRGB888(
                &sourceBuffer,
                &destinationBuffer,
                UInt32(kvImageNoFlags)
            )
        default:
            // Unknown pixel format.
            return nil
        }

        let byteData = Data(
            bytes: destinationBuffer.data,
            count: destinationBuffer.rowBytes * height
        )
        if isModelQuantized {
            return byteData
        }

        // Not quantized, convert to floats
        let bytes = [UInt8](unsafeData: byteData)!
        var floatBytes = [Float](repeating: 0, count: bytes.count)
        vDSP_vfltu8(bytes, 1, &floatBytes, 1, vDSP_Length(bytes.count))
//        floatBytes = vDSP.divide(floatBytes, 255.0)
        floatBytes = vDSP.divide(floatBytes, 128.0)
        floatBytes = vDSP.add(-1, floatBytes)
        return floatBytes.withUnsafeBufferPointer(Data.init)
    }
    
    func rotate90PixelBuffer(factor: UInt) -> CVPixelBuffer? {
            let srcPixelBuffer: CVPixelBuffer = self
            let flags = CVPixelBufferLockFlags(rawValue: 0)
            guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, flags) else {
                return nil
            }
            defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, flags) }

            guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
                Log.log(.error, "celly-core | cvpixel-buffer | rotate90PixelBuffer: CVPixelBufferGetBaseAddress=null")
                return nil
            }
            let sourceWidth = CVPixelBufferGetWidth(srcPixelBuffer)
            let sourceHeight = CVPixelBufferGetHeight(srcPixelBuffer)
            var destWidth = sourceHeight
            var destHeight = sourceWidth
            var color = UInt8(0)

            if factor % 2 == 0 {
                destWidth = sourceWidth
                destHeight = sourceHeight
            }

            let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
            var srcBuffer = vImage_Buffer(
                data: srcData,
                height: vImagePixelCount(sourceHeight),
                width: vImagePixelCount(sourceWidth),
                rowBytes: srcBytesPerRow
            )

            let destBytesPerRow = destWidth * 4
            guard let destData = malloc(destHeight * destBytesPerRow) else {
                Log.log(.error, "celly-core | cvpixel-buffer | rotate90PixelBuffer: out_of_memory ")
                return nil
            }
            var destBuffer = vImage_Buffer(
                data: destData,
                height: vImagePixelCount(destHeight),
                width: vImagePixelCount(destWidth),
                rowBytes: destBytesPerRow
            )

            let rotation: UInt8
            if factor == 0 {
                rotation = UInt8(kRotate0DegreesClockwise)
            }
            else if factor == 90 {
                rotation = UInt8(kRotate90DegreesClockwise)
            }
            else if factor == 180 {
                rotation = UInt8(kRotate180DegreesClockwise)
            }
            else if factor == 270 {
                rotation = UInt8(kRotate270DegreesClockwise)
            }
            else {
                fatalError("Unsupported factor \(factor)")
            }
            let error = vImageRotate90_ARGB8888(
                &srcBuffer,
                &destBuffer,
                rotation,
                &color,
                vImage_Flags(0)
            )
            if error != kvImageNoError {
                os_log(.info, "Rotating error %ld", error)
                free(destData)
                return nil
            }

            let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
                if let ptr = ptr {
                    free(UnsafeMutableRawPointer(mutating: ptr))
                }
            }

            let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
            var dstPixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreateWithBytes(
                nil,
                destWidth,
                destHeight,
                pixelFormat,
                destData,
                destBytesPerRow,
                releaseCallback,
                nil,
                nil,
                &dstPixelBuffer
            )
            if status != kCVReturnSuccess {
                Log.log(.error, "celly-core | cvpixel-buffer | rotate90PixelBuffer: CVPixelBufferCreateWithBytes!=success")
                free(destData)
                return nil
            }
            return dstPixelBuffer
        }

    
}

 // Interpreter

struct InferenceTFInterpreterConfig: Encodable {
    enum FilteredClasses: Encodable {
        enum CodingKeys: String, CodingKey {
            case excluded
            case included
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .excluded(excluded):
                let childEncoder = container.superEncoder(forKey: .excluded)
                try excluded.encode(to: childEncoder)
            case let .included(included):
                let childEncoder = container.superEncoder(forKey: .included)
                try included.encode(to: childEncoder)
            }
        }

        case included([String])
        case excluded([String])
    }

    let model: String
    let cellClasses: [CellClass]
    let iouThreshold: Double
    let confidenceThreshold: Double
    let threadCount: Int?

    enum CodingKeys: String, CodingKey {
        case modeName = "model_name"
        case cellClasses = "model_classes_to_count"
        case countedCellClasses = "counted_cell_classes"
        case iouThreshold = "iou_threshold"
        case confidenceThreshold = "confidence_threshold"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.model, forKey: .modeName)
        try container.encode(self.cellClasses, forKey: .cellClasses)
        try container.encode(self.iouThreshold, forKey: .iouThreshold)
        try container.encode(self.confidenceThreshold, forKey: .confidenceThreshold)
    }
}

public class InferenceInterpreterTFWrapperOverCoreMLImpl {
    // MARK: - Private properties

    private let bgraPixel = (channels: 4, alphaComponent: 3, lastBgrComponent: 2)
    private let rgbPixelChannels = 3
    /// TensorFlow Lite `ObjectDetector` object for performing object detection using a given model.
    // private let detector: ObjectDetector
    private let interpreter: Interpreter
    private let config: InferenceTFInterpreterConfig
    private var counter = 0

    private struct ModelDimensions {
        let batchSize: Int
        let inputChannels: Int
        let inputWidth: Int
        let inputHeight: Int
    }

    // MARK: - Initialization

    init(
        config: InferenceTFInterpreterConfig
    ) throws {
        // START: Guard checks
        guard
            let modelPath = Bundle.main.path(
                forResource: config.model,
                ofType: nil
            )
        else {
            throw CellyError(
                message: "Failed to load the model file with name: \(config.model)."
            )
        }
        Log.log(.warning, "inference-interpreter-detection-tflite | model \(config.model)")
        // END
        // START: Interpreter
        let coreMLDelegate = CoreMLDelegate(options: CoreMLDelegate.Options())
        if coreMLDelegate == nil {
            Log.log(.warning, "inference-interpreter-detection-tflite | neural-engine-not-supported")
        }
        else {
            Log.log(.notice, "inference-interpreter-detection-tflite | neural-engine-supported")
        }
        let delegates = [coreMLDelegate].compactMap { $0 }
        self.interpreter = try Interpreter(
            modelPath: modelPath,
            options: { () in var options = Interpreter.Options(); options.threadCount = nil; return options }(),
            delegates: delegates
        )
        try self.interpreter.allocateTensors()
        // END
        // START: Specify the options for the `Detector`
//        let options = ObjectDetectorOptions(modelPath: modelPath)
//        options.classificationOptions.scoreThreshold = Float(config.confidenceThreshold)
//        options.classificationOptions.maxResults = 100 // TODO: Move to config
//        options.baseOptions.computeSettings.cpuSettings.numThreads = Int32(config.threadCount ?? 0)
//        self.detector = try ObjectDetector.detector(options: options)
        // END
        self.config = config
    }

    func inference(cgImage: CGImage) throws -> InferenceResult {
        let start = CFAbsoluteTimeGetCurrent()
        // Start: Extracting & validating model dimensions
        let dimensions = try interpreter.input(at: 0).shape.dimensions
        guard dimensions.count == 4 else {
            throw CellyError(
                message: "Expected input share dimensions count as 4, got \(dimensions.count)"
            )
        }
        let modelDimensions = ModelDimensions(
            batchSize: dimensions[0],
            inputChannels: dimensions[3],
            inputWidth: dimensions[1],
            inputHeight: dimensions[2]
        )
        // END
        // START: Scalling
        // Crops the image to the biggest square in the center
        // and scales it down to model dimensions.
        let scaledSize = CGSize(
            width: modelDimensions.inputWidth,
            height: modelDimensions.inputHeight
        )
        let scaledImage = try cgImage.scaled(size: scaledSize)
        Logger.shared.log(.service, .debug, UIImage(cgImage: scaledImage))
        guard
            let thumbnailPixelBuffer = CVPixelBuffer
                .pixelBuffer(from: scaledImage)
        else {
            throw CellyError(message: "Unable to resize pixel buffer to thumbnail")
        }
        // END
        // START: Extracing RGB data from image
        let inputTensor = try interpreter.input(at: 0)
        // Remove the alpha component from the image buffer
        //  to get the RGB data.
        let byteCount = modelDimensions.batchSize * modelDimensions.inputWidth * modelDimensions
            .inputHeight * modelDimensions.inputChannels
        guard
            let rgbData = thumbnailPixelBuffer.rgbDataFromBuffer(
                byteCount: byteCount,
                channels: bgraPixel.channels,
                alphaComponent: bgraPixel.alphaComponent,
                rgbPixelChannels: rgbPixelChannels,
                lastBgrComponent: bgraPixel.lastBgrComponent,
                isModelQuantized: inputTensor.dataType == .uInt8
            )
        else {
            throw CellyError(message: "Failed to convert the image buffer to RGB data.")
        }
        // END
        // START: Running inference
        try self.interpreter.copy(rgbData, toInputAt: 0)
        let startInvoke = CFAbsoluteTimeGetCurrent()
        try interpreter.invoke()
        let intervalInvoke = CFAbsoluteTimeGetCurrent() - startInvoke
        Log.log(.debug, "inference-interpreter-detection-tflite | inference-interval-invoke %3.3lf ", intervalInvoke)
        // END
        // START:
        // Formats the results
//        let outputScores = try interpreter.output(at: 0)
//        let outputBoundingBox = try interpreter.output(at: 1)
//        let outputCount = try interpreter.output(at: 2)
//        let outputClasses = try interpreter.output(at: 3)
        
        let outputScores = try interpreter.output(at: 2)
        let outputBoundingBox = try interpreter.output(at: 0)
        let outputClasses = try interpreter.output(at: 1)
        // let outputCount = try interpreter.output(at: 2)
        
        Log.log(.debug, "inference-interpreter-detection-tflite | output | ---")
        Log.log(.debug, "inference-interpreter-detection-tflite | output-scores %@", String(describing: outputScores))
        Log.log(.debug, "inference-interpreter-detection-tflite | output-bounding-box %@", String(describing: outputBoundingBox))
        // Log.log(.debug, "inference-interpreter-detection-tflite | output-count %@", String(describing: outputCount))
        Log.log(.debug, "inference-interpreter-detection-tflite | output-classes %@", String(describing: outputClasses))
        Log.log(.debug, "inference-interpreter-detection-tflite | output | ---")
        
        let resultArray = self.formatResults(
            boundingBox: [Float](unsafeData: outputBoundingBox.data) ?? [],
            outputScores: [Float](unsafeData: outputScores.data) ?? [],
            //outputCount: Int(([Float](unsafeData: outputCount.data) ?? [0])[0]),
            outputClasses: [Float](unsafeData: outputClasses.data) ?? [],
            width: CGFloat(cgImage.width),
            height: CGFloat(cgImage.height)
        )
        // END
        let interval = CFAbsoluteTimeGetCurrent() - start
        Log.log(.debug, "inference-interpreter-detection-tflite | inference-interval %3.3lf ", interval)
        return .init(interval: interval, inferences: resultArray)
    }

    /// Filters out all the results with confidence score < threshold and returns the top N results
    /// sorted in descending order.
    private func formatResults(
        boundingBox: [Float],
        outputScores: [Float],
        //outputCount: Int,
        outputClasses: [Float],
        width: CGFloat,
        height: CGFloat
    ) -> [Inference] {
        var resultsArray: [Inference] = []
//        if outputCount == 0 {
//            return resultsArray
//        }
        let outputCount = outputScores.count
        for i in 0...outputCount - 1 {
            self.counter += 1
            let score = outputScores[i]
            guard score >= Float(self.config.confidenceThreshold) else {
                continue
            }

            // Gets the output class names for detected classes from labels list.
            let outputClassIndex = Int(outputClasses[i])
            let cellClass = self.config.cellClasses[outputClassIndex]

            var rect = CGRect.zero

            // Translates the detected bounding box to CGRect.
            rect.origin.y = CGFloat(boundingBox[4 * i])
            rect.origin.x = CGFloat(boundingBox[4 * i + 1])
            rect.size.height = CGFloat(boundingBox[4 * i + 2]) - rect.origin.y
            rect.size.width = CGFloat(boundingBox[4 * i + 3]) - rect.origin.x

            // The detected corners are for model dimensions.
            // So we scale the rect with respect to the
            // actual image dimensions.
            let newRect = rect.applying(CGAffineTransform(scaleX: width, y: height))
            let inference = Inference(
                id: self.counter,
                confidence: score,
                cellClass: cellClass,
                rect: newRect,
                displayColor: CGColor.color(hex: cellClass.color),
                manual: false
            )
            resultsArray.append(inference)
        }

        // Sort results in descending order of confidence.
        resultsArray.sort { first, second -> Bool in
            first.confidence > second.confidence
        }

        return resultsArray
    }
}


// Models

public class CellClass: Codable, Equatable, Hashable {
    public enum Class: String, Codable {
        case wbc
        case rbc
        case infected
        case column
        case artefact
        case plt
        case thick
        case bg
        case thin
    }

    public static func == (lhs: CellClass, rhs: CellClass) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.class == rhs.class && lhs.color == rhs
            .color && lhs.weigth == rhs.weigth
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.name)
        hasher.combine(self.class)
        hasher.combine(self.color)
        hasher.combine(self.weigth)
    }

    public let id: Int
    public let name: String
    public let `class`: Class
    public var color: String
    public let weigth: Float?
    public init(
        id: Int,
        name: String,
        class: Class,
        color: String? = nil,
        weigth: Float? = nil
    ) {
        self.id = id
        self.name = name
        self.class = `class`
        self.color = color ?? CellClass.color(class: `class`)
        self.weigth = weigth
    }

    static func color(class: Class) -> String {
        switch `class` {
        case .wbc: return "#4A90E2" // blue
        case .rbc: return "#41F648" // green
        case .infected: return "#F5A623" // orange
        case .column: return "#aaaaff" // light-puple
        case .artefact: return "#000000" // black
        case .plt: return "#BD10E0" // purpule
        case .bg,
             .thick,
             .thin: return "#000000"
        }
    }
}

public class CellyError: Error, LocalizedError {
    public enum ErrorCode: Int {
        case aborted
        case unauthorized = 401
        case undefined = -1
    }

    private var message: String

    public var errorDescription: String? {
        self.message
    }

    public var localizedDescription: String {
        self.message
    }

    public var code: ErrorCode?

    public init(message: String, code: ErrorCode? = nil) {
        self.message = message
        self.code = code
    }

    public init(message: String, status: Int) {
        self.message = message
        self.code = ErrorCode(rawValue: status) ?? .undefined
    }
}


public struct InterpretatorResult {
    public let frameNumber: Int
    public let interval: Double
    public let inferenceResult: InferenceResult
    public init(
        frameNumber: Int,
        interval: Double,
        inferenceResult: InferenceResult
    ) {
        self.frameNumber = frameNumber
        self.interval = interval
        self.inferenceResult = inferenceResult
    }
}

public struct InferenceResult {
    public let interval: Double
    public let inferences: [Inference]
    public func copy(inferences: [Inference]) -> InferenceResult {
        InferenceResult(
            interval: self.interval,
            inferences: inferences
        )
    }

    public init(
        interval: Double,
        inferences: [Inference]
    ) {
        self.interval = interval
        self.inferences = inferences
    }
}

public struct Inference: Codable, Equatable {
    public let id: Int
    public let confidence: Float
    public let cellClass: CellClass
    public let rect: CGRect
    public let displayColor: CGColor?
    public let manual: Bool
    public init(
        id: Int,
        confidence: Float,
        cellClass: CellClass,
        rect: CGRect,
        displayColor: CGColor? = nil,
        manual: Bool = false
    ) {
        self.id = id
        self.confidence = confidence
        self.cellClass = cellClass
        self.rect = rect
        self.displayColor = displayColor
        self.manual = manual
    }

    public static func == (lhs: Inference, rhs: Inference) -> Bool {
        lhs.id == rhs.id
            && lhs.confidence == rhs.confidence
            && lhs.cellClass == rhs.cellClass
            && lhs.rect == rhs.rect
            && lhs.manual == rhs.manual
    }

    func copy(
        rect: CGRect? = nil
    ) -> Inference {
        Inference(
            id: self.id,
            confidence: self.confidence,
            cellClass: self.cellClass,
            rect: rect ?? self.rect,
            displayColor: self.displayColor,
            manual: self.manual
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case confidence
        case cellClass = "cell_class"
        case rect
        case manual
        case color
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.confidence, forKey: .confidence)
        try container.encode(self.manual, forKey: .manual)
        try container.encode(self.cellClass, forKey: .cellClass)
        try container.encode(self.rect, forKey: .rect)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.confidence = try container.decode(Float.self, forKey: .confidence)
        self.manual = try container.decode(Bool.self, forKey: .manual)
        self.cellClass = try container.decode(CellClass.self, forKey: .cellClass)
        self.rect = try container.decode(CGRect.self, forKey: .rect)
        self.displayColor = nil
    }
}


//

// TODO: OSLogMessage wrapper: privacy, formatting
public struct LogEntity {
    public let date: Date
    public let category: String
    public let composedMessage: String
}

public enum Log {
    private static let _subsystem = Bundle.main.bundleIdentifier ?? "undefined"

    private static let _app = Logger(subsystem: _subsystem, category: "App")
    private static let _pointsOfInterest = OSSignposter(
        subsystem: _subsystem,
        category: .pointsOfInterest
    )

    public static func log(
        _ type: LogType = .default,
        _ message: String,
        _ args: CVarArg...
    ) {
        let msg = String(format: message, arguments: args)
        switch type {
        case .default:
            self._app.log("\(msg, align: .none, privacy: .public)")
        case .info:
            self._app.info("\(msg, align: .none, privacy: .public)")
        case .notice:
            self._app.notice("\(msg, align: .none, privacy: .public)")
        case .debug:
            self._app.debug("\(msg, align: .none, privacy: .public)")
        case .trace:
            self._app.trace("\(msg, align: .none, privacy: .public)")
        case .warning:
            self._app.warning("\(msg, align: .none, privacy: .public)")
        case .error:
            self._app.error("\(msg, align: .none, privacy: .public)")
        case .fault:
            self._app.fault("\(msg, align: .none, privacy: .public)")
        case .critical:
            self._app.critical("\(msg, align: .none, privacy: .public)")
        }
    }

    @discardableResult
    public static func signpost<T>(
        _ name: StaticString,
        _ task: () throws -> T,
        _ message: String = "",
        _ args: CVarArg...
    ) rethrows -> T {
        try self._signposter().withIntervalSignpost(
            name,
            "\(String(format: message, arguments: args), align: .none, privacy: .public)",
            around: task
        )
    }

    public static func signpost(
        _: LogSignpostType,
        _ name: StaticString,
        _ message: String = "",
        _ args: CVarArg...
    ) {
        self._signposter().emitEvent(
            name,
            "\(String(format: message, arguments: args), align: .none, privacy: .public)"
        )
    }

    // MARK: Private

    private static func _signposter() -> OSSignposter {
        #if DEBUG
            let isSignPostEnabled = ProcessInfo.processInfo.environment["SIGNPOST_ENABLED"] != nil
            return isSignPostEnabled ? self._pointsOfInterest : .disabled
        #else
            return .disabled
        #endif
    }
}

public enum LogType {
    case `default`
    case notice
    case debug
    case trace
    case info
    case warning
    case error
    case fault
    case critical
}

public enum LogSignpostType {
    case begin
    case end
    case event
}

public struct LogInterpolation {
    init(literalCapacity _: Int, interpolationCount _: Int) {}
}

public enum LogPrivacy {
    case auto
    case `private`
    case sensetive
}


public extension Array {
    /// Creates a new array from the bytes of the given unsafe data.
    ///
    /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
    ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
    ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
    /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
    ///     `MemoryLayout<Element>.stride`.
    /// - Parameter unsafeData: The data containing the bytes to turn into an array.
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        #if swift(>=5.0)
            self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
        #else
            self = unsafeData.withUnsafeBytes {
                .init(UnsafeBufferPointer<Element>(
                    start: $0,
                    count: unsafeData.count / MemoryLayout<Element>.stride
                ))
            }
        #endif // swift(>=5.0)
    }

    func toDictionary<Key: Hashable>(with selectKey: (Iterator.Element) -> Key)
        -> [Key: Iterator.Element]
    {
        var dict: [Key: Iterator.Element] = [:]
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }

    func appending(_ newElement: Element) -> [Element] {
        self + [newElement]
    }

    func appending(contentsOf sequence: [Element]) -> [Element] {
        self + sequence
    }

    // https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}


public extension CGColor {
    class func color(hex: String) -> CGColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        guard
            cString.count == 6,
            let rgbValue = Scanner(string: cString).scanInt32(representation: .hexadecimal)
        else {
            return CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        }

        return CGColor(
            srgbRed: CGFloat((rgbValue & 0xff0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00ff00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000ff) / 255.0,
            alpha: 1.0
        )
    }
}

// Fake camera

protocol CameraFeedManagerDelegate: AnyObject {
    func didVideoOutput(cgImage: CGImage?, error: Error?)

    func presentCameraPermissionsDeniedAlert()

    func presentVideoConfigurationErrorAlert()

    func sessionRunTimeErrorOccured()

    func sessionWasInterrupted(canResumeManually resumeManually: Bool)

    func sessionInterruptionEnded()
}

extension CameraFeedManagerDelegate {
    func presentCameraPermissionsDeniedAlert() {}

    func presentVideoConfigurationErrorAlert() {}

    func sessionRunTimeErrorOccured() {}

    func sessionWasInterrupted(canResumeManually _: Bool) {}

    func sessionInterruptionEnded() {}
}


class CameraFeedManagerFakeImageImpl: NSObject {
    
    weak var delegate: CameraFeedManagerDelegate?
    let image: CGImage
    let playerView: PlayerView
    
    init(image: CGImage, playerView: PlayerView) {
        self.image = image
        self.playerView = playerView
    }
    func start() throws {
        DispatchQueue.global().async {
            while (true) {
                DispatchQueue.main.async {
                    self.playerView.draw(cgImage: self.image)
                }
                self.delegate?.didVideoOutput(cgImage: self.image, error: nil)
            }
        }
    }
    
}

class CameraFeedManagerFakeImpl: NSObject {
    private(set) var fps: Int?
    private(set) var frame: Int
    weak var delegate: CameraFeedManagerDelegate?

    // Services
    private var isRecording: Bool

    // Configuration
    private var configuration: Configuration?; struct Configuration {
        let videoURL: URL
        let playerView: PlayerView?
        let fps: Int?
        let frame: Int?
        init(
            videoURL: URL,
            playerView: PlayerView?,
            fps: Int?,
            frame: Int?
        ) {
            self.videoURL = videoURL
            self.playerView = playerView
            self.fps = fps
            self.frame = frame
        }
    }

    // Asset Reader
    private var assetReader: AVAssetReader?
    private var isReading: Bool
    private var nominalFrameRate: Float
    private var transformDegrees: UInt8
    private let queue: DispatchQueue
    private var lastFrameDispatchDate: Date
    private var completion: ((Result<Void, Error>) -> Void)?
    private var isReachedBlackFrame: Bool

    // MARK: Timer

    fileprivate var timer: Timer?
    fileprivate var frameCounterPerSecond: Atomic<Int>

    // MARK: Rendering

    fileprivate var renderingImage: Atomic<CGImage?>
    fileprivate var rendetingTimeObserverToken: Any?
    fileprivate var renderingTimer: Timer?

    override init() {
        self.queue = DispatchQueue(
            label: "com.cellyai.fakecamera",
            qos: .userInteractive,
            attributes: [.concurrent]
        )
        self.lastFrameDispatchDate = .distantPast
        self.nominalFrameRate = 0
        self.transformDegrees = 0
        self.isReading = false
        self.frameCounterPerSecond = Atomic<Int>(0)
        self.renderingImage = Atomic<CGImage?>(nil)
        self.isRecording = false
        self.isReachedBlackFrame = false
        self.frame = 0
        super.init()
    }

    deinit {
        self.renderingTimer?.invalidate()
        self.timer?.invalidate()
    }

    func configure(
        configuration: Configuration,
        _ completion: ((Result<Void, Error>) -> Void)?
    ) throws {
        self.configuration = configuration
        self.completion = completion
    }

    func start() throws {
        guard !self.isReading else {
            return
        }
        guard let configuration = self.configuration else {
            return
        }
        self.frameCounterPerSecond.mutate { value in
            value = 0
        }
        self.nominalFrameRate = 0
        self.transformDegrees = 0
        self.timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(self.fireTimer),
            userInfo: nil,
            repeats: true
        )
        self.isReading = true
        self.renderingImage = Atomic<CGImage?>(nil)
        let avAsset = AVAsset(url: configuration.videoURL)
        try self.setupAssetReader(avAsset: avAsset)
        self.readAssetReader()
    }

    func pause() throws {
        self.queue.async { [weak self] in
            self?.isReading = false
        }
    }

    func stop(_ completion: (() -> Void)?) throws {
        self.timer?.invalidate()
        self.timer = nil
        self.queue.async { [weak self] in
            self?.isReading = false
            self?.nominalFrameRate = 0
            self?.isReachedBlackFrame = false
            self?.frame = 0
            self?.transformDegrees = 0
            self?.frameCounterPerSecond = Atomic<Int>(0)
            self?.assetReader?.cancelReading()
            completion?()
        }
    }

    func resume(_: @escaping (Bool) -> Void) throws {
        self.isReading = true
        self.queue.async {
            self.readFrames()
        }
    }

    // MARK:

    @objc
    private func fireTimer() {
        if self.frameCounterPerSecond.value > 1 {
            self.fps = self.frameCounterPerSecond.value
        }
        self.frameCounterPerSecond.mutate { value in
            value = 0
        }
    }

    // Iterative

    private func setupAssetReader(avAsset: AVAsset) throws {
        if let assetReader = self.assetReader {
            assetReader.cancelReading()
        }
        guard let assetTrack = avAsset.tracks.first else {
            throw CellyError(message: "Unable to get asset track")
        }

        let minFrameDuration = assetTrack.minFrameDuration
        self.nominalFrameRate = assetTrack.nominalFrameRate
        let radians = atan2(
            assetTrack.preferredTransform.b,
            assetTrack.preferredTransform.a
        )
        self.transformDegrees = UInt8((radians * 180.0) / .pi)

        let outputSettings =
            [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]
        let assetReaderOutput = AVAssetReaderTrackOutput(
            track: assetTrack,
            outputSettings: outputSettings
        )
        assetReaderOutput.alwaysCopiesSampleData = false
        assetReaderOutput.supportsRandomAccess = true

        self.assetReader = try AVAssetReader(asset: avAsset)
        self.assetReader?.add(assetReaderOutput)
        DispatchQueue.main.async {
            self.renderingTimer?.invalidate()
            self.renderingTimer = Timer.scheduledTimer(
                withTimeInterval: CMTimeGetSeconds(minFrameDuration),
                repeats: true,
                block: { [weak self] _ in
                    if let cgImage = self?.renderingImage.value {
                        DispatchQueue.main.async {
                            self?.configuration?.playerView?.draw(cgImage: cgImage)
                        }
                    }
                }
            )
        }
    }

    private func readAssetReader() {
        self.assetReader?.startReading()
        self.queue.async {
            self.readFrames()
        }
    }

    private func readFrames() {
        let videoFPS = self.configuration?.fps ?? Int(self.nominalFrameRate)
        let beetweenFrameInterval = TimeInterval(1.0 / Float(videoFPS))
        var sample: CMSampleBuffer?
        while true {
            // Step 0: Reading buffer only if ready
            guard self.isReading else {
                return
            }

            let intervalSinceLastFrame = Date().timeIntervalSince(self.lastFrameDispatchDate)
            if
                intervalSinceLastFrame >= beetweenFrameInterval,
                let output = self.assetReader?.outputs.first
            {
                sample = output.copyNextSampleBuffer()
                self.frame += 1
                self.frameCounterPerSecond.mutate { value in
                    value += 1
                }
            }
            else {
                continue
            }
            self.lastFrameDispatchDate = Date()

            // Start: Skipping all frames until desired one reached
            if let frame = self.configuration?.frame, self.frame < frame {
                continue
            }
            // End

            // Extracing buffer
            guard var imageBuffer = sample?.imageBuffer else {
                break
            }

            let cgImage: CGImage = Log.signpost("Fake Camera Preprocessing") {
                // Rotating of buffer if need
                if self.transformDegrees != 0, self.transformDegrees % 90 == 0 {
                    imageBuffer = imageBuffer
                        .rotate90PixelBuffer(factor: UInt(self.transformDegrees)) ?? imageBuffer
                }

                let cgImage = try! imageBuffer.cgimage()
                return cgImage
            }
            // Guard check if image is black
            guard !cgImage.isBlack() else {
                guard !self.isReachedBlackFrame else {
                    Log.log(.error, "camera-feed-manager | already-reached-black-frame")
                    continue
                }
                self.isReachedBlackFrame = true
                continue
            }

            // Saving image buffer for possible render
            self.renderingImage.mutate { value in
                value = cgImage.copy()
            }

            // Outputting buffer to delegate (counter)
            autoreleasepool {
                self.delegate?.didVideoOutput(cgImage: cgImage, error: nil)
            }
        }
        try? self.stop { [weak self] in
            self?.completion?(.success(()))
        }
    }
}

extension CameraFeedManagerFakeImpl: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(
        _ previewController: RPPreviewViewController
    ) {
        previewController.dismiss(animated: true, completion: nil)
    }
}


public final class Atomic<A> {
    private let queue = DispatchQueue(
        label: "amin.benarieb.Celly-Atomic",
        attributes: .concurrent
    )
    private var _value: A
    private let didSet: DidSetCompletion?; public typealias DidSetCompletion = (A) -> Void

    public init(_ value: A, didSet: DidSetCompletion? = nil) {
        self._value = value
        self.didSet = didSet
    }

    public var value: A { self.queue.sync { self._value } }

    public func mutate(_ transform: (inout A) -> Void) {
        self.queue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            transform(&self._value)
            self.didSet?(self._value)
        }
    }
}


// PlayerView


class PlayerView: UIView {
    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            fatalError("Layer expected is of type AVPlayerLayer")
        }
        return layer
    }

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        set {
            if let layer = layer as? AVPlayerLayer {
                layer.player = newValue
            }
        }
        get {
            if let layer = layer as? AVPlayerLayer {
                return layer.player
            }
            else {
                return nil
            }
        }
    }

    func draw(cgImage: CGImage?) {
        self.layer.contents = cgImage
    }
}

// OverLayview

class OverlayView: UIView {
    var overlayViewModel: OverlayViewModel?
    var cropping: Float?
    var tapRect: CGRect?
    var tapOverlayViewModel: OverlayViewModel?

    private let cornerRadius: CGFloat = 10.0
    private let stringBgAlpha: CGFloat = 0.7
    private let lineWidth: CGFloat = 3
    private let stringFontColor = UIColor.white
    private let stringHorizontalSpacing: CGFloat = 13.0
    private let stringVerticalSpacing: CGFloat = 7.0

    override func draw(_: CGRect) {
        if let overlayViewModel = self.overlayViewModel {
            for objectOverlay in overlayViewModel.objectOverlays {
                self.drawBorders(of: objectOverlay)
                self.drawBackground(of: objectOverlay)
                self.drawName(of: objectOverlay)
            }
        }
        if let tapOverlayViewModel = self.tapOverlayViewModel {
            for objectOverlay in tapOverlayViewModel.objectOverlays {
                self.drawBorders(of: objectOverlay)
                self.drawBackground(of: objectOverlay)
                self.drawName(of: objectOverlay)
            }
        }
        if let cropping = cropping {
            let size = self.bounds.size
            let frameWidth = CGFloat(size.width)
            let frameHeight = CGFloat(size.height)
            let offsetX = frameWidth * CGFloat(cropping)
            let offsetY = frameHeight * CGFloat(cropping)
            let roiRect = CGRect(
                x: offsetX,
                y: offsetY,
                width: frameWidth - 2 * offsetX,
                height: frameHeight - 2 * offsetY
            )
            self.draw(activeArea: roiRect)
        }
        if let tapRect = tapRect {
            self.draw(rect: tapRect)
        }
    }

    private func drawBorders(of objectOverlay: ObjectOverlay) {
        let path = UIBezierPath(rect: objectOverlay.borderRect)
        path.lineWidth = self.lineWidth
        if let dashes = objectOverlay.dashed {
            path.setLineDash(dashes, count: dashes.count, phase: 0.0)
            path.lineCapStyle = .square
        }
        objectOverlay.color.setStroke()
        path.stroke()
    }

    private func drawBackground(of objectOverlay: ObjectOverlay) {
        if let nameStringSize = objectOverlay.nameStringSize {
            let stringBgRect = CGRect(
                x: objectOverlay.borderRect.origin.x,
                y: objectOverlay.borderRect.origin.y,
                width: 2 * self.stringHorizontalSpacing + nameStringSize.width,
                height: 2 * self.stringVerticalSpacing + nameStringSize.height
            )

            let stringBgPath = UIBezierPath(rect: stringBgRect)
            objectOverlay.color.withAlphaComponent(self.stringBgAlpha).setFill()
            stringBgPath.fill()
        }
    }

    private func drawName(of objectOverlay: ObjectOverlay) {
        // Draws the string.
        if let name = objectOverlay.name, let nameStringSize = objectOverlay.nameStringSize {
            let stringRect = CGRect(
                x: objectOverlay.borderRect.origin.x + self.stringHorizontalSpacing,
                y: objectOverlay.borderRect.origin.y + self.stringVerticalSpacing,
                width: nameStringSize.width,
                height: nameStringSize.height
            )

            let attributedString = NSAttributedString(
                string: name,
                attributes: [
                    NSAttributedString.Key
                        .foregroundColor: self
                        .stringFontColor,
                    NSAttributedString.Key.font: objectOverlay
                        .font,
                ]
            )
            attributedString.draw(in: stringRect)
        }
    }

    private func draw(activeArea: CGRect) {
        let path = UIBezierPath(rect: activeArea)
        path.lineWidth = 4
        UIColor.green.setStroke()
        path.stroke()
    }

    private func draw(rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 1.0)
        path.lineWidth = 4
        let dashes: [CGFloat] = [0.0, 8.0]
        path.setLineDash(dashes, count: dashes.count, phase: 0.0)
        path.lineCapStyle = .square
        UIColor.orange.setStroke()
        path.stroke()
    }
}

