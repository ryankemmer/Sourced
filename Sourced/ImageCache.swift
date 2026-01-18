//
//  ImageCache.swift
//  Sourced
//
//  Simple local image caching for profile photos
//

import UIKit

class ImageCache {
    static let shared = ImageCache()

    private let fileManager = FileManager.default

    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private init() {}

    private func fileURL(for key: String) -> URL? {
        cacheDirectory?.appendingPathComponent("\(key).jpg")
    }

    func saveImage(_ image: UIImage, forKey key: String) {
        guard let url = fileURL(for: key),
              let data = image.jpegData(compressionQuality: 0.8) else { return }

        try? data.write(to: url)
    }

    func loadImage(forKey key: String) -> UIImage? {
        guard let url = fileURL(for: key),
              let data = try? Data(contentsOf: url) else { return nil }

        return UIImage(data: data)
    }

    func removeImage(forKey key: String) {
        guard let url = fileURL(for: key) else { return }
        try? fileManager.removeItem(at: url)
    }
}
