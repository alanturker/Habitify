//
//  ContentView.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @StateObject private var viewModel: HabitListViewModel
    
    init() {
        // Create a temporary service for initialization - this will be updated in onAppear
        let tempContainer = try! ModelContainer(for: Habit.self, HabitCompletion.self, WeeklyDay.self, MonthlyDay.self)
        let tempService = HabitService(modelContext: ModelContext(tempContainer))
        _viewModel = StateObject(wrappedValue: HabitListViewModel(habitService: tempService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    tabBarSection
                    dateHeaderSection
                    calendarHeaderSection
                    listSection
                }
                
                // Floating Action Button
                floatingActionButton
            }
            .navigationTitle("Habitify")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $viewModel.showingAddHabit) {
            HabitFormView(habit: nil)
        }
        .sheet(item: $viewModel.selectedHabit) { habit in
            HabitFormView(habit: habit)
        }
        .onAppear {
            // Update the model context to use the environment context
            viewModel.updateModelContext(modelContext)
        }
        .task {
            // Ensure model context is updated when view appears
            viewModel.updateModelContext(modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            // Clear cache on memory warning
            HabitAnalysisService.shared.clearCache()
        }
    }
}

// MARK: - Sections
extension HabitListView {
    @ViewBuilder
    var tabBarSection: some View {
        HStack {
            ForEach(Frequency.allCases) { tab in
                Text(tab.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.selectedTab == tab ? .white : .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(viewModel.selectedTab == tab ? Color.purple : Color.gray.opacity(0.1)))
                    .onTapGesture { viewModel.selectTab(tab) }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    var dateHeaderSection: some View {
        let monthYear = viewModel.monthYearText(for: viewModel.selectedDate)
        
        HStack {
            Text(monthYear.month)
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(monthYear.year)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            Spacer()
            
            Button(action: {
                viewModel.scrollToCurrentDay()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                    Text("Today")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    var calendarHeaderSection: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.headerDates, id: \.timeIntervalSince1970) { date in
                        CalendarDateView(
                            date: date,
                            isSelected: viewModel.isSameDay(viewModel.selectedDate, date),
                            isToday: viewModel.isSameDay(date, Date()),
                            habitsForDate: viewModel.habitsForDate(habits, on: date),
                            onTap: { viewModel.selectDate(date) },
                            weekdayLabel: viewModel.weekdayLabel(for: date),
                            dayNumber: viewModel.dayNumber(for: date),
                            habitColor: { habit in viewModel.color(for: habit) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .frame(height: 70) // Fixed height to prevent excessive vertical space
            .onAppear {
                // Scroll to today on first load - use task instead of DispatchQueue
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    let today = Calendar.current.startOfDay(for: Date())
                    
                    // Find the exact date in headerDates
                    if let exactToday = viewModel.headerDates.first(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
                        let exactTodayId = "date-\(exactToday.timeIntervalSince1970)"
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                proxy.scrollTo(exactTodayId, anchor: .center)
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.scrollToToday) { _, shouldScroll in
                if shouldScroll {
                    let today = Calendar.current.startOfDay(for: Date())
                    
                    // Find the exact date in headerDates
                    if let exactToday = viewModel.headerDates.first(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
                        let exactTodayId = "date-\(exactToday.timeIntervalSince1970)"
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(exactTodayId, anchor: .center)
                        }
                    }
                    
                    // Reset the flag using Task
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        await MainActor.run {
                            viewModel.scrollToToday = false
                        }
                    }
                }
            }
        }
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    var listSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.selectedTab == .daily {
                    ForEach(viewModel.habitsForDaily(habits, on: viewModel.selectedDate)) { habit in
                        HabitDailyView(
                            habit: habit,
                            selectedDate: viewModel.selectedDate,
                            isCompleted: viewModel.isCompleted(habit, on: viewModel.selectedDate),
                            canToggle: viewModel.canToggleCompletion(habit, on: viewModel.selectedDate),
                            streakText: viewModel.streakText(for: habit),
                            habitColor: viewModel.color(for: habit),
                            onToggleCompletion: { 
                                // Clear cache first to ensure fresh calculation
                                HabitAnalysisService.shared.clearCache(for: habit)
                                // Immediate UI feedback without waiting for completion
                                viewModel.toggleCompletion(for: habit, on: viewModel.selectedDate)
                            }
                        )
                        .onTapGesture { viewModel.selectHabit(habit) }
                    }
                } else if viewModel.selectedTab == .weekly {
                    ForEach(viewModel.habitsForWeekly(habits, for: viewModel.selectedDate)) { habit in
                        HabitWeeklyView(
                            habit: habit,
                            selectedDate: viewModel.selectedDate,
                            weekDays: viewModel.weekDays,
                            isWeekCompleted: viewModel.isWeekFullyCompleted(habit, for: viewModel.selectedDate),
                            streakText: viewModel.streakText(for: habit),
                            habitColor: viewModel.color(for: habit),
                            onToggleCompletion: { date in 
                                viewModel.toggleCompletion(for: habit, on: date)
                            }
                        )
                        .onTapGesture { viewModel.selectHabit(habit) }
                    }
                } else {
                    ForEach(viewModel.habitsForMonthly(habits, for: viewModel.selectedDate)) { habit in
                        HabitMonthlyView(
                            habit: habit,
                            selectedDate: viewModel.selectedDate,
                            monthDays: viewModel.monthDays,
                            isMonthCompleted: viewModel.isMonthFullyCompleted(habit, for: viewModel.selectedDate),
                            habitColor: viewModel.color(for: habit),
                            onToggleCompletion: { date in 
                                viewModel.toggleCompletion(for: habit, on: date)
                            }
                        )
                        .onTapGesture { viewModel.selectHabit(habit) }
                    }
                }
                if habits.isEmpty {
                    emptyStateView
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }
    
    @ViewBuilder
    var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    viewModel.showAddHabit()
                }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    @ViewBuilder
    var emptyStateView: some View {
        ContentUnavailableView { 
            Label("No Habits Yet", systemImage: "star.slash") 
        } description: { 
            Text("Tap the + button to add your first habit") 
        }
        .padding(.top, 100)
    }
}






