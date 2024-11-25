import XCTest

import Yams
@testable import OpenTrainingPlanCore

enum MockRemoteResolverError: Error {
    case notFound
}

// Mock URLSession for testing
struct MockRemoteResolver: RemoteResolver {
    var data: [URL: Data]
    
    init(data: [URL: Data]) {
        self.data = data
    }
    
    func resolve(_ url: URL) async throws -> Data {
        guard let data = data[url] else {
            throw MockRemoteResolverError.notFound
        }
        return data
    }
}

// Example usage:
struct UserList: Codable, RemoteResolvable {
    @RemoteResourceList<User> var users: [User]?
}

struct User: Codable, RemoteResolvable {
    let id: Int
    let name: String
    @RemoteResource var profile: Profile?
}

struct Profile: Codable, RemoteResolvable {
    let bio: String
    @RemoteResource var avatar: Avatar?
}

struct Avatar: Codable {
    let url: String
    let size: Int
}

final class RemoteResourceTests: XCTestCase {
    var mockResolver: MockRemoteResolver!
    let profileURL = URL(string: "https://api.example.com/profiles/1")!
    let avatarURL = URL(string: "https://api.example.com/avatars/1")!
    let userURL = URL(string: "https://api.example.com/users/1")!
    
    override func setUp() {
        super.setUp()
        
        // Set up mock responses
        let mockResponses: [URL: Data] = [
            profileURL: """
            {
                "bio": "Test Bio",
                "avatar": "https://api.example.com/avatars/1"
            }
            """.data(using: .utf8)!,
            
            avatarURL: """
            {
                "url": "https://example.com/avatar1.jpg",
                "size": 100
            }
            """.data(using: .utf8)!,
            
            userURL: """
            {
                "id": 1,
                "name": "Test User",
                "profile": "https://api.example.com/profiles/1"
            }
            """.data(using: .utf8)!
        ]
        
        mockResolver = MockRemoteResolver(data: mockResponses)
    }
    
    func testResolveJSON() async throws {
        // Given
        let json = """
        {
            "id": 1,
            "name": "Test User",
            "profile": "https://api.example.com/profiles/1"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)
        let remoteDecoder = RemoteDecoder(decoder: decoder, resolver: mockResolver)
        
        // When
        try await user.resolve(using: remoteDecoder)
        
        // Then
        XCTAssertNotNil(user.profile)
        XCTAssertEqual(user.profile?.bio, "Test Bio")
        XCTAssertNotNil(user.profile?.avatar)
        XCTAssertEqual(user.profile?.avatar?.url, "https://example.com/avatar1.jpg")
        XCTAssertEqual(user.profile?.avatar?.size, 100)
    }
    
    func testResolveYAML() async throws {
        // Given
        let yaml = """
        id: 1
        name: Test User
        profile: https://api.example.com/profiles/1
        """.data(using: .utf8)!
        
        let decoder = YAMLDecoder()
        let user = try decoder.decode(User.self, from: yaml)
        let remoteDecoder = RemoteDecoder(decoder: decoder, resolver: mockResolver) // Note: Mock returns JSON, but JSON is a subset of YAML
        
        // When
        try await user.resolve(using: remoteDecoder)
        
        // Then
        XCTAssertNotNil(user.profile)
        XCTAssertEqual(user.profile?.bio, "Test Bio")
        XCTAssertNotNil(user.profile?.avatar)
        XCTAssertEqual(user.profile?.avatar?.url, "https://example.com/avatar1.jpg")
        XCTAssertEqual(user.profile?.avatar?.size, 100)
    }
    
    func testLocalValueDecoding() throws {
        // Given
        let json = """
        {
            "id": 1,
            "name": "Test User",
            "profile": {
                "bio": "Local Bio",
                "avatar": {
                    "url": "local.jpg",
                    "size": 50
                }
            }
        }
        """.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)
        
        // Then
        XCTAssertNotNil(user.profile)
        XCTAssertEqual(user.profile?.bio, "Local Bio")
        XCTAssertNotNil(user.profile?.avatar)
        XCTAssertEqual(user.profile?.avatar?.url, "local.jpg")
        XCTAssertEqual(user.profile?.avatar?.size, 50)
    }
    
    func testArrayDecoding() async throws {
        // Given
        let json = """
        {
        "users":
        [
        "https://api.example.com/users/1",
        {
            "id": 2,
            "name": "Test User",
            "profile": {
                "bio": "Local Bio",
                "avatar": {
                    "url": "local.jpg",
                    "size": 50
                }
            }
        }
        ]
        }
        """.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let list = try decoder.decode(UserList.self, from: json)
        let remoteDecoder = RemoteDecoder(decoder: decoder, resolver: mockResolver)
        
        try await list.resolve(using: remoteDecoder)
        
        // Then
        XCTAssertNotNil(list.users?[0])
        if let user = list.users?[0] {
            XCTAssertNotNil(user.profile)
            XCTAssertEqual(user.profile?.bio, "Test Bio")
            XCTAssertNotNil(user.profile?.avatar)
            XCTAssertEqual(user.profile?.avatar?.url, "https://example.com/avatar1.jpg")
            XCTAssertEqual(user.profile?.avatar?.size, 100)
        } else {
            XCTAssertTrue(false, "Expected user 1 to be present")
        }

        XCTAssertNotNil(list.users?[1])
        if let user = list.users?[1] {
            XCTAssertNotNil(user.profile)
            XCTAssertEqual(user.profile?.bio, "Local Bio")
            XCTAssertNotNil(user.profile?.avatar)
            XCTAssertEqual(user.profile?.avatar?.url, "local.jpg")
            XCTAssertEqual(user.profile?.avatar?.size, 50)
        } else {
            XCTAssertTrue(false, "Expected user 1 to be present")
        }
    }
    
    func testMissingRemoteResource() async throws {
        // Given
        let json = """
        {
            "id": 1,
            "name": "Test User",
            "profile": "https://api.example.com/profiles/404"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)
        let resolver = RemoteDecoder(decoder: decoder, resolver: mockResolver)
        do {
            try await user.resolve(using: resolver)
            XCTAssertTrue(false , "Expected error to be thrown")
        } catch {
            
        }
    }
}
