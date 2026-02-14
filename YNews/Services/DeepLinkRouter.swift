//
//  DeepLinkRouter.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation

final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    static let didSetPendingArticleNotification = Notification.Name("DeepLinkRouter.didSetPendingArticle")

    private(set) var pendingArticle: Article?

    private init() {}

    func setPendingArticle(_ article: Article?) {
        pendingArticle = article
        if article != nil {
            NotificationCenter.default.post(name: Self.didSetPendingArticleNotification, object: self)
        }
    }

    func consumePendingArticle() -> Article? {
        let article = pendingArticle
        pendingArticle = nil
        return article
    }
}
