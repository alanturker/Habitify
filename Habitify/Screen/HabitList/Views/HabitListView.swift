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
        // Create a temporary service for initialization
        let tempService = HabitService(modelContext: ModelContext(try! ModelContainer(for: Habit.self, HabitCompletion.self)))
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
            viewModel.updateModelContext(modelContext)
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
                HStack(spacing: 12) {
                    ForEach(viewModel.headerDates, id: \.self) { date in
                        let isSelected = viewModel.isSameDay(viewModel.selectedDate, date)
                        let isToday = viewModel.isSameDay(date, Date())
                        VStack(spacing: 4) {
                            Text(viewModel.weekdayLabel(for: date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(viewModel.dayNumber(for: date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 44, height: 54)
                        .background(Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple, lineWidth: isSelected ? 3 : (isToday ? 1 : 0)))
                        .id(date.timeIntervalSince1970)
                        .onTapGesture { viewModel.selectDate(date) }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onAppear {
                let dates = viewModel.headerDates
                if let today = dates.first(where: { viewModel.isSameDay($0, Date()) }) {
                    proxy.scrollTo(today.timeIntervalSince1970, anchor: .center)
                }
            }
            .onChange(of: viewModel.scrollToToday) { _, shouldScroll in
                if shouldScroll {
                    let today = Date()
                    proxy.scrollTo(today.timeIntervalSince1970, anchor: .center)
                    // Reset the flag
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.scrollToToday = false
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    var listSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.selectedTab == .daily {
                    ForEach(viewModel.habitsForDaily(habits, on: viewModel.selectedDate)) { habit in
                        HabitDailyView(
                            habit: habit,
                            selectedDate: viewModel.selectedDate,
                            isCompleted: viewModel.isCompleted(habit, on: viewModel.selectedDate),
                            canToggle: viewModel.canToggleCompletion(habit, on: viewModel.selectedDate),
                            streakText: viewModel.streakText(for: habit),
                            habitColor: viewModel.color(for: habit),
                            onToggleCompletion: { viewModel.toggleCompletion(for: habit, on: viewModel.selectedDate) }
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
                            onToggleCompletion: { date in viewModel.toggleCompletion(for: habit, on: date) }
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
                            onToggleCompletion: { date in viewModel.toggleCompletion(for: habit, on: date) }
                        )
                        .onTapGesture { viewModel.selectHabit(habit) }
                    }
                }
                if habits.isEmpty {
                    emptyStateView
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
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






