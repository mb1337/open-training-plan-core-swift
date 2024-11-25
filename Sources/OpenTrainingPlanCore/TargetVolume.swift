/// Target volume for a workout defined as either a percentage of max weekly volume or absolute volume
public enum TargetVolume: Codable {
    case percentage(Double)
    case absolute(WorkoutMeasure)
    
    public init(from decoder: Decoder) throws {
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            if stringValue.hasSuffix("%") {
                let percentString = stringValue.dropLast() // Remove %
                if let percent = Double(percentString) {
                    self = .percentage(percent / 100.0) // Convert to decimal
                    return
                }
            }
        }
        
        self = .absolute(try .init(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .percentage(let percent):
            var container = encoder.singleValueContainer()
            try container.encode("\(percent * 100)%")
        case .absolute(let value):
            try value.encode(to: encoder)
        }
    }
}
