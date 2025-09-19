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
    
    // MARK: - Initialization
    init(habitService: HabitService) {
        self.habitService = habitService
    }
    
    // MARK: - Computed Properties
    var headerDates: [Date] {
        dateService.lifetimeDates()
    }
    
    var weekDays: [Date] {
        dateService.weekDays(for: selectedDate)
    }
    
    var monthDays: [Date] {
        dateService.monthDays(for: selectedDate)
    }
    
    // MARK: - UI Actions
    func showAddHabit() {
        showingAddHabit = true
    }
    
    func selectHabit(_ habit: Habit) {
        selectedHabit = habit
    }
    
    func selectTab(_ tab: Frequency) {
        withAnimation(.spring(response: 0.3)) {
            selectedTab = tab
        }
    }
    
    func selectDate(_ date: Date) {
        withAnimation(.spring(response: 0.3)) {
            selectedDate = Calendar.current.startOfDay(for: date)
        }
    }
    
    func scrollToCurrentDay() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            selectedDate = Calendar.current.startOfDay(for: Date())
            scrollToToday = true
        }
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
    
    func isCompletedToday(_ habit: Habit, today: Date = Date()) -> Bool {
        analysisService.isCompletedToday(habit, today: today)
    }
    
    func currentStreak(for habit: Habit, today: Date = Date()) -> Int {
        analysisService.currentStreak(for: habit, today: today)
    }
    
    func weeklyStreak(for habit: Habit, today: Date = Date()) -> Int {
        analysisService.weeklyStreak(for: habit, today: today)
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
    
    func habitsForDate(_ habits: [Habit], on date: Date) -> [Habit] {
        return habits.filter { habit in
            analysisService.isScheduled(habit, on: date)
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
        habitService.toggleCompletion(for: habit, on: date)
    }
}

