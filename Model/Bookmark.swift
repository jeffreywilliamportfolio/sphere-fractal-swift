import Foundation
import simd

struct Bookmark: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var offset: Float3Codable
    var logScale: Float

    init(id: UUID = UUID(), name: String, offset: SIMD3<Float>, logScale: Float) {
        self.id = id
        self.name = name
        self.offset = Float3Codable(offset)
        self.logScale = logScale
    }
}

struct Float3Codable: Codable, Equatable {
    var x: Float
    var y: Float
    var z: Float

    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(_ v: SIMD3<Float>) {
        self.x = v.x
        self.y = v.y
        self.z = v.z
    }

    var simd: SIMD3<Float> { SIMD3<Float>(x, y, z) }
}

