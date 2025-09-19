//
//  HabitService.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class HabitService: ObservableObject {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updateModelContext(_ newContext: ModelContext) {
        self.modelContext = newContext
    }
    
    // MARK: - Habit CRUD Operations
    func createHabit(name: String, colorHex: String, iconName: String, frequency: Frequency, weeklyDays: [Int], monthlyDays: [Int]) async {
        let habit = Habit(name: name, colorHex: colorHex, iconName: iconName)
        habit.frequencyRaw = frequency.rawValue
        
        // Create WeeklyDay objects
        habit.weeklyDays = weeklyDays.map { WeeklyDay(dayNumber: $0) }
        
        // Create MonthlyDay objects
        habit.monthlyDays = monthlyDays.map { MonthlyDay(dayNumber: $0) }
        
        modelContext.insert(habit)
        await saveContext()
    }
    
    func updateHabit(_ habit: Habit, name: String, colorHex: String, iconName: String, frequency: Frequency, weeklyDays: [Int], monthlyDays: [Int]) async {
        habit.name = name
        habit.colorHex = colorHex
        habit.iconName = iconName
        habit.frequencyRaw = frequency.rawValue
        
        // Clear existing days
        habit.weeklyDays.removeAll()
        habit.monthlyDays.removeAll()
        
        // Create new WeeklyDay objects
        habit.weeklyDays = weeklyDays.map { WeeklyDay(dayNumber: $0) }
        
        // Create new MonthlyDay objects
        habit.monthlyDays = monthlyDays.map { MonthlyDay(dayNumber: $0) }
        
        // Clear cache for this habit since schedule changed
        await MainActor.run {
            HabitAnalysisService.shared.clearCache(for: habit)
        }
        
        await saveContext()
    }
    
    func deleteHabit(_ habit: Habit) async {
        // Ensure context is ready
        await MainActor.run {
            // Force context validation
            _ = modelContext.container
        }
        
        modelContext.delete(habit)
        await saveContext()
    }
    
    // MARK: - Habit Completion Operations
    func toggleCompletion(for habit: Habit, on date: Date) async {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        // Use more efficient search
        if let index = habit.completions.firstIndex(where: {
            calendar.isDate($0.date, inSameDayAs: targetDay)
        }) {
            habit.completions.remove(at: index)
        } else {
            let completion = HabitCompletion(date: targetDay)
            habit.completions.append(completion)
        }
        
        // Save immediately without waiting for cache operations
        await saveContext()
    }
    
    // MARK: - Private Methods
    private func saveContext() async {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
