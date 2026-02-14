//
//  ImageLoader.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import Foundation
import UIKit


final class ImageLoader {

    static let shared = ImageLoader()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let diskCacheURL: URL
    private let fileManager  = FileManager.default
    private let ioQueue      = DispatchQueue(label: "com.app.ImageLoader.io", qos: .utility)

    private init() {

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        memoryCache.totalCostLimit = 50 * 1024 * 1024
    }

    // MARK: - Public

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let nsURL = url as NSURL


        if let cached = memoryCache.object(forKey: nsURL) {
            completion(cached)
            return
        }


        let filePath = diskPath(for: url)
        ioQueue.async { [weak self] in
            guard let self else { return }
            if let data  = try? Data(contentsOf: filePath),
               let image = UIImage(data: data) {
                self.memoryCache.setObject(image, forKey: nsURL,
                                           cost: data.count)
                DispatchQueue.main.async { completion(image) }
                return
            }

            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard
                    let self,
                    error == nil,
                    let data,
                    let image = UIImage(data: data)
                else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                self.memoryCache.setObject(image, forKey: nsURL, cost: data.count)
                // Write to disk on the IO queue (already on it here).
                try? data.write(to: filePath, options: .atomic)

                DispatchQueue.main.async { completion(image) }
            }.resume()
        }
    }


    func clearDiskCache() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            try? self.fileManager.removeItem(at: self.diskCacheURL)
            try? self.fileManager.createDirectory(at: self.diskCacheURL,
                                                   withIntermediateDirectories: true)
        }
    }


    private func diskPath(for url: URL) -> URL {
        let key = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        let filename = String(key.prefix(200))
        return diskCacheURL.appendingPathComponent(filename)
    }
}


