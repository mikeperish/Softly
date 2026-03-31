// FocusTimer.swift
// Fidget App — Pomodoro Timer Engine
// Background-safe, timestamp-based

import SwiftUI
import Combine
import AVFoundation
import UserNotifications

// MARK: - Timer Phase

enum FocusPhase: String {
    case focus = "Focus"
    case shortBreak = "Break"
    case longBreak = "Long Break"

    var isFocus: Bool { self == .focus }
    var isBreak: Bool { !isFocus }
}

// MARK: - Focus Mode Presets

enum FocusPreset: String, CaseIterable, Identifiable {
    case standard = "25 min"
    case adhd = "15 min"

    var id: String { rawValue }

    var defaultWork: Int {
        switch self {
        case .standard: return 25
        case .adhd: return 15
        }
    }

    var defaultBreak: Int { 5 }
    var defaultLongBreak: Int { 15 }
}

// MARK: - FocusTimer

final class FocusTimer: ObservableObject {

    // MARK: Published State

    @Published var phase: FocusPhase = .focus
    @Published var isRunning = false
    @Published var remainingSeconds: Int
    @Published var totalSeconds: Int
    @Published var preset: FocusPreset = .standard

    @Published var workMinutes: Int
    @Published var breakMinutes: Int
    @Published var longBreakMinutes: Int = 15
    @Published var autoStartNext: Bool = true

    @Published var soundEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true

    // MARK: Session Tracking (exposed for FocusStore)

    @Published private(set) var focusSessionsInCycle: Int = 0
    private let sessionsBeforeLongBreak = 4

    // MARK: Callbacks

    var onPhaseComplete: ((_ phase: FocusPhase, _ wasSkipped: Bool) -> Void)?

    // MARK: Private — Timestamp Engine

    private var phaseStartDate: Date?
    private var elapsedBeforePause: TimeInterval = 0
    private var tickCancellable: AnyCancellable?
    private var backgroundDate: Date?

    // MARK: Init

    init() {
        let preset = FocusPreset.standard
        let work = preset.defaultWork
        let brk = preset.defaultBreak
        self.workMinutes = work
        self.breakMinutes = brk
        self.remainingSeconds = work * 60
        self.totalSeconds = work * 60

        setupBackgroundObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    func start() {
        guard !isRunning else { return }
        isRunning = true
        phaseStartDate = Date()
        startTicking()
        schedulePhaseNotification()
    }

    func pause() {
        guard isRunning else { return }
        if let start = phaseStartDate {
            elapsedBeforePause += Date().timeIntervalSince(start)
        }
        phaseStartDate = nil
        isRunning = false
        tickCancellable?.cancel()
        tickCancellable = nil
        cancelNotification()
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func reset() {
        pause()
        phase = .focus
        focusSessionsInCycle = 0
        elapsedBeforePause = 0
        let dur = workMinutes * 60
        remainingSeconds = dur
        totalSeconds = dur
        cancelNotification()
    }

    func skip() {
        pause()
        onPhaseComplete?(phase, true)
        advancePhase(wasCompleted: false)

        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func applyPreset(_ newPreset: FocusPreset) {
        preset = newPreset
        workMinutes = newPreset.defaultWork
        breakMinutes = newPreset.defaultBreak
        longBreakMinutes = newPreset.defaultLongBreak
        reset()
    }

    // MARK: - Computed

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var phaseLabel: String {
        phase.rawValue
    }

    // MARK: - Duration Helpers

    private var currentPhaseDuration: Int {
        switch phase {
        case .focus:      return workMinutes * 60
        case .shortBreak: return breakMinutes * 60
        case .longBreak:  return longBreakMinutes * 60
        }
    }

    // MARK: - Tick Engine (Timestamp-Based)

    private func startTicking() {
        tickCancellable?.cancel()
        tickCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning, let start = phaseStartDate else { return }

        let totalElapsed = elapsedBeforePause + Date().timeIntervalSince(start)
        let dur = Double(totalSeconds)
        let remaining = max(0, dur - totalElapsed)

        remainingSeconds = Int(ceil(remaining))

        if remaining <= 0 {
            phaseDidFinish()
        }
    }

    // MARK: - Phase Completion

    private func phaseDidFinish() {
        pause()

        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        if soundEnabled {
            AudioServicesPlaySystemSound(1007)
        }

        if phase == .focus {
            focusSessionsInCycle += 1
        }

        onPhaseComplete?(phase, false)

        advancePhase(wasCompleted: true)

        if autoStartNext {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.start()
            }
        }
    }

    private func advancePhase(wasCompleted: Bool) {
        elapsedBeforePause = 0

        if phase.isFocus {
            if focusSessionsInCycle >= sessionsBeforeLongBreak {
                phase = .longBreak
                focusSessionsInCycle = 0
            } else {
                phase = .shortBreak
            }
        } else {
            phase = .focus
        }

        let dur = currentPhaseDuration
        totalSeconds = dur
        remainingSeconds = dur
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func schedulePhaseNotification() {
        guard soundEnabled else {
            cancelNotification()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = phase.isFocus ? "Focus complete!" : "Break's over!"
        content.body = phase.isFocus ? "Time for a break." : "Ready to focus?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, Double(remainingSeconds)),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "focusPhase",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["focusPhase"]
        )
    }

    // MARK: - Background Handling

    private func setupBackgroundObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        backgroundDate = Date()
    }

    @objc private func appWillEnterForeground() {
        guard isRunning else { return }
        tick()
    }

    // MARK: - Work/Break Minutes Changed

    func updateWorkMinutes(_ value: Int) {
        workMinutes = value
        if phase == .focus && !isRunning {
            let dur = value * 60
            remainingSeconds = dur
            totalSeconds = dur
            elapsedBeforePause = 0
        }
    }

    func updateBreakMinutes(_ value: Int) {
        breakMinutes = value
        if phase == .shortBreak && !isRunning {
            let dur = value * 60
            remainingSeconds = dur
            totalSeconds = dur
            elapsedBeforePause = 0
        }
    }
}
