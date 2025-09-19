//
//  HabitMonthlyView.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI

struct HabitMonthlyView: View {
    let habit: Habit
    let selectedDate: Date
    let monthDays: [Date]
    let isMonthCompleted: Bool
    let habitColor: Color
    let onToggleCompletion: (Date) -> Void
    
    private var calendarGrid: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) ?? selectedDate
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        
        // Get the first day of the month
        guard let firstDay = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: startOfMonth),
            month: calendar.component(.month, from: startOfMonth),
            day: 1
        )) else { return [] }
        
        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc.)
        let weekday = calendar.component(.weekday, from: firstDay)
        // Convert to Monday = 0, Tuesday = 1, ..., Sunday = 6
        let mondayBasedWeekday = (weekday + 5) % 7
        
        // Create grid with leading empty cells
        var grid: [Date?] = Array(repeating: nil, count: mondayBasedWeekday)
        
        // Add actual days of the month
        for day in range {
            if let date = calendar.date(from: DateComponents(
                year: calendar.component(.year, from: startOfMonth),
                month: calendar.component(.month, from: startOfMonth),
                day: day
            )) {
                grid.append(calendar.startOfDay(for: date))
            }
        }
        
        return grid
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: habit.iconName)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(habitColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(habit.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(habit.completions.count) days total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Weekday headers
            HStack {
                ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Month grid with scheduled/completed indications
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(calendarGrid.indices, id: \.self) { idx in
                    if let date = calendarGrid[idx] {
                        MonthDayView(
                            date: date,
                            habit: habit,
                            habitColor: habitColor,
                            selectedDate: selectedDate,
                            onToggleCompletion: { onToggleCompletion(date) }
                        )
                    } else {
                        // Empty cell for days before the month starts
                        Color.clear
                            .frame(height: 22)
                    }
                }
            }
        }
        .padding()
        .background(isMonthCompleted ? Color.green.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isMonthCompleted ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - MonthDayView
private struct MonthDayView: View {
    let date: Date
    let habit: Habit
    let habitColor: Color
    let selectedDate: Date
    let onToggleCompletion: () -> Void
    
    @State private var isScheduled: Bool = false
    @State private var isCompleted: Bool = false
    @State private var canToggle: Bool = false
    @State private var isToday: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? habitColor : Color.gray.opacity(0.15))
                .frame(width: 24, height: 24) // Reduced size
                .overlay(
                    Circle().stroke(
                        isScheduled ? habitColor : Color.clear, 
                        lineWidth: isScheduled ? (isToday ? 1.5 : 1) : 0
                    )
                )
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else if canToggle {
                // Show day number with a subtle indicator for completion
                VStack(spacing: 1) {
                    Text(DateService.shared.dayNumber(for: date))
                        .font(.caption2)
                        .foregroundColor(.primary)
                    Circle()
                        .fill(habitColor)
                        .frame(width: 3, height: 3)
                }
            } else {
                Text(DateService.shared.dayNumber(for: date))
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .onTapGesture {
            guard canToggle else { return }
            // Immediate response without any delays
            onToggleCompletion()
            // Immediate state update on main thread
            updateState()
        }
        .onAppear {
            updateState()
        }
        .onChange(of: habit.completions) { _, _ in
            // Immediate update without delay
            updateState()
        }
        .onChange(of: habit.frequencyRaw) { _, _ in
            updateState()
        }
        .onChange(of: habit.monthlyDays) { _, _ in
            updateState()
        }
        .onChange(of: selectedDate) { _, _ in
            updateState()
        }
    }
    
    private func updateState() {
        // Use direct calculation without cache to prevent hang
        let calendar = Calendar.current
        
        // Direct completion check
        isCompleted = habit.completions.contains { completion in
            calendar.isDate(completion.date, inSameDayAs: date)
        }
        
        // Direct schedule check
        let frequency = Frequency(rawValue: habit.frequencyRaw) ?? .daily
        switch frequency {
        case .daily:
            isScheduled = true
        case .weekly:
            let weekday = calendar.component(.weekday, from: date)
            isScheduled = habit.weeklyDays.contains { $0.dayNumber == weekday }
        case .monthly:
            let day = calendar.component(.day, from: date)
            isScheduled = habit.monthlyDays.contains { $0.dayNumber == day }
        }
        
        // Direct canToggle check
        canToggle = isScheduled && DateService.shared.isPastOrToday(date)
        isToday = DateService.shared.isSameDay(date, Date())
    }
}
