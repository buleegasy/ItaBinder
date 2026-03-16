#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Objective-C++ bridge for OpenCV functionality.
@interface OpenCVBridge : NSObject

/// Applies a bilateral filter to smooth the image while preserving edges.
/// Useful for pre-processing before flood fill or extraction.
+ (UIImage *)applyBilateralFilter:(UIImage *)image;

/// Performs a high-precision flood fill to generate a mask.
/// @param image The source image.
/// @param point The seed point in image coordinates.
/// @param tolerance Color difference tolerance (0-255 scale recommended for CV).
+ (UIImage *)generateFloodMask:(UIImage *)image
                     atPoint:(CGPoint)point
                   tolerance:(CGFloat)tolerance;

@end

NS_ASSUME_NONNULL_END
