//
//  NotificationService.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation
import UserNotifications


enum NotificationService {

    private static let center = UNUserNotificationCenter.current()
    private static let trendingIdentifierPrefix = "ynews.trending."
    static let notificationIdKey = "notificationId"

    private static var hasScheduledArticleNotificationThisSession = false

    static func requestPermission(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    static func scheduleTrendingNotification(for article: Article, delaySeconds: TimeInterval = 3) {
        let notificationId = UUID().uuidString
        NotificationArticleStore.save(notificationId: notificationId, article: article)

        let content = UNMutableNotificationContent()
        content.title = "🔥 Trending"
        content.body = article.title ?? ""
        content.sound = .default
        content.categoryIdentifier = "TRENDING_NEWS"
        content.userInfo = [notificationIdKey: notificationId]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delaySeconds), repeats: false)
        let request = UNNotificationRequest(identifier: trendingIdentifierPrefix + notificationId, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("NotificationService: failed to schedule – \(error)")
            }
        }
        hasScheduledArticleNotificationThisSession = true
    }

}
