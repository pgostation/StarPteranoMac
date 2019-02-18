//
//  ImageViewController.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/28.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ImageViewController: NSViewController {
    private let imageView = MyImageView()
    private let coverButton = NSButton()
    private let leftButton = NSButton()
    private let rightButton = NSButton()
    private var selectedIndex: Int
    private let imagesUrls: [String]
    private let previewUrls: [String]
    
    init(imagesUrls: [String], previewUrls: [String], index: Int, smallImage: NSImage?) {
        self.imagesUrls = imagesUrls
        self.previewUrls = previewUrls
        self.selectedIndex = index
        
        super.init(nibName: nil, bundle: nil)
        
        self.view = NSView()
        
        view.addSubview(imageView)
        
        imageView.imageScaling = .scaleProportionallyUpOrDown
        
        // 適度な大きさで表示
        if let smallImage = smallImage {
            imageView.image = smallImage
            let rate = 1000 / max(1, smallImage.size.width + smallImage.size.height)
            imageView.frame = NSRect(x: 0, y: 0, width: rate * smallImage.size.width, height: rate * smallImage.size.height)
        } else {
            imageView.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        }
        
        if imagesUrls.count <= 1 {
            self.view.frame = NSRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height)
        } else {
            self.view.frame = NSRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height + 40)
            imageView.frame.origin.y += 40
            
            // 左右ボタン追加
            addLeftRightButtons()
        }
        
        // 画像クリックボタン追加
        view.addSubview(coverButton)
        coverButton.frame = imageView.frame
        coverButton.isTransparent = true
        coverButton.target = self
        coverButton.action = #selector(tapAction)
        
        // フル画像読み込み
        let index = selectedIndex
        ImageCache.image(urlStr: imagesUrls[index], isTemp: true, isSmall: false) { [weak self] image in
            if index != self?.selectedIndex { return }
            self?.imageView.image = image
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addLeftRightButtons() {
        view.addSubview(leftButton)
        view.addSubview(rightButton)
        
        leftButton.title = "<"
        rightButton.title = ">"
        
        leftButton.target = self
        leftButton.action = #selector(leftAction)
        rightButton.target = self
        rightButton.action = #selector(rightAction)
        
        leftButton.frame = NSRect(x: 0,
                                  y: 5,
                                  width: 50,
                                  height: 30)
        
        rightButton.frame = NSRect(x: 60,
                                   y: 5,
                                   width: 50,
                                   height: 30)
    }
    
    @objc func leftAction() {
        selectedIndex = max(0, selectedIndex - 1)
        
        reloadImage()
    }
    
    @objc func rightAction() {
        selectedIndex = min(imagesUrls.count - 1, selectedIndex + 1)
        
        reloadImage()
    }
    
    private func reloadImage() {
        if selectedIndex == 0 {
            leftButton.title = "|<"
        } else {
            leftButton.title = "<"
        }
        
        if selectedIndex == imagesUrls.count - 1 {
            rightButton.title = ">|"
        } else {
            rightButton.title = ">"
        }
        
        let index = selectedIndex
        ImageCache.image(urlStr: previewUrls[selectedIndex], isTemp: false, isSmall: false) { [weak self] image in
            if index != self?.selectedIndex { return }
            self?.imageView.image = image
        }
        
        ImageCache.image(urlStr: imagesUrls[selectedIndex], isTemp: true, isSmall: false) { [weak self] image in
            if index != self?.selectedIndex { return }
            self?.imageView.image = image
        }
    }
    
    func layout() {
        imageView.frame = NSRect(x: 0,
                                 y: imageView.frame.minY,
                                 width: view.frame.width,
                                 height: view.frame.height)
        
        coverButton.frame = imageView.frame
    }
    
    @objc func tapAction() {
        guard let url = URL(string: imagesUrls[selectedIndex]) else { return }
        NSWorkspace.shared.open(url)
    }
}
