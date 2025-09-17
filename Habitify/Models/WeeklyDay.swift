//
//  WeeklyDay.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftData
import Foundation

@Model
final class WeeklyDay {
    var dayNumber: Int // 1...7 (Sunday=1)
    
    init(dayNumber: Int) {
        self.dayNumber = dayNumber
    }
}
