//
//  ImageCheckView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/28.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import SDWebImage
import AVKit

final class ImageCheckView: NSView {
    private let nsfwLabel = MyTextField()
    let nsfwSw = NSButton()
    var urls: [URL] = []
    private var imageViews: [NSView] = []
    private var deleteButtons: [NSButton] = []
    
    init() {
        super.init(frame: NSRect.init(x: 0, y: 0, width: 0, height: 0))
        
        nsfwSw.setButtonType(NSButton.ButtonType.switch)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func add(imageUrl: URL) {
        guard let data = try? Data(contentsOf: imageUrl) else { return }
        
        if let image = NSImage(contentsOfFile: imageUrl.path) {
            addImage(imageUrl: imageUrl, image: image)
        } else if let image = SDWebImageWebPCoder().decodedImage(with: data) {
            addImage(imageUrl: imageUrl, image: image)
        } else {
            // 動画のプレビューイメージを作成
            let avAsset = AVURLAsset(url: imageUrl, options: nil)
            let generator = AVAssetImageGenerator(asset: avAsset)
            if let capturedImage = try? generator.copyCGImage(at: avAsset.duration, actualTime: nil) {
                let image = NSImage.init(cgImage: capturedImage, size: generator.maximumSize)
                addImage(imageUrl: imageUrl, image: image)
            }
        }
    }
    
    private func addImage(imageUrl: URL, image: NSImage) {
        if !self.urls.contains(imageUrl) {
            self.urls.append(imageUrl)
        }
        
        let imageView = NSImageView()
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        self.addSubview(imageView)
        self.imageViews.append(imageView)
        
        let deleteButton = NSButton()
        deleteButton.title = I18n.get("BUTTON_DELETE_IMAGE")
        deleteButton.wantsLayer = true
        deleteButton.layer?.backgroundColor = ThemeColor.opaqueButtonsBgColor.cgColor
        //deleteButton.clipsToBounds = true
        deleteButton.layer?.cornerRadius = 12
        self.addSubview(deleteButton)
        self.deleteButtons.append(deleteButton)
        deleteButton.target = self
        deleteButton.action = #selector(self.deleteAction(_:))
        
        self.needsLayout = true
    }
    
    @objc func deleteAction(_ sender: NSButton) {
        for (index, button) in self.deleteButtons.enumerated() {
            if sender == button {
                imageViews[index].removeFromSuperview()
                deleteButtons[index].removeFromSuperview()
                
                if index < urls.count {
                    urls.remove(at: index)
                    imageViews.remove(at: index)
                    deleteButtons.remove(at: index)
                }
                
                (self.superview as? TootView)?.refresh()
                
                self.needsLayout = true
                
                break
            }
        }
    }
    
}
