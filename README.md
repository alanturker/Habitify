# Habitify - Habit Tracking App

## Overview

Habitify is a modern habit tracking application built with SwiftUI and SwiftData. The app allows users to create, manage, and track daily, weekly, and monthly habits with an intuitive calendar-based interface. Users can mark habits as complete, view their streaks, and analyze their progress over time.

### How to Build/Run

#### Prerequisites
- macOS with Xcode 15.0 or later
- iOS 17.0 or later (for device testing)

#### Installation Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/alanturker/Habitify.git
   cd Habitify
   ```

2. **Open in Xcode:**
   - Open `Habitify.xcodeproj` in Xcode
   - Wait for Xcode to resolve dependencies

3. **Select target:**
   - Choose your target device (iPhone/iPad) or simulator
   - Ensure deployment target is iOS 17.0+

4. **Build and run:**
   - Press `⌘+R` or click the "Run" button
   - The app will launch on your selected device/simulator

#### Repository
🔗 **GitHub:** [https://github.com/alanturker/Habitify.git](https://github.com/alanturker/Habitify.git)

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** architectural pattern with the following structure:

- **Models**: SwiftData models (`Habit`, `HabitCompletion`, `WeeklyDay`, `MonthlyDay`)
- **Views**: SwiftUI views for UI components
- **ViewModels**: `@ObservableObject` classes that handle business logic and data binding
- **Services**: Separate service classes for data operations (`HabitService`, `HabitAnalysisService`, `DateService`)

The architecture ensures separation of concerns, making the code maintainable and testable. ViewModels act as intermediaries between Views and Models, handling all business logic while keeping Views focused on presentation.

## Use of AI Tools

### Which tools did you use?
- **Cursor** (with Claude AI integration)
- **Claude AI** for code generation and refactoring
- **Gemini** for researching habit tracker apps and default habit options

### What specific parts of the code did you generate with AI?
- **SwiftData Models**: Complete model structure with relationships and properties
- **CRUD Operations**: All database operations in `HabitService`
- **UI Components**: Most SwiftUI views and components
- **Business Logic**: Streak calculations, date utilities, and habit analysis
- **Architecture Setup**: Initial MVVM structure and service layer

### What parts did you write manually? Why?
- **MVVM Refactoring**: AI initially embedded logic directly in models, so I manually refactored to proper MVVM pattern
- **Bug Fixes**: Performance issues, UI state synchronization, and gesture timeout problems required manual debugging
- **Code Cleanup**: Removed duplicate code and optimized performance bottlenecks
- **UI State Management**: Complex state synchronization between views required manual intervention

### What were the limitations of the AI?
- **Architecture Patterns**: AI sometimes generated code that didn't follow MVVM principles properly
- **Performance Issues**: AI couldn't always identify and fix complex performance bottlenecks
- **UI State Synchronization**: Complex state management issues required manual debugging
- **Pixel-Perfect Design**: Without design files, AI couldn't create pixel-perfect implementations

## Challenges & Trade-offs

### Major Challenges
1. **MVVM Conversion**: The biggest challenge was converting AI-generated code to proper MVVM architecture. AI initially embedded business logic in models, requiring significant refactoring.

2. **Performance Optimization**: Encountered memory issues, hangs, and gesture timeouts that required extensive debugging and optimization.

3. **UI State Management**: Complex state synchronization between different views (Daily, Weekly, Monthly) required careful manual intervention.

### Trade-offs Made
- **Time vs. Perfection**: Focused on core functionality over pixel-perfect design
- **Simplicity vs. Features**: Prioritized essential features over advanced analytics
- **Performance vs. Features**: Optimized for smooth performance over complex animations

## Future Improvements

If given more time, I would add:

### Essential Features
- **Push Notifications**: Remind users to complete their habits
- **Onboarding Screen**: Guide new users through app setup
- **Splash Screen**: Professional app launch experience

### Enhanced User Experience
- **Filtering Options**: Filter habits by type, status, or date range
- **Widgets**: Home screen widgets for quick habit tracking
- **Customizable Themes**: Additional color themes and customization options
- **Animations**: More engaging micro-interactions and transitions

### Analytics & Insights
- **Progress Charts**: Visual representation of habit completion rates
- **Statistics Dashboard**: Detailed analytics and insights
- **Export Data**: Ability to export habit data

### Advanced Features
- **Habit Categories**: Organize habits into different categories
- **Streak Goals**: Set and track streak targets
- **Habit Sharing**: Share progress with friends or family
- **Backup & Sync**: Cloud backup and cross-device synchronization

---

*Built with ❤️ using SwiftUI, SwiftData, and AI assistance*
