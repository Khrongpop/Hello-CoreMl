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
}

/// MARK - AVCapture Delegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Food101().model) else { return }
        let request = VNCoreMLRequest(model: model) { [weak self] (finishedReq, err) in

            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
//            guard firstObservation.confidence > 0.2 else { return }
            DispatchQueue.main.async {
                self?.textLabel.text = "\(firstObservation.identifier) : \(firstObservation.confidence)"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}
