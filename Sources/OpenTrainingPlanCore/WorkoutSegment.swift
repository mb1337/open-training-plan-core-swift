import Foundation

/// Represents a repeatable segment of a workout
public struct WorkoutSegment: Codable {
    /// The intensity level for this segment
    public let intensity: Intensity
    
    /// The work portion of the segment
    public let work: WorkoutMeasure
    
    /// The recovery portion of the segment (optional)
    public let recovery: WorkoutMeasure?
    
    /// Number of times to repeat this segment
    public let iterations: Int
    
    /// Optional label for this segment
    public let label: String?
    
    /// Creates a new workout segment
    /// - Parameters:
    ///   - intensity: Intensity level for the segment
    ///   - work: Work portion duration/distance
    ///   - recovery: Optional recovery portion
    ///   - label: Optional descriptive label
    ///   - iterations: Number of repetitions (default 1)
    public init(intensity: Intensity,
                work: WorkoutMeasure,
                recovery: WorkoutMeasure? = nil,
                label: String? = nil,
                iterations: Int = 1) {
        self.intensity = intensity
        self.work = work
        self.recovery = recovery
        self.iterations = iterations
        self.label = label
    }
    
    init(_ segment: _WorkoutSegment) {
        self.intensity = .init(segment.intensity)
        self.work = segment.work
        self.iterations = segment.iterations
        self.recovery = segment.recovery
        self.label = segment.label
    }
}

/// Internal implementation
struct _WorkoutSegment: Codable, RemoteResolvable {
    /// The intensity level for this segment
    let intensity: _Intensity
    
    /// The work portion of the segment
    let work: WorkoutMeasure
    
    /// The recovery portion of the segment (optional)
    let recovery: WorkoutMeasure?
    
    /// Number of times to repeat this segment
    let iterations: Int
    
    /// Optional label for this segment
    let label: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intensity = try container.decode(_Intensity.self, forKey: .intensity)
        work = try container.decode(WorkoutMeasure.self, forKey: .work)
        recovery = try container.decodeIfPresent(WorkoutMeasure.self, forKey: .recovery)
        iterations = try container.decodeIfPresent(Int.self, forKey: .iterations) ?? 1;
        label = try container.decodeIfPresent(String.self, forKey: .label)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(work, forKey: .work)
        try container.encodeIfPresent(recovery, forKey: .recovery)
        if (iterations > 1) {
            try container.encode(iterations, forKey: .iterations)
        }
        try container.encodeIfPresent(label, forKey: .label)
    }
    
    private enum CodingKeys: String, CodingKey {
        case intensity
        case work
        case recovery
        case iterations
        case label
    }
}
