//
//  ImageUtils.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2018/10/27.
//  Copyright © 2018 pgostation. All rights reserved.
//

import Cocoa
import CoreGraphics

final class ImageUtils {
    private static let scale = NSScreen.main?.backingScaleFactor ?? 1
    
    // 正方形の画像を縮小する
    // アイコンは36pt, 絵文字は40ptくらいにしたい
    static func small(image: EmojiImage, size: CGFloat) -> EmojiImage {
        if image.size.width < size * self.scale { return image }
        
        let rate = max(size * self.scale / image.size.width, size * self.scale / image.size.height)
        
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
        
        let rate = max(size * self.scale / image.size.width, size * self.scale / image.size.height)
        
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
    
    // 画像をピクセル数以内に縮小する
    static func small(image: NSImage, pixels: CGFloat) -> NSImage {
        if image.size.width * image.size.height < pixels { return image }
        
        let rate = sqrt(pixels / (image.size.width * image.size.height))
        
        let resizedSize = CGSize(width: floor(image.size.width * rate), height: floor(image.size.height * rate))
        
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
    static func flipped(_ image: NSImage) -> EmojiImage {
        let flippedImage = EmojiImage(size: image.size)
        flippedImage.lockFocus()
        
        let transform = NSAffineTransform()
        transform.translateX(by: 0, yBy: image.size.height)
        transform.scaleX(by: 1.0, yBy: -1.0)
        transform.concat()
        
        let rect = NSRect(origin: NSZeroPoint, size: image.size)
        image.draw(at: NSZeroPoint, from: rect, operation: .sourceOver, fraction: 1.0)
        flippedImage.unlockFocus()
        
        flippedImage.shortcode = (image as? EmojiImage)?.shortcode
        
        return flippedImage
    }
    
    // 指定色のNSImageを作成 (面倒なことしてるのは、CoreGraphicsを使いたかっただけなのです)
    static func colorImage(color: NSColor) -> NSImage? {
        guard let offscreenRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 1, // 1px width
            pixelsHigh: 1, // 1px height
            bitsPerSample: 8, // 8*4 = 32bitColor
            samplesPerPixel: 4, //RGBA
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSColorSpaceName.deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0) else {
                return nil
        }
        
        let image: NSImage
        do {
            let g = NSGraphicsContext(bitmapImageRep: offscreenRep)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = g
            let context = g?.cgContext
            
            color.set()
            context?.fill(NSRect(x: 0, y: 0, width: 1, height: 1))
            image = NSImage(size: NSSize(width: 1, height: 1))
            image.addRepresentation(offscreenRep)
            NSGraphicsContext.restoreGraphicsState()
        }
        
        return image
    }
    
    // 画像の最大ピクセル数
    static func maxPixels(hostName: String) -> CGFloat {
        // imastodonでは1920 * 1920
        if hostName == "imastodon.net" {
            return 1920 * 1920
        }
        
        // bbbdn.jpでは2560 * 1280
        if hostName == "bbbdn.jp" {
            return 2560 * 1280
        }
        
        // デフォルト
        return 1280 * 1280
    }
}
