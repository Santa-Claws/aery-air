import Foundation

public struct GliderDesign: Codable, Equatable, Sendable {
    public var name: String
    public var wingspan: Double          // m
    public var wingChord: Double         // m
    public var horizontalTailArea: Double // m²
    public var tailMomentArm: Double     // m
    public var mass: Double              // kg
    public var centerOfGravity: Double   // fraction of wing chord aft of leading edge

    public init(
        name: String = "Untitled glider",
        wingspan: Double = 0.45,
        wingChord: Double = 0.08,
        horizontalTailArea: Double = 0.004,
        tailMomentArm: Double = 0.18,
        mass: Double = 0.025,
        centerOfGravity: Double = 0.30
    ) {
        self.name = name
        self.wingspan = wingspan
        self.wingChord = wingChord
        self.horizontalTailArea = horizontalTailArea
        self.tailMomentArm = tailMomentArm
        self.mass = mass
        self.centerOfGravity = centerOfGravity
    }

    public var wingArea: Double { wingspan * wingChord }
    public var aspectRatio: Double { guard wingArea > 0 else { return 0 }; return wingspan * wingspan / wingArea }
    public var tailVolume: Double {
        guard wingArea > 0, wingChord > 0 else { return 0 }
        return horizontalTailArea * tailMomentArm / (wingArea * wingChord)
    }
}

public enum FlightVerdict: String, Sendable {
    case ready = "Ready to test"
    case caution = "Needs adjustment"
    case unsafe = "Not ready"
}

public struct FlightAssessment: Sendable {
    public let verdict: FlightVerdict
    public let messages: [String]
    public let wingLoading: Double       // N/m²
    public let estimatedLaunchSpeed: Double // m/s
    public let aspectRatio: Double
    public let tailVolume: Double

    public init(design: GliderDesign) {
        aspectRatio = design.aspectRatio
        tailVolume = design.tailVolume
        let gravity = 9.80665
        let airDensity = 1.225
        wingLoading = design.wingArea > 0 ? design.mass * gravity / design.wingArea : .infinity
        estimatedLaunchSpeed = design.wingArea > 0 ? sqrt(2 * design.mass * gravity / (airDensity * design.wingArea * 1.05)) : .infinity

        var notes: [String] = []
        var severe = false
        if design.wingArea <= 0 || design.mass <= 0 { notes.append("Wing area and mass must be greater than zero."); severe = true }
        if design.wingspan < 0.15 { notes.append("Increase wingspan; this is very small for a hand-launched glider."); severe = true }
        if aspectRatio < 3 { notes.append("Increase span or reduce chord for a more efficient wing.") }
        if design.centerOfGravity < 0.20 { notes.append("Move the center of gravity aft slightly; it is very nose-heavy.") }
        if design.centerOfGravity > 0.40 { notes.append("Move the center of gravity forward; this position risks a stall."); severe = true }
        if tailVolume + 0.000_001 < 0.25 { notes.append("Increase horizontal-tail area or tail arm for better pitch stability.") }
        if wingLoading > 18 { notes.append("Reduce mass or add wing area; wing loading is high for a simple balsa glider.") }
        if notes.isEmpty { notes.append("Balanced starting point. Test with short, gentle hand launches and adjust in small steps.") }
        let verdict: FlightVerdict = severe ? .unsafe : (notes.count == 1 && aspectRatio >= 3 && tailVolume + 0.000_001 >= 0.25 ? .ready : .caution)
        self.verdict = verdict
        self.messages = notes
    }
}
