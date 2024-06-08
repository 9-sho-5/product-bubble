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
    private var isBarcodeDetected = false // バーコード認識状態を管理するフラグ
    
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
        guard !isBarcodeDetected else { return } // バーコードがすでに認識されている場合は処理をスキップ
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
                    self.isBarcodeDetected = true // バーコードが認識されたことを記録
                    self.fetchProductInfo(barcode: rawValue)
                    break // 一つのバーコードが認識されたらループを抜ける
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
    
    // Yahoo!ショッピングAPIを使用して商品情報を取得
    func fetchProductInfo(barcode: String) {
        let apiKey = Env.getAPI_KEY() // 取得したAPIキーをここに入力
        let urlString = "https://shopping.yahooapis.jp/ShoppingWebService/V3/itemSearch?appid=\(apiKey)&query=\(barcode)&results=1"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching product info: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Full JSON response: \(json)")
                }

                let decoder = JSONDecoder()
                let response = try decoder.decode(ProductResponse.self, from: data)
                if let firstProduct = response.hits.first {
                    DispatchQueue.main.async {
                        self.displayProductInfo(firstProduct)
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
    func displayProductInfo(_ product: Product) {
        // 商品情報を取得
        let genreCategory = product.genreCategory.name
        let brand = product.brand.name
        let priceLabel = "\(product.priceLabel.defaultPrice)円"
        let name = product.name
        let imageUrl = product.image.medium
        let price = "\(product.price)円"
        let url = product.url
        let seller = product.seller.name
        let parentGenreCategories = product.parentGenreCategories.map { $0.name }.joined(separator: ", ")
        
        // 商品情報を表示
        let message = """
        名前: \(name)
        ジャンル: \(genreCategory)
        ブランド: \(brand)
        価格: \(price)
        販売者: \(seller)
        URL: \(url)
        親ジャンル: \(parentGenreCategories)
        """
        
        // アラートを作成
        let alert = UIAlertController(title: "Product Info", message: message, preferredStyle: .alert)
        
        // 画像を追加
        if let imageUrl = URL(string: imageUrl), let imageData = try? Data(contentsOf: imageUrl), let productImage = UIImage(data: imageData) {
            let imageView = UIImageView(frame: CGRect(x: 10, y: 220, width: 250, height: 250))
            imageView.contentMode = .scaleAspectFit
            imageView.image = productImage
            alert.view.addSubview(imageView)
            alert.view.heightAnchor.constraint(equalToConstant: 520).isActive = true
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
