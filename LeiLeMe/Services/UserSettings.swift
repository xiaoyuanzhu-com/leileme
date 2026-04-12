import Foundation

/// Which hand a grip strength reading was taken with, or the user's dominant hand.
enum Hand: String {
    case left
    case right
}

/// Lightweight wrapper around `UserDefaults` for user-adjustable settings that
/// need to be read from non-UI code (e.g. the `Measure` aggregation extension).
///
/// Kept as an enum with static properties rather than an instance singleton so
/// call sites don't need dependency injection — tests override by writing to
/// `UserDefaults.standard` directly.
enum UserSettings {

    private static let dominantHandKey = "dominantHand"

    static var dominantHand: Hand {
        get {
            guard let raw = UserDefaults.standard.string(forKey: dominantHandKey),
                  let hand = Hand(rawValue: raw) else {
                return .right
            }
            return hand
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: dominantHandKey)
        }
    }
}
