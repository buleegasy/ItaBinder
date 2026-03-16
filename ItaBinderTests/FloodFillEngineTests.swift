import XCTest
import UIKit
@testable import ItaBinder

final class FloodFillEngineTests: XCTestCase {
    
    var engine: FloodFillEngine!
    
    override func setUp() {
        super.setUp()
        engine = FloodFillEngine()
    }
    
    func testBilateralFilter() {
        // Create a dummy image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let inputImage = image else {
            XCTFail("Failed to create test image")
            return
        }
        
        let filteredImage = engine.applyBilateralFilter(to: inputImage)
        XCTAssertNotNil(filteredImage)
        XCTAssertEqual(filteredImage.size.width, inputImage.size.width)
        XCTAssertEqual(filteredImage.size.height, inputImage.size.height)
    }
    
    func testOpenCVFloodFill() {
        // Create a test image with a white square on black background
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.black.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 25, y: 25, width: 50, height: 50))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let inputImage = image else {
            XCTFail("Failed to create test image")
            return
        }
        
        // Seed point inside the white square
        let seedPoint = CGPoint(x: 50, y: 50)
        let mask = engine.generateFloodMask(from: inputImage, seedPoint: seedPoint, tolerance: 0.1, engine: .openCV)
        
        XCTAssertNotNil(mask)
        // Note: OpenCV mask results might be 8-bit single channel, which MatToUIImage handles
    }
}
