
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
    
    public func zone(intensity: Double, metric: IntensityMetric) -> ZoneDefinition? {
        for zone in allZones where zone.metric == metric {
            if zone.targetIntensity == intensity {
                return zone
            }
        }
        
        return nil
    }
    
    /// All zones in the system
    public var allZones: [ZoneDefinition] {
        Array(zones.values).sorted { $0.targetIntensity < $1.targetIntensity }
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


/// Zone-related errors
public enum ZoneError: Error {
    case zoneNotFound(String)
    case invalidZoneSystem
}
