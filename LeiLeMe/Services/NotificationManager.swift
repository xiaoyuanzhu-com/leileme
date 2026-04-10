import Foundation
import UserNotifications

@Observable
class NotificationManager {
    // MARK: - Keys

    private enum Keys {
        static let remindersEnabled = "notification_reminders_enabled"
        static let reminderHour = "notification_reminder_hour"
        static let reminderMinute = "notification_reminder_minute"
        static let lastCopyIndex = "notification_last_copy_index"
        static let permissionRequested = "notification_permission_requested"
    }

    // MARK: - Notification copy (rotating)

    static let motivationalCopy: [(title: String, body: String)] = [
        ("How's your body today?", "A quick check-in helps you understand your recovery."),
        ("90 seconds to check your recovery", "Your daily assessment is waiting."),
        ("Your baseline gets smarter each day", "Keep the streak going with today's check-in."),
        ("Good morning! Time for a body check", "See how your recovery is trending."),
        ("Ready for today's check-in?", "Track your recovery in under 2 minutes."),
        ("Your body has a story today", "Open LeiLeMe to see how you're doing."),
        // Chinese-ready copies
        ("今天身体感觉怎么样？", "快速打卡，了解你的恢复状态。"),
        ("90秒，检查你的恢复状况", "今天的评估正在等你。"),
        ("每天打卡，基线越来越准", "保持连续打卡吧！"),
        ("早上好！该检查身体了", "看看你的恢复趋势如何。"),
    ]

    // MARK: - Published state

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var isAuthorized: Bool { authorizationStatus == .authorized }

    var remindersEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.remindersEnabled) }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.remindersEnabled)
            if newValue {
                scheduleNotifications()
            } else {
                cancelAllNotifications()
            }
        }
    }

    var reminderHour: Int {
        get {
            let h = UserDefaults.standard.integer(forKey: Keys.reminderHour)
            return h == 0 && !UserDefaults.standard.bool(forKey: Keys.remindersEnabled + "_hour_set") ? 7 : h
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.reminderHour)
            UserDefaults.standard.set(true, forKey: Keys.remindersEnabled + "_hour_set")
            if remindersEnabled { scheduleNotifications() }
        }
    }

    var reminderMinute: Int {
        get {
            let m = UserDefaults.standard.integer(forKey: Keys.reminderMinute)
            return m == 0 && !UserDefaults.standard.bool(forKey: Keys.remindersEnabled + "_minute_set") ? 30 : m
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.reminderMinute)
            UserDefaults.standard.set(true, forKey: Keys.remindersEnabled + "_minute_set")
            if remindersEnabled { scheduleNotifications() }
        }
    }

    /// Convenience computed property for binding to DatePicker
    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 7
            reminderMinute = components.minute ?? 30
        }
    }

    var hasRequestedPermission: Bool {
        UserDefaults.standard.bool(forKey: Keys.permissionRequested)
    }

    // MARK: - Identifier

    private let notificationIdentifierPrefix = "leileme_daily_reminder_"

    // MARK: - Init

    init() {
        // Set defaults on first launch
        if !UserDefaults.standard.bool(forKey: Keys.permissionRequested) {
            // Defaults will be set after permission is granted
        }
    }

    // MARK: - Authorization

    /// Request notification authorization. Returns whether permission was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            UserDefaults.standard.set(true, forKey: Keys.permissionRequested)
            await refreshAuthorizationStatus()
            if granted {
                // Enable reminders by default when permission is first granted
                if !UserDefaults.standard.bool(forKey: Keys.remindersEnabled + "_ever_set") {
                    UserDefaults.standard.set(true, forKey: Keys.remindersEnabled + "_ever_set")
                    UserDefaults.standard.set(true, forKey: Keys.remindersEnabled)
                    scheduleNotifications()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    /// Refresh the current authorization status from the system.
    func refreshAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedule rotating daily notifications. We schedule 7 days ahead with different copy.
    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()

        // Remove existing reminders first
        cancelAllNotifications()

        let copies = Self.motivationalCopy
        var copyIndex = UserDefaults.standard.integer(forKey: Keys.lastCopyIndex)

        // Schedule 7 notifications (one per day for the next week)
        for dayOffset in 0..<7 {
            let content = UNMutableNotificationContent()
            let copy = copies[copyIndex % copies.count]
            content.title = copy.title
            content.body = copy.body
            content.sound = .default
            // No custom userInfo needed — app opens to Home by default

            var dateComponents = DateComponents()
            dateComponents.hour = reminderHour
            dateComponents.minute = reminderMinute

            // For day 0, use a repeating trigger; for others, use specific dates
            if dayOffset == 0 {
                // Use a repeating calendar trigger for the daily time
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: "\(notificationIdentifierPrefix)repeating",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }

            copyIndex += 1
        }

        // Save the copy index for next rotation
        UserDefaults.standard.set(copyIndex, forKey: Keys.lastCopyIndex)
    }

    /// Cancel all scheduled reminder notifications.
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    /// Format the reminder time for display.
    var formattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminderTime)
    }
}
