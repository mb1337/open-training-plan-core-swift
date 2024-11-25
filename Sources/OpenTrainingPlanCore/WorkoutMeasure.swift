import Foundation

/// Represents a duration or distance in a workout
public enum WorkoutMeasure: Codable {
    /// Time duration in seconds, if specified
    case time(TimeInterval)
    
    /// Distance measurement, if specified
    case distance(Measurement<UnitLength>)
    
    public var timeValue: TimeInterval? {
        switch self {
        case .time(let value): return value
        case .distance: return nil
        }
    }
    
    public var distanceValue: Measurement<UnitLength>? {
        switch self {
        case .distance(let value): return value
        case .time: return nil
        }
    }
    
    // MARK: - Codable Implementation
    
    public init(from decoder: Decoder) throws {
        // Try to decode as a single string
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            // Try parsing as time first
            if let time = WorkoutMeasure.parseTimeString(stringValue) {
                self = .time(time)
                return
            }
            // Then try as distance
            if let distance = WorkoutMeasure.parseDistanceString(stringValue) {
                self = .distance(distance)
                return
            }
        }
        
        throw DecodingError.dataCorruptedError(
            in: try decoder.singleValueContainer(),
            debugDescription: "Invalid measure format"
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .time(let time):
            try container.encode(WorkoutMeasure.formatTime(time))
        case .distance(let distance):
            try container.encode(WorkoutMeasure.formatDistance(distance))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Parses a time string in format "MM:SS" or "HH:MM:SS"
    private static func parseTimeString(_ string: String) -> TimeInterval? {
        let components = string.split(separator: ":").compactMap { Double($0) }
        if components.count == 2 {
            return components[0] * 60 + components[1]
        }
        if components.count == 3 {
            return components[0] * 3600 + components[1] * 60 + components[2]
        }
        return nil
    }
    
    /// Formats a time interval as "MM:SS" or "HH:MM:SS"
    private static func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Parses a distance string like "5 km" or "400 m"
    private static func parseDistanceString(_ string: String) -> Measurement<UnitLength>? {
        let scanner = Scanner(string: string)
        
        guard let number = scanner.scanDouble() else { return nil }
        
        scanner.charactersToBeSkipped = .whitespaces
        guard let unitString = scanner.scanCharacters(from: .letters) else { return nil }
        
        let unit: UnitLength
        switch unitString.lowercased() {
        case "km", "kilometers":
            unit = .kilometers
        case "m", "meters":
            unit = .meters
        case "mi", "miles":
            unit = .miles
        default:
            return nil
        }
        
        return Measurement(value: number, unit: unit)
    }
    
    /// Formats a distance measurement as a string
    private static func formatDistance(_ distance: Measurement<UnitLength>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter.string(from: distance)
    }
}
