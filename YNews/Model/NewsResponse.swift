//
//  NewsResponse.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import Foundation

struct NewsResponse: Decodable {
    let totalResults: Int
    let articles: [Article]

    private enum CodingKeys: String, CodingKey {
        case status, totalResults, articles
    }

    init(totalResults: Int?, articles: [Article]) {
        self.totalResults = totalResults ?? 0
        self.articles = articles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let status = try container.decodeIfPresent(String.self, forKey: .status) ?? "ok"
        guard status == "ok" else {
            totalResults = 0
            articles = []
            return
        }

        totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults) ?? 0
        articles = try container.decodeIfPresent([Article].self, forKey: .articles) ?? []
    }
}

struct Article: Codable, Equatable {
    let title: String?
    let description: String?
    let content: String?
    let source: Source?
    let urlToImage: String?
    let publishedAt: String

    var publishedAtDate: String {
        let isoFormatter = ISO8601DateFormatter()

        guard let date = isoFormatter.date(from: publishedAt) else {
            return publishedAt
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }

    struct Source: Codable, Equatable {
        let name: String
    }

    var bookmarkKey: String {
        "\(title ?? "")|\(publishedAt)|\(source?.name ?? "")"
    }
}
