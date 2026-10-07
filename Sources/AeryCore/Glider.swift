import Foundation

public enum SweepType: Int, Codable, CaseIterable, Hashable, Sendable {
    case arbitrary, straightTrailingEdge, centeredWingtip

    public var title: String {
        switch self {
        case .arbitrary: return "Arbitrary Sweep Angle"
        case .straightTrailingEdge: return "Straight Trailing Edge"
        case .centeredWingtip: return "Centered Wingtip"
        }
    }
}

public struct WoodConfiguration: Codable, Equatable, Sendable {
    public var name = "3/16x3/8x36 spruce, 1/8x4x48 balsa"
    public var maximumWingSpan = 121.92
    public var maximumWingWidth = 10.16
    public var wingThickness = 0.32
    public var wingDensity = 132.51
    public var maximumFuselageLength = 91.44
    public var fuselageMassPerLength = 0.01666
    public var fuselageWidth = 0.4763
    public var fuselageDepth = 0.9525
    public var maximumNoseMass = 30.0
    public var airfoilLiftSlope = 5.7
    public var airDensity = 1.22
}

public struct Surface: Codable, Equatable, Sendable {
    public var span: Double
    public var rootChord: Double
    public var taperRatio: Double
    public var sweepAngle: Double
    public var sweepType: SweepType

    public init(span: Double, rootChord: Double, taperRatio: Double = 0.8, sweepAngle: Double = 0, sweepType: SweepType = .arbitrary) {
        self.span = span; self.rootChord = rootChord; self.taperRatio = taperRatio
        self.sweepAngle = sweepAngle; self.sweepType = sweepType
    }

    public var tipChord: Double { rootChord * taperRatio }
    public var area: Double { span * (rootChord + tipChord) / 2 }
    public var aspectRatio: Double { area > 0 ? span * span / area : 0 }
    public var tipSweep: Double { (span / 2) * tan(sweepAngle * .pi / 180) }
}

public struct GliderDesign: Codable, Equatable, Sendable {
    public var name = "Untitled"
    public var fuselageLength = 65.0
    public var wingLocation = 25.0
    public var stabilizerLocation = 48.25
    public var verticalTailLocation = 57.0
    public var noseMass = 12.0
    public var throwingVelocity = 22.0
    public var wing = Surface(span: 70, rootChord: 10.16, taperRatio: 0.76, sweepAngle: 3.985275, sweepType: .centeredWingtip)
    public var stabilizer = Surface(span: 26, rootChord: 7, taperRatio: 0.8)
    public var verticalTail = Surface(span: 13, rootChord: 8, taperRatio: 0.82)
    public var configuration = WoodConfiguration()

    public init() {}

    public var estimatedFuselageMass: Double { fuselageLength / 100 * configuration.fuselageMassPerLength * 1_000 }
    public var estimatedWingMass: Double { wing.area * configuration.wingThickness / 1_000_000 * configuration.wingDensity * 1_000 }
    public var estimatedMass: Double { estimatedFuselageMass + estimatedWingMass + noseMass }
    public var centerOfGravity: Double {
        let fuselage = estimatedFuselageMass * fuselageLength / 2
        let wingMass = estimatedWingMass * (wingLocation + wing.rootChord / 2)
        return (fuselage + wingMass) / max(estimatedFuselageMass + estimatedWingMass + noseMass, .leastNonzeroMagnitude)
    }
}

public struct FlightAssessment: Sendable {
    public let flies: Bool
    public let messages: [String]
    public let wingLoading: Double
    public let stallVelocity: Double
    public let aspectRatio: Double
    public let verticalTailVolume: Double
    public let stabilizerVolume: Double
    public let neutralPoint: Double
    public let evaluationNumber: Double

    public init(design: GliderDesign) {
        let wingAreaM2 = design.wing.area / 10_000
        let massKg = design.estimatedMass / 1_000
        aspectRatio = design.wing.aspectRatio
        wingLoading = design.wing.area > 0 ? design.estimatedMass / design.wing.area : .infinity
        let velocity = design.throwingVelocity / 3.6
        let lift = 0.5 * design.configuration.airDensity * velocity * velocity * wingAreaM2 * 0.9
        stallVelocity = wingAreaM2 > 0 ? sqrt((2 * massKg * 9.80665) / (design.configuration.airDensity * wingAreaM2 * 0.9)) * 3.6 : .infinity
        let wingAC = design.wingLocation + design.wing.rootChord * 0.25
        let stabAC = design.stabilizerLocation + design.stabilizer.rootChord * 0.25
        let vtAC = design.verticalTailLocation + design.verticalTail.rootChord * 0.25
        verticalTailVolume = design.wing.area > 0 ? abs(vtAC - wingAC) * design.verticalTail.area / (design.wing.span * design.wing.area) : 0
        stabilizerVolume = design.wing.area > 0 ? (stabAC - wingAC) * design.stabilizer.area / (design.wing.rootChord * design.wing.area) : 0
        neutralPoint = wingAC + (stabAC - wingAC) * min(0.8, abs(design.stabilizer.area / max(design.wing.area, 0.001)))
        var notes: [String] = []
        if design.wing.area <= 0 || design.estimatedMass <= 0 { notes.append("The wing area and estimated mass must be greater than zero.") }
        if lift < massKg * 9.80665 { notes += ["The lift required is too large for the design.", "Increase the velocity, increase the size of the wing, or decrease the mass at the nose."] }
        if verticalTailVolume < 0.035 { notes += ["The vertical tail is incorrectly placed or sized.", "Increase its area, or move it farther from the wing."] }
        if stabilizerVolume > -0.1 && stabilizerVolume < 0.5 { notes += ["The stabilizer is probably incorrectly placed or sized.", "Increase its area, or move it farther aft (or farther forward for a canard)."] }
        if design.centerOfGravity >= neutralPoint { notes += ["The center of gravity is behind the neutral point. (The glider will be unstable)", "Move the wing farther aft, or add more mass to the nose."] }
        if neutralPoint - design.centerOfGravity < design.wing.rootChord * 0.05 && design.centerOfGravity < neutralPoint { notes.append("The static margin for stability is less than the recommended value (0.05).") }
        flies = notes.isEmpty || !notes.contains(where: { $0.contains("too large") || $0.contains("incorrectly") || $0.contains("unstable") })
        messages = notes.isEmpty ? ["It will fly!", "This design has acceptable lift, longitudinal stability, and tail sizing."] : notes
        evaluationNumber = flies ? max(1, 100 * verticalTailVolume + 100 * abs(stabilizerVolume) + aspectRatio) : 0
    }
}

public enum AeryFile: Sendable {
    private static let labels = ["Glider Name", "Fuselage Length (cm)", "Wing X Location (cm)", "Stabilizer X Location (cm)", "Vertical Tail X Location (cm)", "Mass at the nose (g)", "Throwing Velocity (km/hr)", "Wing Span (cm)", "Wing Root Chord (cm)", "Wing Taper Ratio", "Wing LE Angle (deg.)", "Wing Sweep Type", "Stabilizer Span (cm)", "Stabilizer Root Chord (cm)", "Stabilizer Taper Ratio", "Stabilizer LE Angle (deg.)", "Stabilizer Sweep Type", "Vertical Tail Height (cm)", "Vertical Tail Root Chord (cm)", "Vertical Tail Taper Ratio", "Vertical Tail LE Angle (deg.)", "Vertical Tail Sweep Type", "configuration name", "maximum wing span (cm)", "maximum wing width (cm)", "wing thickness (cm)", "wing density (kg/m^3)", "max fuselage length (cm)", "fuselage mass/length (kg/m)", "fuselage width (top) (cm)", "fuselage depth (side) (cm)", "max nose mass (grams)", "airfoil section lift coefficient", "air density (kg/m^3)"]

    public static func encode(_ design: GliderDesign) -> String {
        let c = design.configuration
        let values: [String] = [design.name, n(design.fuselageLength), n(design.wingLocation), n(design.stabilizerLocation), n(design.verticalTailLocation), n(design.noseMass), n(design.throwingVelocity), n(design.wing.span), n(design.wing.rootChord), n(design.wing.taperRatio), n(design.wing.sweepAngle), "\(design.wing.sweepType.rawValue)", n(design.stabilizer.span), n(design.stabilizer.rootChord), n(design.stabilizer.taperRatio), n(design.stabilizer.sweepAngle), "\(design.stabilizer.sweepType.rawValue)", n(design.verticalTail.span), n(design.verticalTail.rootChord), n(design.verticalTail.taperRatio), n(design.verticalTail.sweepAngle), "\(design.verticalTail.sweepType.rawValue)", c.name, n(c.maximumWingSpan), n(c.maximumWingWidth), n(c.wingThickness), n(c.wingDensity), n(c.maximumFuselageLength), n(c.fuselageMassPerLength), n(c.fuselageWidth), n(c.fuselageDepth), n(c.maximumNoseMass), n(c.airfoilLiftSlope), n(c.airDensity)]
        return zip(labels, values).map { "\"\($0)\",\"\($1)\"" }.joined(separator: "\n") + "\n"
    }

    public static func decode(_ text: String) -> GliderDesign? {
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) { let pieces = line.split(separator: "\",\""); if pieces.count == 2 { values[String(pieces[0]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))] = String(pieces[1]).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) } }
        guard let name = values["Glider Name"] else { return nil }
        var d = GliderDesign(); d.name = name
        func number(_ key: String, _ current: Double) -> Double { Double(values[key] ?? "") ?? current }
        d.fuselageLength = number("Fuselage Length (cm)", d.fuselageLength); d.wingLocation = number("Wing X Location (cm)", d.wingLocation); d.stabilizerLocation = number("Stabilizer X Location (cm)", d.stabilizerLocation); d.verticalTailLocation = number("Vertical Tail X Location (cm)", d.verticalTailLocation); d.noseMass = number("Mass at the nose (g)", d.noseMass); d.throwingVelocity = number("Throwing Velocity (km/hr)", d.throwingVelocity)
        d.wing.span = number("Wing Span (cm)", d.wing.span); d.wing.rootChord = number("Wing Root Chord (cm)", d.wing.rootChord); d.wing.taperRatio = number("Wing Taper Ratio", d.wing.taperRatio); d.wing.sweepAngle = number("Wing LE Angle (deg.)", d.wing.sweepAngle); d.wing.sweepType = SweepType(rawValue: Int(number("Wing Sweep Type", Double(d.wing.sweepType.rawValue)))) ?? .arbitrary
        d.stabilizer.span = number("Stabilizer Span (cm)", d.stabilizer.span); d.stabilizer.rootChord = number("Stabilizer Root Chord (cm)", d.stabilizer.rootChord); d.stabilizer.taperRatio = number("Stabilizer Taper Ratio", d.stabilizer.taperRatio); d.stabilizer.sweepAngle = number("Stabilizer LE Angle (deg.)", d.stabilizer.sweepAngle); d.stabilizer.sweepType = SweepType(rawValue: Int(number("Stabilizer Sweep Type", Double(d.stabilizer.sweepType.rawValue)))) ?? .arbitrary
        d.verticalTail.span = number("Vertical Tail Height (cm)", d.verticalTail.span); d.verticalTail.rootChord = number("Vertical Tail Root Chord (cm)", d.verticalTail.rootChord); d.verticalTail.taperRatio = number("Vertical Tail Taper Ratio", d.verticalTail.taperRatio); d.verticalTail.sweepAngle = number("Vertical Tail LE Angle (deg.)", d.verticalTail.sweepAngle); d.verticalTail.sweepType = SweepType(rawValue: Int(number("Vertical Tail Sweep Type", Double(d.verticalTail.sweepType.rawValue)))) ?? .arbitrary
        d.configuration.name = values["configuration name"] ?? d.configuration.name
        d.configuration.maximumWingSpan = number("maximum wing span (cm)", d.configuration.maximumWingSpan); d.configuration.maximumWingWidth = number("maximum wing width (cm)", d.configuration.maximumWingWidth); d.configuration.wingThickness = number("wing thickness (cm)", d.configuration.wingThickness); d.configuration.wingDensity = number("wing density (kg/m^3)", d.configuration.wingDensity); d.configuration.maximumFuselageLength = number("max fuselage length (cm)", d.configuration.maximumFuselageLength); d.configuration.fuselageMassPerLength = number("fuselage mass/length (kg/m)", d.configuration.fuselageMassPerLength); d.configuration.fuselageWidth = number("fuselage width (top) (cm)", d.configuration.fuselageWidth); d.configuration.fuselageDepth = number("fuselage depth (side) (cm)", d.configuration.fuselageDepth); d.configuration.maximumNoseMass = number("max nose mass (grams)", d.configuration.maximumNoseMass); d.configuration.airfoilLiftSlope = number("airfoil section lift coefficient", d.configuration.airfoilLiftSlope); d.configuration.airDensity = number("air density (kg/m^3)", d.configuration.airDensity)
        return d
    }

    private static func n(_ value: Double) -> String { String(format: "%.6g", value) }
}
