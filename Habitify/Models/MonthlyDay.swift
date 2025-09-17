//
//  MonthlyDay.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftData
import Foundation

@Model
final class MonthlyDay {
    var dayNumber: Int // 1...31
    
    init(dayNumber: Int) {
        self.dayNumber = dayNumber
    }
}
