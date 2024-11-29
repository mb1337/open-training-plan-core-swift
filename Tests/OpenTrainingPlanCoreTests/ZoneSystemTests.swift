import XCTest
@testable import OpenTrainingPlanCore

struct TestZoneSystems {
    static let danielsSystem = ZoneSystem(
        name: "Daniels",
        description: "Daniels Running Formula Training Zones",
        zones: [
            ZoneDefinition(
                code: "E",
                name: "Easy",
                description: "Easy/Recovery pace",
                metric: .vo2max,
                targetIntensity: 0.65,
                intensityRange: 0.59...0.74
            ),
            ZoneDefinition(
                code: "M",
                name: "Marathon",
                description: "Marathon training pace",
                metric: .vo2max,
                targetIntensity: 0.75,
                intensityRange: 0.75...0.84
            ),
            ZoneDefinition(
                code: "T",
                name: "Threshold",
                description: "Lactate threshold training",
                metric: .vo2max,
                targetIntensity: 0.88,
                intensityRange: 0.85...0.91
            ),
            ZoneDefinition(
                code: "I",
                name: "Interval",
                description: "VO2max intervals",
                metric: .vo2max,
                targetIntensity: 0.95,
                intensityRange: 0.92...0.97
            ),
            ZoneDefinition(
                code: "R",
                name: "Repetition",
                description: "Speed work",
                metric: .vo2max,
                targetIntensity: 1.0,
                intensityRange: 0.98...1.0
            )
        ]
    )
    
    static let hrSystem = ZoneSystem(
        name: "Heart Rate Zones",
        description: "5-Zone Heart Rate Training System",
        zones: [
            ZoneDefinition(
                code: "Z1",
                name: "Recovery",
                description: "Very light intensity",
                metric: .hrMax,
                targetIntensity: 0.60,
                intensityRange: 0.50...0.60
            ),
            ZoneDefinition(
                code: "Z2",
                name: "Aerobic",
                description: "Light aerobic",
                metric: .hrMax,
                targetIntensity: 0.70,
                intensityRange: 0.60...0.70
            ),
            ZoneDefinition(
                code: "Z3",
                name: "Tempo",
                description: "Moderate intensity",
                metric: .hrMax,
                targetIntensity: 0.80,
                intensityRange: 0.70...0.80
            ),
            ZoneDefinition(
                code: "Z4",
                name: "Threshold",
                description: "Hard intensity",
                metric: .hrMax,
                targetIntensity: 0.90,
                intensityRange: 0.80...0.90
            ),
            ZoneDefinition(
                code: "Z5",
                name: "Maximum",
                description: "Maximum effort",
                metric: .hrMax,
                targetIntensity: 0.95,
                intensityRange: 0.90...1.0
            )
        ]
    )
}

final class ZoneSystemTests: XCTestCase {
    
    
    func testZoneSystemBasics() throws {
        // Test zone lookup
        let easyZone = try TestZoneSystems.danielsSystem.zone(forCode: "E")
        XCTAssertEqual(easyZone.name, "Easy")
        XCTAssertEqual(easyZone.targetIntensity, 0.65)
        XCTAssertEqual(easyZone.metric, .vo2max)
        
        // Test all zones are sorted by intensity
        let allZones = TestZoneSystems.danielsSystem.allZones
        XCTAssertEqual(allZones.count, 5)
        XCTAssertEqual(allZones.map(\.code), ["E", "M", "T", "I", "R"])
        XCTAssertTrue(allZones.map(\.targetIntensity).isSorted())
    }
    
    func testRemoteZoneSystem() async throws {
        let json = """
        {
            "name": "Workout with Zones",
            "description": "Test workout",
            "segments": [
                {
                    "intensity": "0.80 vo2max",
                    "work": "5:00"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let workout = try JSONDecoder().decode(_WorkoutTemplate.self, from: json)
        XCTAssertEqual(workout.segments.first?.intensity.value, 0.80)
    }
    
    func testZoneSystemJSON() throws {
        let json = """
        {
            "name": "Simple Zones",
            "description": "Basic zone system",
            "zones": {
                "E": {
                    "code": "E",
                    "name": "Easy",
                    "description": "Easy pace",
                    "metric": "vo2max",
                    "targetIntensity": 0.65,
                    "intensityRange": [
                        0.60,
                        0.70
                    ]
                },
                "H": {
                    "code": "H",
                    "name": "Hard",
                    "description": "Hard pace",
                    "metric": "vo2max",
                    "targetIntensity": 0.85,
                    "intensityRange": [
                        0.80,
                        0.90
                    ]
                }
            }
        }
        """.data(using: .utf8)!
        
        let system = try JSONDecoder().decode(ZoneSystem.self, from: json)
        XCTAssertEqual(system.name, "Simple Zones")
        XCTAssertEqual(system.allZones.count, 2)
        
        let easyZone = try system.zone(forCode: "E")
        XCTAssertEqual(easyZone.targetIntensity, 0.65)
        XCTAssertEqual(easyZone.intensityRange?.lowerBound, 0.60)
        XCTAssertEqual(easyZone.intensityRange?.upperBound, 0.70)
    }
    
    func testComplexWorkoutWithZones() async throws {
        let json = """
        {
            "name": "Mixed Zone Workout",
            "description": "Workout using different intensities",
            "segments": [
                {
                    "intensity": "0.65 vo2max",
                    "work": "10:00"
                },
                {
                    "intensity": "0.88 vo2max",
                    "work": "5:00",
                    "recovery": "2:00",
                    "iterations": 4
                },
                {
                    "intensity": "0.70 vo2max",
                    "work": "10:00"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let context = TrainingContext()
        context.setZoneSystem(.init(TestZoneSystems.danielsSystem))
        let workout = try await WorkoutTemplate(from: json, using: decoder, context: context)
        XCTAssertEqual(workout.segments.count, 3)
        XCTAssertEqual(workout.segments[0].intensity.value, 0.65)
        XCTAssertEqual(workout.segments[0].intensity.zone?.code, "E")
        XCTAssertEqual(workout.segments[1].intensity.value, 0.88)
        XCTAssertEqual(workout.segments[1].intensity.zone?.code, "T")
        XCTAssertEqual(workout.segments[2].intensity.value, 0.70)
        XCTAssertNil(workout.segments[2].intensity.zone?.code)
    }
}

// Helper extension to check if array is sorted
private extension Array where Element: Comparable {
    func isSorted() -> Bool {
        guard count > 1 else { return true }
        return zip(self, dropFirst()).allSatisfy(<=)
    }
}
