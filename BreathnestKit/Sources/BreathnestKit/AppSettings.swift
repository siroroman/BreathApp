/// One of the five sounds of the Sounds menu. The IDs are stored, so they never change; the names and the audio
/// are placeholders until #49.
public enum SoundID: String, CaseIterable, Sendable {
    case softBell = "soft-bell"
    case singingBowl = "singing-bowl"
    case chime
    case woodBlock = "wood-block"
    case pulse
}

/// The settings the iPhone keeps between launches: Sound on or off, the chosen sound and Haptics on or off.
/// Saved in `UserDefaults` under `breathnest.settings` (ADR 0003). The Watch uses the same type.
public struct AppSettings: StoredDocument {
    public var isSoundOn: Bool
    public var soundID: SoundID
    public var isHapticsOn: Bool

    public init(isSoundOn: Bool, soundID: SoundID, isHapticsOn: Bool) {
        self.isSoundOn = isSoundOn
        self.soundID = soundID
        self.isHapticsOn = isHapticsOn
    }

    public static let defaultValue = AppSettings(isSoundOn: true, soundID: .softBell, isHapticsOn: true)
    public static let currentVersion = 1

    private enum CodingKeys: String, CodingKey {
        case version, isSoundOn, soundID, isHapticsOn
    }

    /// A missing, mistyped or unknown field takes its own default (rule F4).
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaultValue
        isSoundOn = (try? container.decode(Bool.self, forKey: .isSoundOn)) ?? defaults.isSoundOn
        soundID = (try? container.decode(String.self, forKey: .soundID)).flatMap(SoundID.init) ?? defaults.soundID
        isHapticsOn = (try? container.decode(Bool.self, forKey: .isHapticsOn)) ?? defaults.isHapticsOn
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentVersion, forKey: .version)
        try container.encode(isSoundOn, forKey: .isSoundOn)
        try container.encode(soundID.rawValue, forKey: .soundID)
        try container.encode(isHapticsOn, forKey: .isHapticsOn)
    }
}
