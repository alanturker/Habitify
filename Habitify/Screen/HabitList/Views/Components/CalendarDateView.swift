//
//  CalendarDateView.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI

struct CalendarDateView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let habitsForDate: [Habit]
    let onTap: () -> Void
    let weekdayLabel: String
    let dayNumber: String
    let habitColor: (Habit) -> Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(weekdayLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(dayNumber)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            
            // Habit color dots
            if !habitsForDate.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(habitsForDate.prefix(3)), id: \.id) { habit in
                        Circle()
                            .fill(habitColor(habit))
                            .frame(width: 4, height: 4)
                    }
                    if habitsForDate.count > 3 {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 4, height: 4)
                    }
                }
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 40, height: 50) // Reduced size for better fit
        .background(Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple, lineWidth: isSelected ? 2 : (isToday ? 1 : 0)))
        .id("date-\(date.timeIntervalSince1970)")
        .onTapGesture { onTap() }
    }
}
