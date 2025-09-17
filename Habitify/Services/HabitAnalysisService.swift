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
    
    private init() {}
    
    // MARK: - Habit Computations
    func color(for habit: Habit) -> Color {
        Color(hex: habit.colorHex) ?? .blue
    }
    
    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        habit.completions.contains { completion in
            calendar.isDate(completion.date, inSameDayAs: date)
        }
    }
    
    func isCompletedToday(_ habit: Habit, today: Date = Date()) -> Bool {
        let startOfToday = calendar.startOfDay(for: today)
        return isCompleted(habit, on: startOfToday)
    }
    
    // MARK: - Streak Calculations
    func currentStreak(for habit: Habit, today: Date = Date()) -> Int {
        guard !habit.completions.isEmpty else { return 0 }
        
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
        
        return streak
    }
    
    func weeklyStreak(for habit: Habit, today: Date = Date()) -> Int {
        guard !habit.completions.isEmpty else { return 0 }
        
        let startOfToday = calendar.startOfDay(for: today)
        let scheduledWeekdays = Set(habit.weeklyDays)
        guard !scheduledWeekdays.isEmpty else { return 0 }
        
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
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else { return 0 }
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
        switch frequency(for: habit) {
        case .daily:
            return true
        case .weekly:
            let weekday = calendar.component(.weekday, from: date)
            return habit.weeklyDays.contains(weekday)
        case .monthly:
            let day = calendar.component(.day, from: date)
            return habit.monthlyDays.contains(day)
        }
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
                return habit.weeklyDays.contains(dayOfWeek)
            }
            
            let completedDaysInWeek = scheduledDaysInWeek.filter { weekDate in
                isCompleted(habit, on: weekDate)
            }
            
            return completedDaysInWeek.count == scheduledDaysInWeek.count && !scheduledDaysInWeek.isEmpty
        case .monthly:
            // For monthly habits, check if all scheduled days in the week are completed
            let scheduledDaysInWeek = weekDays.filter { weekDate in
                let dayOfMonth = calendar.component(.day, from: weekDate)
                return habit.monthlyDays.contains(dayOfMonth)
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
                return habit.weeklyDays.contains(dayOfWeek)
            }
        case .monthly:
            // For monthly habits, only specific days of the month
            scheduledDaysInMonth = monthDays.filter { monthDate in
                let dayOfMonth = calendar.component(.day, from: monthDate)
                return habit.monthlyDays.contains(dayOfMonth)
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
}
