//
//  NotificationArticleStore.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation

enum NotificationArticleStore {
    private static let keyPrefix = "ynews.notification.article."

    static func save(notificationId: String, article: Article) {
        guard let data = try? JSONEncoder().encode(article) else { return }
        UserDefaults.standard.set(data, forKey: keyPrefix + notificationId)
        UserDefaults.standard.synchronize()
    }

    static func article(for notificationId: String) -> Article? {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + notificationId),
              let article = try? JSONDecoder().decode(Article.self, from: data) else { return nil }
        return article
    }

    static func remove(notificationId: String) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + notificationId)
    }
}
