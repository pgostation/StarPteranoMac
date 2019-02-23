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
    let nsfwSw = NSButton()
    var urls: [URL] = []
    private var imageViews: [NSView] = []
    private var deleteButtons: [NSButton] = []
    
    override var tag: Int {
        return 7624
    }
    
    init() {
        super.init(frame: NSRect.init(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(nsfwSw)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        
        let attributedTitle = NSMutableAttributedString(string: "NSFW")
        attributedTitle.addAttributes([NSAttributedString.Key.foregroundColor : ThemeColor.contrastColor], range: NSRange.init(location: 0, length: attributedTitle.length))
        nsfwSw.attributedTitle = attributedTitle
        nsfwSw.setButtonType(NSButton.ButtonType.switch)
        if SettingsData.defaultNSFW {
            nsfwSw.state = .on
        }
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
                
                (self.superview?.viewWithTag(8364) as? TootView)?.refresh()
                
                self.needsLayout = true
                
                if urls.count == 0 {
                    self.removeFromSuperview()
                }
                
                break
            }
        }
    }
    
    override func layout() {
        let imageSize: CGFloat = min(150, (self.superview?.frame.width ?? 300) / 2 - 20)
        var x: CGFloat = 0
        var y: CGFloat = 0
        for imageView in self.imageViews {
            imageView.frame = CGRect(x: 5 + x * (imageSize + 10),
                                     y: y * (imageSize + 60),
                                     width: imageSize,
                                     height: imageSize)
            
            x += 1
            if x >= 2 {
                x = 0
                y += 1
            }
        }
        
        x = 0
        y = 0
        for deleteButton in self.deleteButtons {
            deleteButton.frame = CGRect(x: 40 + x * (imageSize + 10),
                                        y: 150 + y * (imageSize + 60),
                                        width: 80,
                                        height: 30)
            
            x += 1
            if x >= 2 {
                x = 0
                y += 1
            }
        }
        
        let height = 45 + y * (imageSize + 60) + imageSize + 40
        
        self.frame.size.width = min(300, (self.superview?.frame.width ?? 300))
        self.frame.size.height = height
        
        nsfwSw.frame = CGRect(x: 10,
                              y: height - 30,
                              width: 150,
                              height: 20)
    }
}
