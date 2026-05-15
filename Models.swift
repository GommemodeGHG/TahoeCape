import Foundation
import SwiftUI

struct Cape: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    let name: String
    let author: String?
    let version: Double?
    let cursors: [String: Cursor]
    
    init(id: UUID = UUID(), name: String, author: String?, version: Double?, cursors: [String: Cursor]) {
        self.id = id; self.name = name; self.author = author; self.version = version; self.cursors = cursors
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Cape, rhs: Cape) -> Bool { lhs.id == rhs.id }

    enum CodingKeys: String, CodingKey { case name, CapeName, author, Author, version, Version, cursors, Cursors }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? container.decodeIfPresent(String.self, forKey: .CapeName) ?? "Unnamed Cape"
        self.author = try container.decodeIfPresent(String.self, forKey: .author) ?? container.decodeIfPresent(String.self, forKey: .Author)
        self.version = try? container.decodeIfPresent(Double.self, forKey: .version) ?? 1.0
        
        var decodedCursors: [String: Cursor] = [:]
        if let rawCursors = try? container.decodeIfPresent([String: Cursor].self, forKey: .cursors) ?? container.decodeIfPresent([String: Cursor].self, forKey: .Cursors) {
            decodedCursors = rawCursors
        }
        self.cursors = decodedCursors
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(cursors, forKey: .cursors)
    }
}

struct Cursor: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    let hotspot: String?
    let hotspotX: Float?
    let hotspotY: Float?
    let representations: [String: Representation]
    let frameCount: Int?
    let frameDuration: Double?
    
    init(id: UUID = UUID(), hotspot: String? = nil, hotspotX: Float? = nil, hotspotY: Float? = nil, representations: [String: Representation] = [:], frameCount: Int? = nil, frameDuration: Double? = nil) {
        self.id = id; self.hotspot = hotspot; self.hotspotX = hotspotX; self.hotspotY = hotspotY; self.representations = representations; self.frameCount = frameCount; self.frameDuration = frameDuration
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Cursor, rhs: Cursor) -> Bool { lhs.id == rhs.id }
    
    enum CodingKeys: String, CodingKey { case hotspot, HotSpot, HotSpotX, HotSpotY, representations, Representations, hotspotX, hotspotY, FrameCount, FrameDuration }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hotspot = try? container.decodeIfPresent(String.self, forKey: .hotspot) ?? container.decodeIfPresent(String.self, forKey: .HotSpot)
        self.hotspotX = try? container.decodeIfPresent(Float.self, forKey: .hotspotX) ?? container.decodeIfPresent(Float.self, forKey: .HotSpotX)
        self.hotspotY = try? container.decodeIfPresent(Float.self, forKey: .hotspotY) ?? container.decodeIfPresent(Float.self, forKey: .HotSpotY)
        
        var reps: [String: Representation] = [:]
        
        if let array = try? container.decodeIfPresent([AnyCodable].self, forKey: .Representations) ?? container.decodeIfPresent([AnyCodable].self, forKey: .representations) {
            for (index, item) in array.enumerated() {
                if let path = item.value as? String {
                    reps["\(index+1)x"] = Representation(path: path, data: nil, frame: nil)
                } else if let data = item.value as? Data {
                    reps["\(index+1)x"] = Representation(path: nil, data: data, frame: nil)
                } else if let dict = item.value as? [String: Any] {
                    let path = dict["Path"] as? String ?? dict["path"] as? String
                    let data = dict["Data"] as? Data ?? dict["data"] as? Data
                    reps["\(index+1)x"] = Representation(path: path, data: data, frame: nil)
                }
            }
        } else if let dict = try? container.decodeIfPresent([String: Representation].self, forKey: .Representations) {
            reps = dict
        }
        
        self.representations = reps
        self.frameCount = try? container.decodeIfPresent(Int.self, forKey: .FrameCount)
        self.frameDuration = try? container.decodeIfPresent(Double.self, forKey: .FrameDuration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(representations, forKey: .representations)
    }
    
    var parsedHotspot: CGPoint {
        if let x = hotspotX, let y = hotspotY { return CGPoint(x: CGFloat(x), y: CGFloat(y)) }
        return .zero
    }
}

struct Representation: Codable, Hashable {
    let path: String?
    let data: Data?
    let frame: String?
    
    enum CodingKeys: String, CodingKey { case path, Path, data, Data, frame, Frame }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.path = try container.decodeIfPresent(String.self, forKey: .path) ?? container.decodeIfPresent(String.self, forKey: .Path)
            self.data = try container.decodeIfPresent(Data.self, forKey: .data) ?? container.decodeIfPresent(Data.self, forKey: .Data)
            self.frame = try container.decodeIfPresent(String.self, forKey: .frame) ?? container.decodeIfPresent(String.self, forKey: .Frame)
        } else {
            let container = try decoder.singleValueContainer()
            self.path = try container.decode(String.self)
            self.data = nil
            self.frame = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(data, forKey: .data)
    }
    
    init(path: String?, data: Data?, frame: String?) {
        self.path = path; self.data = data; self.frame = frame
    }
}

struct AnyCodable: Codable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Data.self) { value = d }
        else if let s = try? container.decode(String.self) { value = s }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let f = try? container.decode(Double.self) { value = f }
        else if let b = try? container.decode(Bool.self) { value = b }
        else if let dict = try? container.decode([String: AnyCodable].self) { value = dict.mapValues { $0.value } }
        else if let arr = try? container.decode([AnyCodable].self) { value = arr.map { $0.value } }
        else { value = "" }
    }
    func encode(to encoder: Encoder) throws {}
}
