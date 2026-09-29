import XCTest
@testable import AeryCore

final class AeryCoreTests: XCTestCase {
    func testDefaultDesignIsViableStartingPoint() {
        let assessment = FlightAssessment(design: GliderDesign())
        XCTAssertEqual(assessment.verdict, .ready)
        XCTAssertEqual(assessment.aspectRatio, 5.625, accuracy: 0.001)
        XCTAssertGreaterThan(assessment.estimatedLaunchSpeed, 0)
    }

    func testAftCenterOfGravityIsUnsafe() {
        var design = GliderDesign()
        design.centerOfGravity = 0.45
        XCTAssertEqual(FlightAssessment(design: design).verdict, .unsafe)
    }
}
