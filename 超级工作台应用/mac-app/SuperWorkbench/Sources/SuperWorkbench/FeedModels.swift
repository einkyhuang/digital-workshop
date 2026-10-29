import Foundation

struct FeedsRegistryFile: Codable, Equatable {
    var version: Int?
    var timezone: String?
    var feeds: [FeedRegistryEntry]
}

struct FeedRegistryEntry: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var title: String
    var moduleId: String?
    var botId: String?
    var botName: String?
    var publicDir: String?
    var privateDir: String?
    var indexFile: String?
    var legacyGlob: String?
    var cardStyle: String?
    var workbenches: [String]?
    var description: String?
}

struct FeedIndexFile: Codable, Equatable {
    var version: Int?
    var feedId: String?
    var timezone: String?
    var updatedAt: String?
    var dates: [FeedIndexDate]
}

struct FeedIndexDate: Codable, Equatable, Identifiable, Hashable {
    var date: String
    var file: String?
    var summary: String?
    var articleCount: Int?
    var issueCount: Int?
    var id: String { date }
}

struct FeedDayDoc: Codable, Equatable {
    var version: Int?
    var feedId: String?
    var date: String?
    var timezone: String?
    var updatedAt: String?
    var botId: String?
    var botName: String?
    var summary: String?
    var articles: [FeedArticle]?
    var keywords: [FeedKeyword]?
    var images: [FeedImage]?
    var checks: [FeedCheck]?
    var issues: [FeedIssue]?
}

struct FeedArticle: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var title: String?
    var url: String?
    var status: String?
    var primaryKeyword: String?
    var secondaryKeywords: [String]?
    var image: String?
    var publishedAt: String?
    var notes: String?
}

struct FeedKeyword: Codable, Equatable, Hashable {
    var term: String?
    var intent: String?
    var priority: String?
}

struct FeedImage: Codable, Equatable, Hashable {
    var url: String?
    var alt: String?
    var ofArticleId: String?
}

struct FeedCheck: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String?
    var status: String?
    var detail: String?
}

struct FeedIssue: Codable, Equatable, Hashable {
    var severity: String?
    var title: String?
    var detail: String?
}
