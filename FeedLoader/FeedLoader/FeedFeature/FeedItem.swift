//
//  FeedItem.swift
//  FeedLoader
//
//  Created by sinbyte on 08/12/2024.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
