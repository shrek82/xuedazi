//
//  GameTypes.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation

enum GameState: Equatable {
    case idle       // Not started
    case playing    // In progress
    case paused     // Paused
    case gameOver   // Game over (settlement)
    case victory    // Victory (if applicable)
}

enum TeachingMode: Equatable {
    case normal
    case initials
    case finals
    case hidden
}

enum ContentKind: Equatable {
    case word
    case sequence
    case sentence
    case article
}
