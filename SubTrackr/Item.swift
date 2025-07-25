//
//  Item.swift
//  SubTrackr
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
