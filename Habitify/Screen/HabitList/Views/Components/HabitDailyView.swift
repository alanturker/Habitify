//
//  HabitDailyView.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI

struct HabitDailyView: View {
    let habit: Habit
    let selectedDate: Date
    let isCompleted: Bool
    let canToggle: Bool
    let streakText: String
    let habitColor: Color
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: habit.iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(habitColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Name
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !streakText.isEmpty {
                    Text(streakText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Done / Undone Button
            if canToggle {
                ZStack {
                    Circle()
                        .fill(isCompleted ? habitColor : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(habitColor, lineWidth: 2)
                        )
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "circle")
                            .font(.caption.weight(.bold))
                            .foregroundColor(habitColor)
                    }
                }
                .onTapGesture {
                    // Don't toggle local state, let parent handle it
                    onToggleCompletion()
                }
            }
        }
        .padding()
        .background(isCompleted ? Color.green.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}
