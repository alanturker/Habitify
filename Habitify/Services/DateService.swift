//
//  DateService.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import Foundation

final class DateService {
    static let shared = DateService()
    private let calendar = Calendar.current
    
    private init() {}
    
    func lifetimeDates() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .year, value: -2, to: today) ?? today
        let endDate = calendar.date(byAdding: .year, value: 2, to: today) ?? today
        
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    func weekDays(for date: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let startOfSelected = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfSelected)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfSelected) ?? startOfSelected
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monday)
        }
    }
    
    func monthDays(for date: Date) -> [Date] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        return range.compactMap { day -> Date? in
            var comps = calendar.dateComponents([.year, .month], from: startOfMonth)
            comps.day = day
            return calendar.date(from: comps)
        }
    }
    
    func monthGrid(for date: Date) -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        guard let firstDay = calendar.date(from: DateComponents(year: calendar.component(.year, from: startOfMonth), month: calendar.component(.month, from: startOfMonth), day: 1)) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekday + 6) % 7 // make Sunday index 0
        var grid: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            var comps = calendar.dateComponents([.year, .month], from: startOfMonth)
            comps.day = day
            if let d = calendar.date(from: comps) {
                grid.append(calendar.startOfDay(for: d))
            }
        }
        return grid
    }
    
    // MARK: - Date Comparisons
    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
    
    func isPastOrToday(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        return targetDate <= today
    }
    
    // MARK: - Date Formatting
    func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return String(formatter.string(from: date).prefix(2))
    }
    
    func dayNumber(for date: Date) -> String {
        String(calendar.component(.day, from: date))
    }
    
    func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }
    
    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL, yyyy"
        return formatter.string(from: date)
    }
    
    func offsetMonth(_ date: Date, by value: Int) -> Date {
        calendar.date(byAdding: .month, value: value, to: date) ?? date
    }
}
