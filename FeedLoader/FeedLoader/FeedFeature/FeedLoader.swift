//
//  FeedLoader.swift
//  FeedLoader
//
//  Created by sinbyte on 08/12/2024.
//

import Foundation

enum LoadFeedResult{
    case success([FeedItem])
    case fail(Error)
}

protocol FeedLoader{
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
