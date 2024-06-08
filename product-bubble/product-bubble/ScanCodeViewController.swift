//
//  ScanCodeViewController.swift
//  product-bubble
//
//  Created by ほしょ on 2024/06/08.
//

import UIKit
import AVFoundation
import MLKit

class ScanCodeViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession: AVCaptureSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = imageOrientation(
            deviceOrientation: UIDevice.current.orientation,
            cameraPosition: .back
        )
        
        let barcodeScanner = BarcodeScanner.barcodeScanner()
        barcodeScanner.process(visionImage) { barcodes, error in
            guard error == nil, let barcodes = barcodes, !barcodes.isEmpty else {
                // エラーまたはバーコードが見つからない場合
                return
            }
            
            // 見つかったバーコードを処理
            for barcode in barcodes {
                if let rawValue = barcode.rawValue {
                    print("Barcode value: \(rawValue)")
                    self.fetchProductInfo(barcode: rawValue)
                }
            }
        }
    }
    
    private func imageOrientation(
        deviceOrientation: UIDeviceOrientation,
        cameraPosition: AVCaptureDevice.Position
    ) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .right
        @unknown default:
            fatalError()
        }
    }
    
    // Open Food Facts APIを使用して商品情報を取得
    func fetchProductInfo(barcode: String) {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching product info: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let product = json["product"] as? [String: Any] {
                    print("Product info: \(product)")
                    DispatchQueue.main.async {
                        self.displayProductInfo(product)
                    }
                } else {
                    print("Product not found")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    // 商品情報を表示するメソッド
    func displayProductInfo(_ product: [String: Any]) {
        let alert = UIAlertController(title: "Product Info", message: product.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

