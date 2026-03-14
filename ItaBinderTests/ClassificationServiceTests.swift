import XCTest
@testable import ItaBinder

final class ClassificationServiceTests: XCTestCase {
    
    func testLabelFormatting() {
        let rawLabels = ["plastic_bottle", "person_smiling", "comic_book"]
        let expected = ["Plastic Bottle", "Person Smiling", "Comic Book"]
        
        func formatLabel(_ label: String) -> String {
            return label
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
        
        for (index, raw) in rawLabels.enumerated() {
            XCTAssertEqual(formatLabel(raw), expected[index])
        }
    }
}
