//
//  Habit.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var iconName: String
    
    // Scheduling
    var frequencyRaw: Int // Frequency.rawValue
    var weeklyDays: [Int] // 1...7 (Sunday=1)
    var monthlyDays: [Int] // 1...31
    
    @Relationship(deleteRule: .cascade)
    var completions: [HabitCompletion] = []
    
    init(name: String, colorHex: String = "#007AFF", iconName: String = "star.fill") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.iconName = iconName
        self.frequencyRaw = Frequency.daily.rawValue
        self.weeklyDays = []
        self.monthlyDays = []
    }
}
