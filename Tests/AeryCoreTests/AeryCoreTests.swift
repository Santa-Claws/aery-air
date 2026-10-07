import XCTest
@testable import AeryCore

final class AeryCoreTests: XCTestCase {
    func testAeryDesignRoundTripsInOriginalTextFormat() throws {
        var design = GliderDesign(); design.name = "Test Glider #1"; design.wing.taperRatio = 0.76
        let decoded = try XCTUnwrap(AeryFile.decode(AeryFile.encode(design)))
        XCTAssertEqual(decoded.name, design.name)
        XCTAssertEqual(decoded.wing.taperRatio, 0.76, accuracy: 0.0001)
    }

    func testDefaultDesignHasUsefulAnalysis() {
        let analysis = FlightAssessment(design: GliderDesign())
        XCTAssertGreaterThan(analysis.wingLoading, 0)
        XCTAssertGreaterThan(analysis.stallVelocity, 0)
    }
}
