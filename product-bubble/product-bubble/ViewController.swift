//
//  ViewController.swift
//  product-bubble
//
//  Created by ほしょ on 2024/06/08.
//

import UIKit

class ViewController: UIViewController {
    
    var draggableButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Info.plistから環境変数を読み取る
        let apiKey = Env.getAPI_KEY()
        print("API Key: \(apiKey)")
        
        // ボタンの作成
        draggableButton = UIButton(type: .custom)
        draggableButton.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        draggableButton.layer.cornerRadius = 50 // 正円にする
        draggableButton.backgroundColor = .blue
        view.addSubview(draggableButton)
        
        // パンジェスチャーレコグナイザーの追加
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        draggableButton.addGestureRecognizer(panGesture)
    }
    
    // パンジェスチャーのハンドラ
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        if let button = gesture.view {
            var newCenter = CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)
            
            // タブバーの高さを取得
            let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
            
            // ドラッグ範囲の制限
            newCenter.y = max(button.frame.height / 2, newCenter.y)
            newCenter.y = min(view.frame.height - tabBarHeight - button.frame.height / 2, newCenter.y)
            newCenter.x = max(button.frame.width / 2, newCenter.x)
            newCenter.x = min(view.frame.width - button.frame.width / 2, newCenter.x)
            
            button.center = newCenter
        }
        
        gesture.setTranslation(.zero, in: view)
    }
    
    
}

