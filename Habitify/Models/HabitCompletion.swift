//
//  HabitCompletion.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//


import SwiftUI
import SwiftData

@Model
final class HabitCompletion {
    var id: UUID
    var date: Date
    
    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
    }
}
