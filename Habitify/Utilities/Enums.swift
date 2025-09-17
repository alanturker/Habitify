//
//  Enums.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import Foundation
import SwiftUI

enum ColorPalette: String, CaseIterable, Identifiable {
    case peach = "#FFE5B4"
    case sandyBrown = "#F4A460"
    case tan = "#D2B48C"
    case plum = "#DDA0DD"
    case lightPink = "#FFB6C1"
    case skyBlue = "#87CEEB"
    case mint = "#98D8C8"
    case khaki = "#F0E68C"
    case lightSalmon = "#FFA07A"
    case coralRed = "#FF6B6B"
    case purple = "#9B59B6"
    case blue = "#3498DB"
    case turquoise = "#1ABC9C"
    case orange = "#F39C12"
    case red = "#E74C3C"
    
    var id: String { rawValue }
    
    var color: Color {
        Color(hex: rawValue) ?? .gray
    }
}

enum Frequency: Int, CaseIterable, Identifiable {
    case daily = 0
    case weekly = 1
    case monthly = 2
    
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    var id: Int { rawValue }
    var short: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

// Default Habits
struct DefaultHabit {
    let name: String
    let icon: String
    
    static let defaults = [
        DefaultHabit(name: "Set Small Goals", icon: "target"),
        DefaultHabit(name: "Work", icon: "briefcase.fill"),
        DefaultHabit(name: "Meditation", icon: "leaf.fill"),
        DefaultHabit(name: "Basketball", icon: "basketball.fill"),
        DefaultHabit(name: "Sleep Over 8h", icon: "moon.fill"),
        DefaultHabit(name: "Playing Games", icon: "gamecontroller.fill"),
        DefaultHabit(name: "Exercise or Workout", icon: "figure.run"),
        DefaultHabit(name: "Drink Water", icon: "drop.fill"),
        DefaultHabit(name: "Read a Book", icon: "book.fill"),
        DefaultHabit(name: "Healthy Eating", icon: "leaf.circle.fill"),
        DefaultHabit(name: "Study", icon: "graduationcap.fill"),
        DefaultHabit(name: "Journal", icon: "pencil.and.outline")
    ]
}
