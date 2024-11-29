import Foundation

/// Represents a structured workout
public struct WorkoutTemplate: Codable {
    /// Name of the workout
    public let name: String
    
    /// Detailed description of the workout
    public let description: String?
    
    /// Optional warmup period
    public let warmup: WorkoutMeasure?
    
    /// Main segments
    public let segments: [WorkoutSegment]
    
    /// Optional cooldown period
    public let cooldown: WorkoutMeasure?
    
    /// Tags for categorization
    public let tags: [String]?
    
    public init(from data: Data, using decoder: DataDecoder, context: TrainingContext? = nil) async throws {
        self = try await .init(from: data, using: decoder, resolver: DefaultRemoteResolver(), context: context)
    }
    
    init(from data: Data, using decoder: DataDecoder, resolver: RemoteResolver, context: TrainingContext?) async throws {
        let userInfo: [CodingUserInfoKey: Any] = if let context {
            [.trainingContext: context]
        } else {
            [:]
        }
        let remoteDecoder = RemoteDecoder(decoder: decoder, userInfo: userInfo, resolver: resolver)
        let template: _WorkoutTemplate = try remoteDecoder.decode(data: data)
        try await template.resolve(using: remoteDecoder)
        self = .init(template)
    }
    
    init(_ template: _WorkoutTemplate) {
        self.name = template.name
        self.description = template.description
        self.segments = template.segments.map { .init($0) }
        self.warmup = template.warmup
        self.cooldown = template.cooldown
        self.tags = template.tags
    }
}

/// Internal implementation
struct _WorkoutTemplate: Codable, RemoteResolvable {
    /// Name of the workout
    let name: String
    
    /// Detailed description of the workout
    let description: String?
    
    /// Optional warmup period
    let warmup: WorkoutMeasure?
    
    /// Main segments
    let segments: [_WorkoutSegment]
    
    /// Optional cooldown period
    let cooldown: WorkoutMeasure?
    
    /// Tags for categorization
    let tags: [String]?
}
