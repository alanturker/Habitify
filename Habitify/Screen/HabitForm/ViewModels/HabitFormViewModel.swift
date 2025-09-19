//
//  HabitFormViewModel.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class HabitFormViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var habitName = ""
    @Published var selectedColor = "#9B59B6"
    @Published var selectedIcon = "star.fill"
    @Published var frequency: Frequency = .daily
    @Published var originalFrequency: Frequency = .daily
    @Published var selectedWeekdays = Set<Weekday>()
    @Published var monthlySelectedDates = Set<Date>()
    @Published var displayedMonth = Calendar.current.startOfDay(for: Date())
    @Published var showingDeleteAlert = false
    @Published var showingScheduleChangeAlert = false
    
    // MARK: - Private Properties
    private let habit: Habit?
    private let habitService: HabitService
    private let dateService = DateService.shared
    
    // MARK: - Computed Properties
    var isEditMode: Bool { habit != nil }
    var availableColors: [String] { ColorPalette.allCases.map { $0.rawValue } }
    
    // MARK: - Initialization
    init(habit: Habit?, habitService: HabitService) {
        self.habit = habit
        self.habitService = habitService
        loadHabitData()
    }
    
    // MARK: - Public Methods
    func saveHabit() {
        let weeklyDays = Array(selectedWeekdays.map { $0.rawValue }).sorted()
        let monthlyDays = extractMonthDays(from: monthlySelectedDates)
        
        if let habit = habit {
            // Check if schedule has changed
            if hasScheduleChanged(habit: habit, newFrequency: frequency, newWeeklyDays: weeklyDays, newMonthlyDays: monthlyDays) {
                showingScheduleChangeAlert = true
            } else {
                Task(priority: .userInitiated) {
                    await performSave(weeklyDays: weeklyDays, monthlyDays: monthlyDays)
                }  
            }
        } else {
            // Perform on background thread
            Task.detached(priority: .userInitiated) {
                await self.habitService.createHabit(name: self.habitName, colorHex: self.selectedColor, iconName: self.selectedIcon, frequency: self.frequency, weeklyDays: weeklyDays, monthlyDays: monthlyDays)
            }
        }
    }
    
    func confirmScheduleChange() async {
        let weeklyDays = Array(selectedWeekdays.map { $0.rawValue }).sorted()
        let monthlyDays = extractMonthDays(from: monthlySelectedDates)
        await performSave(weeklyDays: weeklyDays, monthlyDays: monthlyDays)
    }
    
    func deleteHabit() async {
        guard let habit = habit else { return }
        
        // Ensure model context is ready before delete
        await MainActor.run {
            // Force context update
            _ = habit.completions.count
        }
        
        await habitService.deleteHabit(habit)
    }
    
    func selectDefaultHabit(_ defaultHabit: DefaultHabit) {
        habitName = defaultHabit.name
        selectedIcon = defaultHabit.icon
    }
    
    func selectFrequency(_ newFrequency: Frequency) {
        // Immediate response without animation to prevent gesture timeout
        frequency = newFrequency
        originalFrequency = newFrequency
    }
    
    func toggleWeekday(_ day: Weekday) {
        if selectedWeekdays.contains(day) {
            selectedWeekdays.remove(day)
            // If removing a day and we're currently on daily, go back to weekly
            if frequency == .daily && originalFrequency == .weekly {
                frequency = .weekly
            }
        } else {
            selectedWeekdays.insert(day)
            // If all days selected, switch to daily but keep original frequency for UI
            if selectedWeekdays.count == Weekday.allCases.count {
                frequency = .daily
            }
        }
    }
    
    func handleMonthlySelectionChange(_ newValue: Set<Date>) {
        if isFullMonthSelected(newValue, month: displayedMonth) {
            frequency = .daily
        } else if frequency == .daily && originalFrequency == .monthly {
            // If removing a day and we're currently on daily, go back to monthly
            frequency = .monthly
        }
    }
    
    func updateModelContext(_ newContext: ModelContext) {
        habitService.updateModelContext(newContext)
    }
    
    // MARK: - Private Methods
    private func loadHabitData() {
        guard let habit = habit else { return }
        
        habitName = habit.name
        selectedColor = habit.colorHex
        selectedIcon = habit.iconName
        frequency = Frequency(rawValue: habit.frequencyRaw) ?? .daily
        originalFrequency = frequency
        selectedWeekdays = Set(habit.weeklyDays.compactMap { Weekday(rawValue: $0.dayNumber) })
        monthlySelectedDates = Set(habit.monthlyDays.compactMap { day in
            var comps = Calendar.current.dateComponents([.year, .month], from: Date())
            comps.day = day.dayNumber
            return Calendar.current.date(from: comps).map { Calendar.current.startOfDay(for: $0) }
        })
    }
    
    private func isFullMonthSelected(_ selected: Set<Date>, month: Date) -> Bool {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        let monthDays: Set<Date> = Set(range.compactMap { day -> Date? in
            var comps = calendar.dateComponents([.year, .month], from: startOfMonth)
            comps.day = day
            return calendar.date(from: comps).map { calendar.startOfDay(for: $0) }
        })
        return monthDays.isSubset(of: selected)
    }
    
    private func extractMonthDays(from dates: Set<Date>) -> [Int] {
        let calendar = Calendar.current
        return dates.map { calendar.component(.day, from: $0) }.sorted()
    }
    
    private func hasScheduleChanged(habit: Habit, newFrequency: Frequency, newWeeklyDays: [Int], newMonthlyDays: [Int]) -> Bool {
        // Check if frequency changed
        if habit.frequencyRaw != newFrequency.rawValue {
            return true
        }
        
        // Check if weekly days changed
        if newFrequency == .weekly {
            let currentWeeklyDays = Set(habit.weeklyDays.map { $0.dayNumber }).sorted()
            if currentWeeklyDays != newWeeklyDays {
                return true
            }
        }
        
        // Check if monthly days changed
        if newFrequency == .monthly {
            let currentMonthlyDays = Set(habit.monthlyDays.map { $0.dayNumber }).sorted()
            if currentMonthlyDays != newMonthlyDays {
                return true
            }
        }
        
        return false
    }
    
    private func performSave(weeklyDays: [Int], monthlyDays: [Int]) async {
        if let habit = habit {
            // Clean up old completions that are no longer scheduled
            cleanUpOldCompletions(habit: habit, newFrequency: frequency, newWeeklyDays: weeklyDays, newMonthlyDays: monthlyDays)
            
            // Update the habit on background thread
            await habitService.updateHabit(habit, name: habitName, colorHex: selectedColor, iconName: selectedIcon, frequency: frequency, weeklyDays: weeklyDays, monthlyDays: monthlyDays)
        } else {
            await habitService.createHabit(name: habitName, colorHex: selectedColor, iconName: selectedIcon, frequency: frequency, weeklyDays: weeklyDays, monthlyDays: monthlyDays)
        }
    }
    
    private func cleanUpOldCompletions(habit: Habit, newFrequency: Frequency, newWeeklyDays: [Int], newMonthlyDays: [Int]) {
        let calendar = Calendar.current
        let _ = calendar.startOfDay(for: Date())
        
        // Get all completions
        let completions = habit.completions
        
        // Filter out completions that are no longer scheduled
        let validCompletions = completions.filter { completion in
            let completionDate = completion.date
            
            switch newFrequency {
            case .daily:
                // Daily habits: all days are valid
                return true
            case .weekly:
                // Weekly habits: only days that match the new weekly schedule
                let weekday = calendar.component(.weekday, from: completionDate)
                return newWeeklyDays.contains(weekday)
            case .monthly:
                // Monthly habits: only days that match the new monthly schedule
                let dayOfMonth = calendar.component(.day, from: completionDate)
                return newMonthlyDays.contains(dayOfMonth)
            }
        }
        
        // Remove invalid completions
        let invalidCompletions = completions.filter { !validCompletions.contains($0) }
        for completion in invalidCompletions {
            if let index = habit.completions.firstIndex(of: completion) {
                habit.completions.remove(at: index)
            }
        }
    }
}
