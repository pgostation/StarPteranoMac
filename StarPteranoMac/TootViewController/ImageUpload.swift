//
//  ImageUpload.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/02/19.
//  Copyright © 2019 pgostation. All rights reserved.
//

import Cocoa
import SDWebImage

final class ImageUpload {
    private init() { }
    
    // 画像のアップロード
    static func upload(httpMethod: String, imageUrl: URL, count: Int, uploadUrl: URL? = nil, filePathKey: String = "file", hostName: String, accessToken: String, callback: @escaping ([String: Any]?)->Void) {
        // 画像アップロード先URL
        guard let uploadUrl = uploadUrl ?? URL(string: "https://\(hostName)/api/v1/media") else { return }
        
        // imageData生成
        if imageUrl.path.lowercased().hasSuffix(".gif") {
            self.filename = "image.gif"
            self.mimetype = "image/gif"
            guard let data = try? Data(contentsOf: imageUrl) else { return }
            uploadData(httpMethod: httpMethod, uploadUrl: uploadUrl, filePathKey: filePathKey, data: data, accessToken: accessToken, callback: callback)
        } else if imageUrl.path.lowercased().hasSuffix(".png") {
            self.filename = "image.png"
            self.mimetype = "image/png"
            var imageData: Data? = nil
            guard let image = NSImage(contentsOfFile: imageUrl.path) else { return }
            if filePathKey == "avatar" || filePathKey == "header" {
                let smallImage = ImageUtils.small(image: image, pixels: 800 * 800)
                if let tiff = smallImage.tiffRepresentation {
                    let imgRep = NSBitmapImageRep(data: tiff)
                    imageData = imgRep?.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                }
            } else {
                let smallImage = ImageUtils.small(image: image, pixels: ImageUtils.maxPixels(hostName: hostName))
                if let tiff = smallImage.tiffRepresentation {
                    let imgRep = NSBitmapImageRep(data: tiff)
                    imageData = imgRep?.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                }
            }
            
            let data: Data = imageData ?? (try! Data(contentsOf: imageUrl))
            uploadData(httpMethod: httpMethod, uploadUrl: uploadUrl, filePathKey: filePathKey, data: data, accessToken: accessToken, callback: callback)
        } else {
            guard let image = NSImage(contentsOfFile: imageUrl.path) else { return }
            
            // JPEG圧縮
            var imageData: Data? = nil
            if filePathKey == "avatar" || filePathKey == "header" {
                let smallImage = ImageUtils.small(image: image, pixels: 800 * 800)
                if let tiff = smallImage.tiffRepresentation {
                    let imgRep = NSBitmapImageRep(data: tiff)
                    imageData = imgRep?.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])
                }
            } else {
                let smallImage = ImageUtils.small(image: image, pixels: ImageUtils.maxPixels(hostName: hostName))
                if let tiff = smallImage.tiffRepresentation {
                    let imgRep = NSBitmapImageRep(data: tiff)
                    imageData = imgRep?.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])
                }
            }
            
            let data: Data = imageData ?? (try! Data(contentsOf: imageUrl))
            self.filename = "image.jpeg"
            self.mimetype = "image/jpeg"
            self.uploadData(httpMethod: httpMethod, uploadUrl: uploadUrl, filePathKey: filePathKey, data: data, accessToken: accessToken, callback: callback)
        }
    }
    
    // 動画のアップロード
    static func upload(movieUrl: URL, uploadUrl: URL? = nil, filePathKey: String = "file", hostName: String, accessToken: String, callback: @escaping ([String: Any]?)->Void) {
        // 画像アップロード先URL
        guard let uploadUrl = uploadUrl ?? URL(string: "https://\(hostName)/api/v1/media") else { return }
        
        self.filename = "movie.mp4"
        self.mimetype = "video/mp4"
        guard let data = try? Data(contentsOf: movieUrl) else { return }
        uploadData(httpMethod: "POST", uploadUrl: uploadUrl, filePathKey: filePathKey, data: data, accessToken: accessToken, callback: callback)
    }
    
    // mediaデータのアップロード
    private static func uploadData(httpMethod: String, uploadUrl: URL, filePathKey: String, data: Data, accessToken: String, callback: @escaping ([String: Any]?)->Void) {
        // boudary生成
        let boundary = generateBoundaryString()
        
        // params生成
        let params: [String: String] = ["access_token": accessToken]
        
        // request生成
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = httpMethod
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBodyWith(parameters: params, filePathKey: filePathKey, data: data, boundary: boundary)
        
        // mediaアップロードPOST
        let task = MastodonRequest.session.dataTask(with: request, completionHandler: { data, response, error in
            if let response = response as? HTTPURLResponse {
                print("statusCode=\(response.statusCode)")
                print("#allHeaderFields=\(response.allHeaderFields)")
            }
            do {
                if let data = data, data.count > 0 {
                    let responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                    
                    callback(responseJson)
                } else if let error = error {
                    print(error.localizedDescription)
                    callback(nil)
                }
            } catch {
                print(response!)
            }
        })
        task.resume()
    }
    
    // ファイル名とmime/type
    private static var filename = ""
    private static var mimetype = ""
    
    // Create body for media
    // https://qiita.com/aryzae/items/8c16bc456588c1251f48
    private static func createBodyWith(parameters: [String: String]?, filePathKey: String, data: Data, boundary: String) -> Data {
        var body = Data()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimetype)\r\n\r\n")
        body.append(data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        return body
    }
    
    private static func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}

extension Data {
    public mutating func append(_ string: String) {
        let data = Data(string.utf8)
        return self.append(data)
    }
}
