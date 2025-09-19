//
//  HabitAnalysisService.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import Foundation
import SwiftUI

final class HabitAnalysisService {
    static let shared = HabitAnalysisService()
    private let calendar = Calendar.current
    
    // MARK: - Caching
    private var completionCache: [String: Bool] = [:]
    private var streakCache: [String: Int] = [:]
    private var scheduledCache: [String: Bool] = [:]
    
    private init() {}
    
    // MARK: - Habit Computations
    func color(for habit: Habit) -> Color {
        Color(hex: habit.colorHex) ?? .blue
    }
    
    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        // Always calculate fresh to ensure accuracy
        let result = habit.completions.contains { completion in
            calendar.isDate(completion.date, inSameDayAs: date)
        }
        
        return result
    }
    
    func isCompletedToday(_ habit: Habit, today: Date = Date()) -> Bool {
        let startOfToday = calendar.startOfDay(for: today)
        return isCompleted(habit, on: startOfToday)
    }
    
    // MARK: - Streak Calculations
    func currentStreak(for habit: Habit, today: Date = Date()) -> Int {
        let cacheKey = "streak-\(habit.id.uuidString)-\(today.timeIntervalSince1970)"
        
        if let cached = streakCache[cacheKey] {
            return cached
        }
        
        guard !habit.completions.isEmpty else { 
            streakCache[cacheKey] = 0
            return 0 
        }
        
        let startOfToday = calendar.startOfDay(for: today)
        let sortedCompletions = habit.completions.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = startOfToday
        
        if !isCompletedToday(habit, today: today) {
            currentDate = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        }
        
        while true {
            if sortedCompletions.contains(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        streakCache[cacheKey] = streak
        return streak
    }
    
    func weeklyStreak(for habit: Habit, today: Date = Date()) -> Int {
        let cacheKey = "weekly-streak-\(habit.id.uuidString)-\(today.timeIntervalSince1970)"
        
        if let cached = streakCache[cacheKey] {
            return cached
        }
        
        guard !habit.completions.isEmpty else { 
            streakCache[cacheKey] = 0
            return 0 
        }
        
        let startOfToday = calendar.startOfDay(for: today)
        let scheduledWeekdays = Set(habit.weeklyDays.map { $0.dayNumber })
        guard !scheduledWeekdays.isEmpty else { 
            streakCache[cacheKey] = 0
            return 0 
        }
        
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysFromMonday = (weekday + 5) % 7
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfToday) ?? startOfToday
        
        var streak = 0
        var currentWeekStart = startOfWeek
        
        // Check current week first
        let currentWeekDays = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
        
        let currentScheduledDays = currentWeekDays.filter { date in
            let dayOfWeek = calendar.component(.weekday, from: date)
            return scheduledWeekdays.contains(dayOfWeek)
        }
        
        let currentCompletedDays = currentScheduledDays.filter { date in
            isCompleted(habit, on: date)
        }
        
        // If current week is not fully completed, start from previous week
        if currentCompletedDays.count != currentScheduledDays.count || currentScheduledDays.isEmpty {
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else { 
                streakCache[cacheKey] = 0
                return 0 
            }
            currentWeekStart = previousWeek
        }
        
        // Count consecutive completed weeks going backwards
        while true {
            let weekDays = (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
            }
            
            let scheduledDaysInWeek = weekDays.filter { date in
                let dayOfWeek = calendar.component(.weekday, from: date)
                return scheduledWeekdays.contains(dayOfWeek)
            }
            
            let completedScheduledDaysInWeek = scheduledDaysInWeek.filter { date in
                isCompleted(habit, on: date)
            }
            
            // If all scheduled days in this week are completed, count as 1 week streak
            if completedScheduledDaysInWeek.count == scheduledDaysInWeek.count && !scheduledDaysInWeek.isEmpty {
                streak += 1
                // Move to previous week
                guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else { break }
                currentWeekStart = previousWeek
            } else {
                break
            }
        }
        
        streakCache[cacheKey] = streak
        return streak
    }
    
    func streakText(for habit: Habit, today: Date = Date()) -> String {
        let frequency = Frequency(rawValue: habit.frequencyRaw) ?? .daily
        
        switch frequency {
        case .daily:
            let streak = currentStreak(for: habit, today: today)
            return streak > 0 ? "\(streak) day streak 🔥" : ""
        case .weekly:
            let streak = weeklyStreak(for: habit, today: today)
            return streak > 0 ? "\(streak) week streak 🔥" : ""
        case .monthly:
            return ""
        }
    }
    
    // MARK: - Scheduling Analysis
    func frequency(for habit: Habit) -> Frequency {
        Frequency(rawValue: habit.frequencyRaw) ?? .daily
    }
    
    func isScheduled(_ habit: Habit, on date: Date) -> Bool {
        let cacheKey = "\(habit.id.uuidString)-\(date.timeIntervalSince1970)-scheduled"
        
        if let cached = scheduledCache[cacheKey] {
            return cached
        }
        
        let result: Bool
        switch frequency(for: habit) {
        case .daily:
            result = true
        case .weekly:
            let weekday = calendar.component(.weekday, from: date)
            result = habit.weeklyDays.contains { $0.dayNumber == weekday }
        case .monthly:
            let day = calendar.component(.day, from: date)
            result = habit.monthlyDays.contains { $0.dayNumber == day }
        }
        
        scheduledCache[cacheKey] = result
        return result
    }
    
    func canToggleCompletion(_ habit: Habit, on date: Date) -> Bool {
        isScheduled(habit, on: date) && DateService.shared.isPastOrToday(date)
    }
    
    // MARK: - Completion Status
    func isWeekFullyCompleted(_ habit: Habit, for date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
        
        let weekDays = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
        
        let frequency = self.frequency(for: habit)
        
        switch frequency {
        case .daily:
            // For daily habits, check if all 7 days of the week are completed
            let completedDaysInWeek = weekDays.filter { weekDate in
                isCompleted(habit, on: weekDate)
            }
            return completedDaysInWeek.count == 7
        case .weekly:
            // For weekly habits, check if all scheduled days in the week are completed
            let scheduledDaysInWeek = weekDays.filter { weekDate in
                let dayOfWeek = calendar.component(.weekday, from: weekDate)
                return habit.weeklyDays.contains { $0.dayNumber == dayOfWeek }
            }
            
            let completedDaysInWeek = scheduledDaysInWeek.filter { weekDate in
                isCompleted(habit, on: weekDate)
            }
            
            return completedDaysInWeek.count == scheduledDaysInWeek.count && !scheduledDaysInWeek.isEmpty
        case .monthly:
            // For monthly habits, check if all scheduled days in the week are completed
            let scheduledDaysInWeek = weekDays.filter { weekDate in
                let dayOfMonth = calendar.component(.day, from: weekDate)
                return habit.monthlyDays.contains { $0.dayNumber == dayOfMonth }
            }
            
            let completedDaysInWeek = scheduledDaysInWeek.filter { weekDate in
                isCompleted(habit, on: weekDate)
            }
            
            return completedDaysInWeek.count == scheduledDaysInWeek.count && !scheduledDaysInWeek.isEmpty
        }
    }
    
    func isMonthFullyCompleted(_ habit: Habit, for date: Date) -> Bool {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        
        let monthDays = range.compactMap { day -> Date? in
            var comps = calendar.dateComponents([.year, .month], from: startOfMonth)
            comps.day = day
            return calendar.date(from: comps)
        }
        
        let frequency = self.frequency(for: habit)
        
        let scheduledDaysInMonth: [Date]
        switch frequency {
        case .daily:
            // For daily habits, all days in the month are scheduled
            scheduledDaysInMonth = monthDays
        case .weekly:
            // For weekly habits, only days that match the weekly schedule
            scheduledDaysInMonth = monthDays.filter { monthDate in
                let dayOfWeek = calendar.component(.weekday, from: monthDate)
                return habit.weeklyDays.contains { $0.dayNumber == dayOfWeek }
            }
        case .monthly:
            // For monthly habits, only specific days of the month
            scheduledDaysInMonth = monthDays.filter { monthDate in
                let dayOfMonth = calendar.component(.day, from: monthDate)
                return habit.monthlyDays.contains { $0.dayNumber == dayOfMonth }
            }
        }
        
        let completedDaysInMonth = scheduledDaysInMonth.filter { monthDate in
            isCompleted(habit, on: monthDate)
        }
        
        return completedDaysInMonth.count == scheduledDaysInMonth.count && !scheduledDaysInMonth.isEmpty
    }
    
    // MARK: - Filtering
    func habitsForDaily(_ habits: [Habit], on date: Date) -> [Habit] {
        habits.filter { isScheduled($0, on: date) }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        completionCache.removeAll(keepingCapacity: true)
        streakCache.removeAll(keepingCapacity: true)
        scheduledCache.removeAll(keepingCapacity: true)
    }
    
    func clearCache(for habit: Habit) {
        let habitId = habit.id.uuidString
        completionCache = completionCache.filter { !$0.key.hasPrefix(habitId) }
        streakCache = streakCache.filter { !$0.key.hasPrefix(habitId) }
        scheduledCache = scheduledCache.filter { !$0.key.hasPrefix(habitId) }
        
        // Also clear any date-specific caches for this habit
        let today = Calendar.current.startOfDay(for: Date())
        let todayKey = "\(habitId)-\(today.timeIntervalSince1970)"
        completionCache.removeValue(forKey: todayKey)
        completionCache.removeValue(forKey: "\(todayKey)-scheduled")
    }
    
    // Clear old cache entries to prevent memory buildup
    func cleanupOldCache() {
        // Keep only recent entries (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let cutoffTime = thirtyDaysAgo.timeIntervalSince1970
        
        completionCache = completionCache.filter { key, _ in
            if let timeInterval = Double(key.components(separatedBy: "-").last ?? "0") {
                return timeInterval >= cutoffTime
            }
            return true
        }
        
        scheduledCache = scheduledCache.filter { key, _ in
            if let timeInterval = Double(key.components(separatedBy: "-").last ?? "0") {
                return timeInterval >= cutoffTime
            }
            return true
        }
    }
}
