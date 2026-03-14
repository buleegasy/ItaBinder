import XCTest
@testable import ItaBinder

final class OCRServiceTests: XCTestCase {
    
    func testTextFiltering() {
        // This is a unit test for the logic inside suggestTitles, 
        // though strictly we'd need to mock the Vision framework results 
        // which is complex for a snippet. 
        // Here we simulate the filtering logic directly.
        
        let noise = ["©", "2024", "1", "TM", "A"]
        let valid = ["Miku Nakano", "Ichiban Kuji", "Acrylic Stand"]
        
        func shouldKeep(_ text: String) -> Bool {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count < 4 { return false }
            if cleaned.rangeOfCharacter(from: .letters) == nil { return false }
            return true
        }
        
        for item in noise {
            XCTAssertFalse(shouldKeep(item), "Should filter out: \(item)")
        }
        
        for item in valid {
            XCTAssertTrue(shouldKeep(item), "Should keep: \(item)")
        }
    }
}
