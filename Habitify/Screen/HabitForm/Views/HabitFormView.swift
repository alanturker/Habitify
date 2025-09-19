//
//  HabitFormView.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: HabitFormViewModel
    private let habit: Habit?
    
    init(habit: Habit?) {
        self.habit = habit
        // Initialize with a temporary service - this will be updated in onAppear
        let tempContainer = try! ModelContainer(for: Habit.self, HabitCompletion.self, WeeklyDay.self, MonthlyDay.self)
        let tempService = HabitService(modelContext: ModelContext(tempContainer))
        self._viewModel = StateObject(wrappedValue: HabitFormViewModel(habit: habit, habitService: tempService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        iconSection
                        nameSection
                        colorSection
                        frequencySection
                        weeklySection
                        monthlySection
                        deletePinnedSection
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Habit" : "Create New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveHabit()
                        if !viewModel.showingScheduleChangeAlert {
                            dismiss()
                        }
                    }
                    .disabled(viewModel.habitName.isEmpty)
                }
            }
            .alert("Delete Habit?", isPresented: $viewModel.showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    // Perform delete on background thread to prevent hang
                    Task.detached(priority: .high) {
                        await viewModel.deleteHabit()
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete this habit and all its data.")
            }
            .alert("Schedule Changed", isPresented: $viewModel.showingScheduleChangeAlert) {
                Button("Save & Clean", role: .destructive) {
                    // Perform save on background thread to prevent hang
                    Task.detached(priority: .high) {
                        await viewModel.confirmScheduleChange()
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You've changed the schedule. Previous completions on unscheduled days will be removed. Do you want to continue?")
            }
        }
        .onAppear {
            // Update the service with the actual model context
            viewModel.updateModelContext(modelContext)
        }
        .task {
            // Ensure model context is properly initialized
            viewModel.updateModelContext(modelContext)
        }
    }
    
    // MARK: - Sections
    @ViewBuilder
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequency")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 8) {
                ForEach(Frequency.allCases) { frequency in
                    frequencyButton(for: frequency)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func frequencyButton(for frequency: Frequency) -> some View {
        Text(frequency.title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(viewModel.frequency == frequency ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(
                    viewModel.frequency == frequency ? Color.purple : Color.gray.opacity(0.1)
                )
            )
            .onTapGesture {
                viewModel.selectFrequency(frequency)
                hideKeyboard()
            }
    }
    
    @ViewBuilder
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DefaultHabit.defaults, id: \.name) { defaultHabit in
                        Button(action: {
                            viewModel.selectDefaultHabit(defaultHabit)
                            hideKeyboard()
                        }) {
                            VStack(spacing: 10) {
                                Image(systemName: defaultHabit.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        viewModel.selectedIcon == defaultHabit.icon
                                        ? (Color(hex: viewModel.selectedColor) ?? .gray)
                                        : Color.gray.opacity(0.5)
                                    )
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.purple, lineWidth: viewModel.selectedIcon == defaultHabit.icon ? 3 : 0))
                                    .overlay(
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.purple)
                                            .background(Color.white.clipShape(Circle()))
                                            .offset(x: 18, y: 18)
                                            .opacity(viewModel.selectedIcon == defaultHabit.icon ? 1 : 0)
                                    )
                                Text(defaultHabit.name)
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .frame(width: 60, height: 30)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
        }
    }
    
    @ViewBuilder
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit Name")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            TextField("Habit Name", text: $viewModel.habitName)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 7), spacing: 15) {
                ForEach(ColorPalette.allCases) { palette in
                    Circle()
                        .fill(palette.color)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color.purple, lineWidth: viewModel.selectedColor == palette.rawValue ? 3 : 0))
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                                .background(Color.white.clipShape(Circle()))
                                .offset(x: 18, y: 18)
                                .opacity(viewModel.selectedColor == palette.rawValue ? 1 : 0)
                        )
                        .onTapGesture { 
                            viewModel.selectedColor = palette.rawValue
                            hideKeyboard() 
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var weeklySection: some View {
        if viewModel.originalFrequency == .weekly {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Days of Week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        Text(day.short)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.selectedWeekdays.contains(day) ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(viewModel.selectedWeekdays.contains(day) ? Color.purple : Color.gray.opacity(0.1)))
                            .onTapGesture {
                                viewModel.toggleWeekday(day)
                                hideKeyboard()
                            }
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private var monthlySection: some View {
        if viewModel.originalFrequency == .monthly {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Days of Month")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                CalendarMonthView(selectedDates: $viewModel.monthlySelectedDates, displayedMonth: $viewModel.displayedMonth, allowsMultipleSelection: true, isReadOnly: false)
                    .padding(.horizontal)
                    .onChange(of: viewModel.monthlySelectedDates) { _, newValue in
                        viewModel.handleMonthlySelectionChange(newValue)
                        hideKeyboard()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var deletePinnedSection: some View {
        if viewModel.isEditMode {
            Button(action: { 
                // Immediate response to prevent hang
                viewModel.showingDeleteAlert = true 
            }) {
                Text("Delete Habit")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

}
