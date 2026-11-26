public extension Exercise {
    /// The lengths the Duration picker offers, shortest first: 1 to 30 whole minutes, the same for every Exercise,
    /// 4-7-8 included (#205, design point 6).
    var pickerDurations: [Duration] {
        (1 ... 30).map { .seconds($0 * 60) }
    }

    /// The picker value a sheet opens on: `defaultDuration` rounded to the nearest whole minute (4-7-8's 1:15
    /// opens on 1 min), at least one minute.
    var defaultPickerDuration: Duration {
        let minutes = (defaultDuration / .seconds(60)).rounded()
        return .seconds(max(Int(minutes), 1) * 60)
    }
}
