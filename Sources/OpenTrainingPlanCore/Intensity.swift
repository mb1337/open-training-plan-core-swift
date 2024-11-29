import Foundation

public struct Intensity: Codable {
    public let value: Double
    public let metric: IntensityMetric
    public let zone: ZoneDefinition?
    
    init(_ intensity: _Intensity) {
        self.value = intensity.value
        self.metric = intensity.metric
        self.zone = intensity.zone
    }
}

/// Represents the intensity of a workout segment
final class _Intensity: Codable, RemoteResolvable {
    /// Direct intensity value and metric
    let value: Double
    let metric: IntensityMetric
    
    var zone: ZoneDefinition?
    
    let context: TrainingContext?
    
    /// Creates an intensity from a direct value
    init(value: Double, metric: IntensityMetric, zoneSystem: ZoneSystem? = nil) {
        self.value = value
        self.metric = metric
        self.zone = zoneSystem?.zone(intensity: value, metric: metric)
        self.context = nil
    }
    
    // MARK: - Codable Implementation
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let valueString = try container.decode(String.self)
        
        let scanner = Scanner(string: valueString)
        
        guard let number = scanner.scanDouble() else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid intensity format"
            )
        }
        
        self.value = number
        
        scanner.charactersToBeSkipped = .whitespaces
        guard let metricString = scanner.scanCharacters(from: .alphanumerics.union(.punctuationCharacters)) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid intensity format"
            )
        }
        
        switch metricString.lowercased() {
        case IntensityMetric.vo2max.rawValue:
            self.metric = .vo2max
        case IntensityMetric.hrMax.rawValue:
            self.metric = .hrMax
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid intensity metric format"
            )
        }
        self.context = decoder.userInfo[.trainingContext] as? TrainingContext
        self.zone = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(value) \(metric)")
    }
    
    func resolve(using resolver: RemoteDecoder) async throws {
        if let context = self.context {
            self.zone = context.zoneSystem?.zone(intensity: self.value, metric: self.metric)
        }
    }
}

/// Represents different ways of measuring workout intensity
public enum IntensityMetric: String, Codable, Sendable {
    /// Percentage of VO2max
    case vo2max = "vo2max"
    
    /// Percentage of maximum heart rate
    case hrMax = "hr_max"
    
    public var description: String {
        switch self {
        case .vo2max: return "VO2max"
        case .hrMax: return "Maximum Heart Rate"
        }
    }
}
