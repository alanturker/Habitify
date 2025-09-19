//
//  HabitListViewModel.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class HabitListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTab: Frequency = .daily
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var showingAddHabit = false
    @Published var selectedHabit: Habit?
    @Published var scrollToToday = false
    
    // MARK: - Private Properties
    private let analysisService = HabitAnalysisService.shared
    private let dateService = DateService.shared
    private let habitService: HabitService
    
    // MARK: - Caching Properties
    private var cachedHeaderDates: [Date]?
    private var cachedWeekDays: [Date]?
    private var cachedMonthDays: [Date]?
    private var lastCachedDate: Date?
    
    // MARK: - Initialization
    init(habitService: HabitService) {
        self.habitService = habitService
    }
    
    // MARK: - Computed Properties
    var headerDates: [Date] {
        if let cached = cachedHeaderDates {
            return cached
        }
        let dates = dateService.lifetimeDates()
        cachedHeaderDates = dates
        return dates
    }
    
    var weekDays: [Date] {
        if let cached = cachedWeekDays, lastCachedDate == selectedDate {
            return cached
        }
        let dates = dateService.weekDays(for: selectedDate)
        cachedWeekDays = dates
        lastCachedDate = selectedDate
        return dates
    }
    
    var monthDays: [Date] {
        if let cached = cachedMonthDays, lastCachedDate == selectedDate {
            return cached
        }
        let dates = dateService.monthDays(for: selectedDate)
        cachedMonthDays = dates
        lastCachedDate = selectedDate
        return dates
    }
    
    // MARK: - UI Actions
    func showAddHabit() {
        showingAddHabit = true
    }
    
    func selectHabit(_ habit: Habit) {
        selectedHabit = habit
    }
    
    func selectTab(_ tab: Frequency) {
        // Immediate response without animation to prevent gesture timeout
        selectedTab = tab
    }
    
    func selectDate(_ date: Date) {
        let newDate = Calendar.current.startOfDay(for: date)
        if newDate != selectedDate {
            // Clear cache when date changes
            cachedWeekDays = nil
            cachedMonthDays = nil
            
            // Clear analysis cache to force fresh calculation
            HabitAnalysisService.shared.clearCache()
            
            // Immediate response without animation to prevent gesture timeout
            selectedDate = newDate
        }
    }
    
    func scrollToCurrentDay() {
        // Immediate response without animation to prevent gesture timeout
        selectedDate = Calendar.current.startOfDay(for: Date())
        scrollToToday = true
    }
    
    func updateModelContext(_ newContext: ModelContext) {
        habitService.updateModelContext(newContext)
    }
    
    // MARK: - Habit Computations
    func color(for habit: Habit) -> Color {
        analysisService.color(for: habit)
    }
    
    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        analysisService.isCompleted(habit, on: date)
    }
    
    
    func currentStreak(for habit: Habit, today: Date = Date()) -> Int {
        analysisService.currentStreak(for: habit, today: today)
    }
    
    func weeklyStreak(for habit: Habit, today: Date = Date()) -> Int {
        analysisService.weeklyStreak(for: habit, today: today)
    }
    
    func habitsForDate(_ habits: [Habit], on date: Date) -> [Habit] {
        return habits.filter { habit in
            analysisService.isScheduled(habit, on: date)
        }
    }
    
    func streakText(for habit: Habit, today: Date = Date()) -> String {
        analysisService.streakText(for: habit, today: today)
    }
    
    // MARK: - Scheduling Analysis
    func frequency(for habit: Habit) -> Frequency {
        analysisService.frequency(for: habit)
    }
    
    func isScheduled(_ habit: Habit, on date: Date) -> Bool {
        analysisService.isScheduled(habit, on: date)
    }
    
    func canToggleCompletion(_ habit: Habit, on date: Date) -> Bool {
        analysisService.canToggleCompletion(habit, on: date)
    }
    
    // MARK: - Completion Status
    func isWeekFullyCompleted(_ habit: Habit, for date: Date) -> Bool {
        analysisService.isWeekFullyCompleted(habit, for: date)
    }
    
    func isMonthFullyCompleted(_ habit: Habit, for date: Date) -> Bool {
        analysisService.isMonthFullyCompleted(habit, for: date)
    }
    
    // MARK: - Filtering
    func habitsForDaily(_ habits: [Habit], on date: Date) -> [Habit] {
        analysisService.habitsForDaily(habits, on: date)
    }
    
    func habitsForWeekly(_ habits: [Habit], for weekStartDate: Date) -> [Habit] {
        let weekDays = dateService.weekDays(for: weekStartDate)
        return habits.filter { habit in
            // Check if this habit has any scheduled days in this week
            return weekDays.contains { date in
                analysisService.isScheduled(habit, on: date)
            }
        }
    }
    
    func habitsForMonthly(_ habits: [Habit], for monthDate: Date) -> [Habit] {
        let monthDays = dateService.monthDays(for: monthDate)
        return habits.filter { habit in
            // Check if this habit has any scheduled days in this month
            return monthDays.contains { date in
                analysisService.isScheduled(habit, on: date)
            }
        }
    }
    
    
    // MARK: - Date Utilities
    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        dateService.isSameDay(lhs, rhs)
    }
    
    func weekdayLabel(for date: Date) -> String {
        dateService.weekdayLabel(for: date)
    }
    
    func dayNumber(for date: Date) -> String {
        dateService.dayNumber(for: date)
    }
    
    func monthYearText(for date: Date) -> (month: String, year: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: date)
        
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: date)
        
        return (month: month, year: year)
    }
    
    // MARK: - Habit Actions
    func toggleCompletion(for habit: Habit, on date: Date) {
        // Perform immediately on background thread with high priority
        Task.detached(priority: .high) {
            await self.habitService.toggleCompletion(for: habit, on: date)
            
            // Force UI update on main thread
            await MainActor.run {
                // This will trigger UI refresh
                _ = habit.completions.count
            }
        }
    }
}

