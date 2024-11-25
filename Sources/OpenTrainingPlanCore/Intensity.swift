import Foundation

/// Represents the intensity of a workout segment
public struct Intensity: Codable, RemoteResolvable {
    /// Direct intensity value and metric
    public private(set) var value: Double?
    public private(set) var metric: IntensityMetric?
    
    /// Zone Reference
    @RemoteResource public var zoneSystem: ZoneSystem?
    public let zoneCode: String?
    
    /// Creates an intensity from a zone reference
    public init(zoneSystem: ZoneSystem, zoneCode: String) throws {
        let zone = try zoneSystem.zone(forCode: zoneCode)
        self._zoneSystem = .init(zoneSystem)
        self.zoneCode = zoneCode
        self.value = zone.targetIntensity
        self.metric = zone.metric
    }
    
    /// Creates an intensity from a direct value
    public init(value: Double, metric: IntensityMetric) {
        self._zoneSystem = .init()
        self.zoneCode = nil
        self.value = value
        self.metric = metric
    }
    
    // MARK: - Codable Implementation
    
    public init(from decoder: Decoder) throws {
        // Handle structured format
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(Double.self, forKey: .value) {
            self.value = value
            if let metric = try container.decodeIfPresent(IntensityMetric.self, forKey: .metric)  {
                self.metric = metric
            } else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "Invalid intensity format"
                )
            }
            self._zoneSystem = .init(nil)
            self.zoneCode = nil
        } else {
            self.zoneCode = try container.decode(String.self, forKey: .zoneCode)
            self._zoneSystem = try container.decode(RemoteResource<ZoneSystem>.self, forKey: .zoneSystem)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if zoneCode != nil {
            try container.encode(zoneCode, forKey: .zoneCode)
            try container.encode(_zoneSystem, forKey: .zoneSystem)
        } else {
            try container.encode(value, forKey: .value)
            try container.encode(metric, forKey: .metric)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case zoneSystem
        case zoneCode
        case value
        case metric
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

/// Represents a training zone definition
public struct ZoneDefinition: Codable, Equatable, Sendable {
    /// Short code for the zone (e.g., "E", "T")
    public let code: String
    
    /// Full name of the zone
    public let name: String
    
    /// Description of the zone
    public let description: String
    
    /// Metric by which zone is defined
    public let metric: IntensityMetric
    
    /// Target intensity as percentage
    public let targetIntensity: Double
    
    /// Optional intensity range
    public let intensityRange: ClosedRange<Double>?
}

/// Represents a complete zone system
public struct ZoneSystem: Codable, Sendable {
    /// Name of the zone system
    public let name: String
    
    /// Description of the zone system
    public let description: String?
    
    /// Zone definitions, indexed by code
    private let zones: [String: ZoneDefinition]
    
    /// Creates a new zone system
    public init(
        name: String,
        description: String? = nil,
        zones: [ZoneDefinition]
    ) {
        self.name = name
        self.description = description
        self.zones = Dictionary(uniqueKeysWithValues: zones.map { ($0.code, $0) })
    }
    
    /// Gets a zone definition by code
    public func zone(forCode code: String) throws -> ZoneDefinition {
        guard let zone = zones[code] else {
            throw ZoneError.zoneNotFound(code)
        }
        
        return zone
    }
    
    /// All zones in the system
    public var allZones: [ZoneDefinition] {
        Array(zones.values).sorted { $0.targetIntensity < $1.targetIntensity }
    }
}

/// Zone-related errors
public enum ZoneError: Error {
    case zoneNotFound(String)
    case invalidZoneSystem
}
