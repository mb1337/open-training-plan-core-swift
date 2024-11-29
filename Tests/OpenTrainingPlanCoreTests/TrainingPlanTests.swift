import XCTest
@testable import OpenTrainingPlanCore

final class TrainingPlanTests: XCTestCase {
    func testBasicPlanDecoding() async throws {
        let json = """
        {
            "name": "5K Training Plan",
            "description": "12 week training plan for 5K",
            "author": "Coach Smith",
            "weeks": [
                {
                    "days": [
                        {
                            "workouts": [
                                {
                                    "template": "https://api.example.com/workouts/easy-run",
                                    "targetVolume": "5 km"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let mockResponses: [URL: Data] = [
            URL(string: "https://api.example.com/workouts/easy-run")!: """
            {
                "name": "Easy Run",
                "description": "Basic easy run",
                "segments": [
                    {
                        "intensity": "0.65 hr_max",
                        "work": "30:00"
                    }
                ]
            }
            """.data(using: .utf8)!
        ]
        
        // When
        let decoder = JSONDecoder()
        let mockResolver = MockRemoteResolver(data: mockResponses)
        let plan = try await TrainingPlan(from: json, using: decoder, resolver: mockResolver)
        
        // Then
        XCTAssertEqual(plan.name, "5K Training Plan")
        XCTAssertEqual(plan.author, "Coach Smith")
        XCTAssertEqual(plan.weeks.count, 1)
        XCTAssertEqual(plan.weeks[0].days.count, 1)
        
        // Check workout
        let workout = try XCTUnwrap(plan.weeks[0].days[0].workouts[0].template)
        XCTAssertEqual(workout.name, "Easy Run")
        XCTAssertEqual(workout.segments.count, 1)
    }
    
    func testWorkoutMeasureParsing() throws {
        // Test time formats
        let timeTests = [
            "30:00": TimeInterval(1800),
            "1:30:00": TimeInterval(5400),
            "0:45": TimeInterval(45)
        ]
        
        for (input, expected) in timeTests {
            let data = "\"\(input)\"".data(using: .utf8)!
            let measure = try JSONDecoder().decode(WorkoutMeasure.self, from: data)
            if case .time(let time) = measure {
                XCTAssertEqual(time, expected)
            } else {
                XCTFail("Expected time measure for input: \(input)")
            }
        }
        
        // Test distance formats
        let distanceTests = [
            "5 km": Measurement(value: 5, unit: UnitLength.kilometers),
            "400 m": Measurement(value: 400, unit: UnitLength.meters),
            "3 mi": Measurement(value: 3, unit: UnitLength.miles)
        ]
        
        for (input, expected) in distanceTests {
            let data = "\"\(input)\"".data(using: .utf8)!
            let measure = try JSONDecoder().decode(WorkoutMeasure.self, from: data)
            if case .distance(let distance) = measure {
                XCTAssertEqual(distance, expected)
            } else {
                XCTFail("Expected distance measure for input: \(input)")
            }
        }
    }
    
    func testIntensityHandling() throws {
        // Test direct intensity
        let json = #""0.70vo2max""#.data(using: .utf8)!
        
        let intensity = try JSONDecoder().decode(_Intensity.self, from: json)
        XCTAssertEqual(intensity.value, 0.70)
        XCTAssertEqual(intensity.metric, .vo2max)
    }
    
    func testWorkoutSegmentHandling() throws {
        let json = """
        {
            "intensity": "0.80 hr_max",
            "work": "400 m",
            "recovery": "1:00",
            "iterations": 8,
            "label": "Speed intervals"
        }
        """.data(using: .utf8)!
        
        let segment = try JSONDecoder().decode(_WorkoutSegment.self, from: json)
        XCTAssertEqual(segment.intensity.value, 0.80)
        XCTAssertEqual(segment.intensity.metric, .hrMax)
        
        if case .distance(let distance) = segment.work {
            XCTAssertEqual(distance.value, 400)
            XCTAssertEqual(distance.unit, UnitLength.meters)
        } else {
            XCTFail("Expected distance measure for work")
        }
        
        if case .time(let time) = segment.recovery {
            XCTAssertEqual(time, 60)
        } else {
            XCTFail("Expected time measure for recovery")
        }
        
        XCTAssertEqual(segment.iterations, 8)
        XCTAssertEqual(segment.label, "Speed intervals")
    }
    
    func testAlternateWorkouts() async throws {
        let json = """
        {
            "name": "Flexible Plan",
            "description": "Plan with alternate workouts",
            "zoneSystem": "https://api.example.com/systems/daniels",
            "weeks": [
                {
                    "days": [
                        {
                            "workouts": [
                                {
                                    "template": "https://api.example.com/workouts/tempo",
                                    "alternates": [
                                        "https://api.example.com/workouts/hills",
                                        "https://api.example.com/workouts/intervals"
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let mockResponses: [URL: Data] = [
            URL(string: "https://api.example.com/systems/daniels")!: try JSONEncoder().encode(TestZoneSystems.danielsSystem),
            URL(string: "https://api.example.com/workouts/tempo")!: #"{"name": "Tempo Run", "segments": [{"intensity": "0.88 vo2max","work":"5:00","recovery":"1:00"}]}"#.data(using: .utf8)!,
            URL(string: "https://api.example.com/workouts/hills")!: #"{"name": "Hill Workout", "segments": [{"intensity": "1.0 vo2max","work":"1:00","recovery":"2:00"}]}"#.data(using: .utf8)!,
            URL(string: "https://api.example.com/workouts/intervals")!: #"{"name": "Interval Session", "segments": [{"intensity":"0.95 vo2max","work":"3:00","recovery":"3:00"}]}"#.data(using: .utf8)!
        ]
        
        let decoder = JSONDecoder()
        let mockResolver = MockRemoteResolver(data: mockResponses)
        let plan = try await TrainingPlan(from: json, using: decoder, resolver: mockResolver)
        let workout = plan.weeks[0].days[0].workouts[0]
        
        XCTAssertEqual(workout.template.name, "Tempo Run")
        XCTAssertEqual(workout.alternates?.count, 2)
        XCTAssertEqual(workout.alternates?[0].name, "Hill Workout")
        XCTAssertEqual(workout.alternates?[1].name, "Interval Session")
    }
    
    func testTargetVolumeHandling() throws {
        // Test percentage
        let percentageData = "\"8%\"".data(using: .utf8)!
        let percentage = try JSONDecoder().decode(TargetVolume.self, from: percentageData)
        if case .percentage(let value) = percentage {
            XCTAssertEqual(value, 0.08)
        } else {
            XCTFail("Expected percentage target volume")
        }
        
        // Test absolute
        let absoluteData = "\"5 km\"".data(using: .utf8)!
        let absolute = try JSONDecoder().decode(TargetVolume.self, from: absoluteData)
        if case .absolute(let measure) = absolute {
            if case .distance(let distance) = measure {
                XCTAssertEqual(distance.value, 5)
                XCTAssertEqual(distance.unit, UnitLength.kilometers)
            } else {
                XCTFail("Expected distance measure")
            }
        } else {
            XCTFail("Expected absolute target volume")
        }
    }
}
