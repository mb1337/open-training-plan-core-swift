import Foundation
import Yams

// For marking properties that need to be resolved
@propertyWrapper
public final class RemoteResource<Value: Codable>: Codable, RemoteResolvable {
    public private(set) var wrappedValue: Value?
    private let remoteURL: URL?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let urlString = try? container.decode(String.self) {
            self.remoteURL = URL(string: urlString)
            self.wrappedValue = nil
        } else {
            self.remoteURL = nil
            self.wrappedValue = try container.decode(Value.self)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let url = remoteURL {
            try container.encode(url.absoluteString)
        } else if let value = wrappedValue {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
    
    public init(_ value: Value? = nil) {
        self.wrappedValue = value
        self.remoteURL = nil
    }
    
    public func resolve(using decoder: RemoteDecoder) async throws {
        if let url = remoteURL {
            wrappedValue = try await decoder.decode(url)
            if let resolvable = wrappedValue as? RemoteResolvable {
                try await resolvable.resolve(using: decoder)
            }
        }
    }
}

// For arrays of remote resources
@propertyWrapper
public final class RemoteResourceList<Element: Codable>: Codable, RemoteResolvable {
    public private(set) var wrappedValue: [Element]?
    private var elements: [Either<URL, Element>]?
    
    private enum Either<A: Codable, B: Codable>: Codable {
        case left(A)
        case right(B)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let a = try? container.decode(A.self) {
                self = .left(a)
            } else if let b = try? container.decode(B.self) {
                self = .right(b)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to decode either")
            }
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .left(let a):
                try container.encode(a)
            case .right(let b):
                try container.encode(b)
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([Either<String, Element>].self)
        
        let elements: [Either<URL, Element>] = try array.map { decodable in
            switch decodable {
            case .left(let urlString):
                if let url = URL(string: urlString) {
                    return .left(url)
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid URL: \(urlString)")
                }
            case .right(let element):
                return .right(element)
            }
        }
        self.elements = elements
        
        self.wrappedValue = elements.compactMap { either in
            if case .right(let element) = either {
                return element
            }
            return nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let elements = self.elements else {
            try container.encodeNil()
            return
        }
        let encodableArray: [Either<String, Element>] = elements.map { either in
            switch either {
            case .left(let url):
                return .left(url.absoluteString)
            case .right(let element):
                return .right(element)
            }
        }
        try container.encode(encodableArray)
    }
    
    public init(_ value: [Element]? = nil) {
        self.wrappedValue = value
        self.elements = value?.map { .right($0) }
    }
    
    public func resolve(using decoder: RemoteDecoder) async throws {
        guard let elements = self.elements else {
            return
        }
        var resolved: [Element] = []
        
        for element in elements {
            switch element {
            case .left(let url):
                let value: Element = try await decoder.decode(url)
                resolved.append(value)
                if let resolvable = value as? RemoteResolvable {
                    try await resolvable.resolve(using: decoder)
                }
            case .right(let value):
                resolved.append(value)
                if let resolvable = value as? RemoteResolvable {
                    try await resolvable.resolve(using: decoder)
                }
            }
        }
        
        wrappedValue = resolved
    }
}

// Protocol for types that can have remote resources
protocol RemoteResolvable {
    func resolve(using resolver: RemoteDecoder) async throws
}

// Default implementation that uses reflection to find and resolve RemoteResources
extension RemoteResolvable {
    func resolve(using decoder: RemoteDecoder) async throws {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            // If property is itself RemoteResolvable
            if let resolvable = child.value as? RemoteResolvable {
                try await resolvable.resolve(using: decoder)
            } else if let resolvableArray = child.value as? [RemoteResolvable] {
                for resolvable in resolvableArray {
                    try await resolvable.resolve(using: decoder)
                }
            }
        }
    }
}

public protocol RemoteResolver {
    func resolve(_ url: URL) async throws -> Data
}

public protocol DataDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

public struct DefaultRemoteResolver: RemoteResolver {
    private let urlSession: URLSession
    public init(_ urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    public func resolve(_ url: URL) async throws -> Data {
        let (data, _) = try await urlSession.data(from: url)
        return data
    }
}

public struct RemoteDecoder {
    private let decoder: DataDecoder
    private let resolver: RemoteResolver
    
    private class Cache {
        struct Entry {
            let value: Any
        }
        private var cache: [URL: Entry] = [:]
        public func get(_ url: URL) -> Entry? {
            cache[url]
        }
        public func set(_ value: Any, for url: URL) {
            cache[url] = .init(value: value)
        }
    }
    private let cache: Cache = .init()
    
    
    public init(decoder: DataDecoder, resolver: RemoteResolver = DefaultRemoteResolver()) {
        self.decoder = decoder
        self.resolver = resolver
    }
    
    public func decode<T: Decodable>(_ url: URL) async throws -> T {
        if let entry = cache.get(url) {
            return entry.value as! T
        }
        let data = try await resolver.resolve(url)
        let value = try decoder.decode(T.self, from: data)
        cache.set(value, for: url)
        return value
    }
}

extension JSONDecoder: DataDecoder {}
extension YAMLDecoder: DataDecoder {}
