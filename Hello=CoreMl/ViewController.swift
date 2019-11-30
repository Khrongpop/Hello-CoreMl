//
//  ViewController.swift
//  Hello=CoreMl
//
//  Created by Muang on 14/11/2562 BE.
//  Copyright © 2562 ict. All rights reserved.
//

import UIKit
import AVKit
import Vision

//import Firebase
import FirebaseMLCommon
import FirebaseMLVision

class ViewController: UIViewController  {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setCamera()
    }


}
/// MARK - function
extension ViewController {
    private func setCamera() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraView.layer.addSublayer(previewLayer)
        previewLayer.frame = cameraView.frame
        
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        

    }
    
    private func barcodeReader(_ uiImage: UIImage) {
        let format = VisionBarcodeFormat.all
        let barcodeOptions = VisionBarcodeDetectorOptions(formats: format)

        let vision = Vision.vision()

        let barcodeDetector = vision.barcodeDetector(options: barcodeOptions)
        let visionImage = VisionImage(image: uiImage)

        barcodeDetector.detect(in: visionImage) { features, error in
          guard error == nil, let features = features, !features.isEmpty else {
            // ...
            return
          }

          // ...
        }


    }
    
    func imageOrientation(
        deviceOrientation: UIDeviceOrientation,
        cameraPosition: AVCaptureDevice.Position
        ) -> VisionDetectorImageOrientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftTop : .rightTop
        case .landscapeLeft:
            return cameraPosition == .front ? .bottomLeft : .topLeft
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightBottom : .leftBottom
        case .landscapeRight:
            return cameraPosition == .front ? .topRight : .bottomRight
        case .faceDown, .faceUp, .unknown:
            return .leftTop
        }
    }
}

/// MARK - AVCapture Delegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        foodScan(sampleBuffer)

    }
    
    private func foodScan(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                
        guard let model = try? VNCoreMLModel(for: Food101().model) else { return }
        let request = VNCoreMLRequest(model: model) { [weak self] (finishedReq, err) in

            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
                    
            guard let firstObservation = results.first else { return }
                    
//          guard firstObservation.confidence > 0.2 else { return }
            DispatchQueue.main.async {
                self?.textLabel.text = "\(firstObservation.identifier) : \(firstObservation.confidence)"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    private func barcodeScan(_ sampleBuffer: CMSampleBuffer) {

        let cameraPosition = AVCaptureDevice.Position.back  // Set to the capture device you used.
        let metadata = VisionImageMetadata()
        metadata.orientation = imageOrientation(
            deviceOrientation: UIDevice.current.orientation,
            cameraPosition: cameraPosition
        )

        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.metadata = metadata

        let format = VisionBarcodeFormat.all
        let barcodeOptions = VisionBarcodeDetectorOptions(formats: format)

        let vision = Vision.vision()

        let barcodeDetector = vision.barcodeDetector(options: barcodeOptions)
        barcodeDetector.detect(in: visionImage) { features, error in
          guard error == nil, let features = features, !features.isEmpty else {
            // ...
            return
          }

          // ...
        }

    }

}
