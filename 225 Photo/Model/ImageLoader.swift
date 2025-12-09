//
//  ImageLoader.swift
//  225 Photo
//
//  Общий менеджер загрузки и кэша картинок.
//

import Foundation
import UIKit
import SwiftUI

/// Глобальный менеджер загрузки изображений.
/// - in-memory кэш (NSCache)
/// - дедупликация запросов по URL
/// - prefetch в фоне
final class ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let lock = NSLock()
    private var tasks: [URL: Task<UIImage?, Never>] = [:]

    private init() {
        cache.countLimit = 200               // до 200 картинок в памяти
        cache.totalCostLimit = 200 * 1024 * 1024 // ~200 MB
    }

    /// Синхронное получение кэшированного изображения (если уже есть).
    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    /// Асинхронная загрузка изображения с кэшем и дедупликацией запросов.
    func loadImage(from url: URL) async -> UIImage? {
        // 1. Сначала пробуем кэш
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        // 2. Проверяем, не грузится ли уже этот URL
        lock.lock()
        if let existing = tasks[url] {
            lock.unlock()
            return await existing.value
        }

        // 3. Создаём новую задачу загрузки
        let task = Task<UIImage?, Never> {
            defer {
                self.lock.lock()
                self.tasks[url] = nil
                self.lock.unlock()
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                self.cache.setObject(image, forKey: url as NSURL, cost: data.count)
                return image
            } catch {
                return nil
            }
        }

        tasks[url] = task
        lock.unlock()

        return await task.value
    }

    /// Prefetch списка URL — грузит и кладёт в кэш в фоне,
    /// вне зависимости от того, отображается ли сейчас картинка.
    func prefetch(urls: [URL]) {
        guard !urls.isEmpty else { return }

        Task.detached { [weak self] in
            guard let self = self else { return }
            for url in urls {
                _ = await self.loadImage(from: url)
            }
        }
    }
}

// MARK: - SwiftUI-обёртка

/// View, которое использует ImageLoader вместо AsyncImage
/// и понимает кэш.
struct CachedAsyncImage<Placeholder: View>: View {

    let url: URL?
    let cornerRadius: CGFloat
    let contentMode: ContentMode
    let placeholder: Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        cornerRadius: CGFloat = 0,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                placeholder
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard !isLoading else { return }
        guard let url = url else {
            image = nil
            return
        }
        isLoading = true
        image = await ImageLoader.shared.loadImage(from: url)
        isLoading = false
    }
}
