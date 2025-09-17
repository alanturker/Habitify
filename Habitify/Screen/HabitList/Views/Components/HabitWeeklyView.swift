//
//  HabitWeeklyView.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI

struct HabitWeeklyView: View {
    let habit: Habit
    let selectedDate: Date
    let weekDays: [Date]
    let isWeekCompleted: Bool
    let streakText: String
    let habitColor: Color
    let onToggleCompletion: (Date) -> Void
    
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
                
                if !streakText.isEmpty {
                    Text(streakText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { date in
                    WeekDayView(
                        date: date,
                        habit: habit,
                        habitColor: habitColor,
                        onToggleCompletion: { onToggleCompletion(date) }
                    )
                }
            }
        }
        .padding()
        .background(isWeekCompleted ? Color.green.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isWeekCompleted ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - WeekDayView
private struct WeekDayView: View {
    let date: Date
    let habit: Habit
    let habitColor: Color
    let onToggleCompletion: () -> Void
    
    @State private var isScheduled: Bool = false
    @State private var isCompleted: Bool = false
    @State private var canToggle: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(DateService.shared.dayLabel(for: date))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .fill(isCompleted ? habitColor : Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(isScheduled ? habitColor : Color.clear, lineWidth: isScheduled ? 2 : 0)
                    )
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                } else if canToggle {
                    Image(systemName: "circle")
                        .font(.caption.weight(.bold))
                        .foregroundColor(habitColor)
                }
            }
            .onTapGesture {
                guard canToggle else { return }
                withAnimation {
                    onToggleCompletion()
                    updateState()
                }
            }
        }
        .onAppear {
            updateState()
        }
        .onChange(of: habit.completions) { _, _ in
            updateState()
        }
        .onChange(of: habit.frequencyRaw) { _, _ in
            updateState()
        }
        .onChange(of: habit.weeklyDays) { _, _ in
            updateState()
        }
    }
    
    private func updateState() {
        let analysisService = HabitAnalysisService.shared
        isScheduled = analysisService.isScheduled(habit, on: date)
        isCompleted = analysisService.isCompleted(habit, on: date)
        canToggle = analysisService.canToggleCompletion(habit, on: date)
    }
}
