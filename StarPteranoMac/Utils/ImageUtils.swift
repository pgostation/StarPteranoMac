//
//  ImageUtils.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa

final class ImageUtils {
    private static let scale = NSScreen.main?.backingScaleFactor ?? 1
    
    // 正方形の画像を縮小する
    // アイコンは36pt, 絵文字は40ptくらいにしたい
    static func small(image: EmojiImage, size: CGFloat) -> EmojiImage {
        if image.size.width < size * self.scale { return image }
        
        let rate = max(size / image.size.width, size / image.size.height)
        
        let resizedSize = CGSize(width: image.size.width * rate, height: image.size.height * rate)
        
        guard let cgImage = NSBitmapImageRep(data: image.tiffRepresentation!)?.cgImage else {
            return image
        }
        
        let width = Int(resizedSize.width)
        let height = Int(resizedSize.height)
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4) * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let bitmapContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        let bitmapRect = NSMakeRect(0, 0, resizedSize.width, resizedSize.height)
        
        bitmapContext.draw(cgImage, in: bitmapRect)
        
        guard let newImageRef = bitmapContext.makeImage() else { return image }
        let newImage = EmojiImage(cgImage: newImageRef, size: resizedSize)
        
        return newImage
    }
    
    // 正方形の画像を縮小する
    static func smallIcon(image: NSImage, size: CGFloat) -> NSImage {
        if image.size.width < size * self.scale { return image }
        
        let rate = max(size / image.size.width, size / image.size.height)
        
        let resizedSize = CGSize(width: image.size.width * rate, height: image.size.height * rate)
        
        guard let cgImage = NSBitmapImageRep(data: image.tiffRepresentation!)?.cgImage else {
            return image
        }
        
        let width = Int(resizedSize.width)
        let height = Int(resizedSize.height)
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4) * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let bitmapContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        let bitmapRect = NSMakeRect(0, 0, resizedSize.width, resizedSize.height)
        
        bitmapContext.draw(cgImage, in: bitmapRect)
        
        guard let newImageRef = bitmapContext.makeImage() else { return image }
        let newImage = NSImage(cgImage: newImageRef, size: resizedSize)
        
        return newImage
    }
    
    // 上下反転する (何故か絵文字が上下反転するので)
    static func flipped(_ image: NSImage) -> NSImage {
        let flippedImage = NSImage(size: image.size)
        flippedImage.lockFocus()
        
        let transform = NSAffineTransform()
        transform.translateX(by: 0, yBy: image.size.height)
        transform.scaleX(by: 1.0, yBy: -1.0)
        transform.concat()
        
        let rect = NSRect(origin: NSZeroPoint, size: image.size)
        image.draw(at: NSZeroPoint, from: rect, operation: .sourceOver, fraction: 1.0)
        flippedImage.unlockFocus()
        return flippedImage
    }
}
