//
//  CalendarMonthView.swift
//  Habitify
//
//  Created by Assistant on 16.09.2025.
//

import SwiftUI

struct CalendarMonthView: View {
    @Binding var selectedDates: Set<Date>
    @Binding var displayedMonth: Date
    var allowsMultipleSelection: Bool = true
    var isReadOnly: Bool = false
    
    private var monthDays: [Date] {
        DateService.shared.monthDays(for: displayedMonth)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(monthTitle(for: displayedMonth))
                    .font(.title3.weight(.semibold))
                Spacer()
                Button(action: { displayedMonth = offsetMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Button(action: { displayedMonth = offsetMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            
            // Weekday headers
            HStack {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                    Text(d).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity)
                }
            }
            
            // Grid of days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(monthGrid(), id: \.self) { date in
                    if let date = date {
                        let isSelected = selectedDates.contains(date)
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(height: 32)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Color.purple.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                guard !isReadOnly else { return }
                                let day = Calendar.current.startOfDay(for: date)
                                if allowsMultipleSelection {
                                    if selectedDates.contains(day) {
                                        selectedDates.remove(day)
                                    } else {
                                        selectedDates.insert(day)
                                    }
                                } else {
                                    selectedDates = [day]
                                }
                            }
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
    }
    
    private func monthTitle(for date: Date) -> String {
        DateService.shared.monthTitle(for: date)
    }
    
    private func offsetMonth(by value: Int) -> Date {
        DateService.shared.offsetMonth(displayedMonth, by: value)
    }
    
    private func monthGrid() -> [Date?] {
        DateService.shared.monthGrid(for: displayedMonth)
    }
}



