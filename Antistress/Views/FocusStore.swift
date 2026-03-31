// FocusStore.swift
// Fidget App — Session Tracking & Streaks
// UserDefaults persistence

import SwiftUI
import Combine

// MARK: - FocusStore

final class FocusStore: ObservableObject {

    // MARK: Published

    @Published var sessionsToday: Int = 0
    @Published var totalSessions: Int = 0
    @Published var focusMinutesToday: Int = 0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0

    // MARK: Private

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sessionsToday = "focus_sessionsToday"
        static let totalSessions = "focus_totalSessions"
        static let focusMinutesToday = "focus_minutesToday"
        static let currentStreak = "focus_currentStreak"
        static let bestStreak = "focus_bestStreak"
        static let lastSessionDate = "focus_lastSessionDate"
        static let lastDayChecked = "focus_lastDayChecked"
    }

    // MARK: Init

    init() {
        load()
        checkNewDay()
    }

    // MARK: - Public API

    /// Call when a focus phase completes (not skipped)
    func recordCompletedFocus(durationMinutes: Int) {
        sessionsToday += 1
        totalSessions += 1
        focusMinutesToday += durationMinutes

        // Update streak
        let today = Self.dayString(from: Date())
        let lastDate = defaults.string(forKey: Keys.lastSessionDate) ?? ""

        if lastDate != today {
            // First session today
            let yesterday = Self.dayString(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)

            if lastDate == yesterday {
                // Consecutive day
                currentStreak += 1
            } else if lastDate.isEmpty {
                // First ever session
                currentStreak = 1
            } else {
                // Streak broken
                currentStreak = 1
            }

            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        }

        defaults.set(today, forKey: Keys.lastSessionDate)
        save()
    }

    // MARK: - Day Reset

    private func checkNewDay() {
        let today = Self.dayString(from: Date())
        let lastDay = defaults.string(forKey: Keys.lastDayChecked) ?? ""

        if lastDay != today {
            // New day — reset daily counters
            sessionsToday = 0
            focusMinutesToday = 0
            defaults.set(today, forKey: Keys.lastDayChecked)

            // Check if streak is broken
            let lastSessionDate = defaults.string(forKey: Keys.lastSessionDate) ?? ""
            let yesterday = Self.dayString(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)

            if !lastSessionDate.isEmpty && lastSessionDate != yesterday && lastSessionDate != today {
                // More than 1 day gap — streak broken
                currentStreak = 0
            }

            save()
        }
    }

    // MARK: - Persistence

    private func load() {
        sessionsToday = defaults.integer(forKey: Keys.sessionsToday)
        totalSessions = defaults.integer(forKey: Keys.totalSessions)
        focusMinutesToday = defaults.integer(forKey: Keys.focusMinutesToday)
        currentStreak = defaults.integer(forKey: Keys.currentStreak)
        bestStreak = defaults.integer(forKey: Keys.bestStreak)
    }

    private func save() {
        defaults.set(sessionsToday, forKey: Keys.sessionsToday)
        defaults.set(totalSessions, forKey: Keys.totalSessions)
        defaults.set(focusMinutesToday, forKey: Keys.focusMinutesToday)
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(bestStreak, forKey: Keys.bestStreak)
    }

    // MARK: - Helpers

    private static func dayString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
