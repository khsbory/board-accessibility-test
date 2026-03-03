import XCTest

final class BoardAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testMainScreenShowsFourButtons() {
        XCTAssertTrue(app.buttons["UIKit 독립 화면"].exists)
        XCTAssertTrue(app.buttons["UIKit 단일 화면"].exists)
        XCTAssertTrue(app.buttons["SwiftUI 독립 화면"].exists)
        XCTAssertTrue(app.buttons["SwiftUI 단일 화면"].exists)
    }

    func testNavigationTitleExists() {
        XCTAssertTrue(app.navigationBars["게시판 접근성 테스트"].exists)
    }
}
