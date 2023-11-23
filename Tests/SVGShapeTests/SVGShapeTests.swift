import XCTest
@testable import SVGShape

final class SVGShapeTests: XCTestCase {
    func testSVGPathArgParsing() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        
        let astring = "6.6.2"
        let ns1 = try! SVGShape.parseArgs(Substring(astring))
        XCTAssertEqual(ns1, [6.599999904632568, 0.20000000298023224], "Incorrect args.")
        
        XCTAssertEqual(CGFloat((".2" as NSString).floatValue), 0.20000000298023224, "Incorrect float.")

        let bstring = "-.6 9.4-4 14.5-9.1 17-.8.4-2.1.4-3-.2-6-3.8"
        let ns2 = try! SVGShape.parseArgs(Substring(bstring))
        XCTAssertEqual(ns2.count, 14, "Incorrect args count.")
        
        let cstring = "0-1.9-2.8-2.5-3.6-.7-3.4 10-3.3 22.8-.8 29 1.3 3.1 1.3 6.6.2 9.8-1.4 4-2.1 8.5-2 13"
        let ns3 = try! SVGShape.parseArgs(Substring(cstring))
        XCTAssertEqual(ns3.count, 24, "Incorrect args count.")

    }
}
