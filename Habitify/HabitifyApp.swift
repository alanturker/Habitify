//
//  HabitifyApp.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI
import SwiftData

@main
struct HabitifyApp: App {
    var body: some Scene {
        WindowGroup {
            HabitListView()
        }
        .modelContainer(for: [Habit.self, HabitCompletion.self, WeeklyDay.self, MonthlyDay.self])
    }
}


