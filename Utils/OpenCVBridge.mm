#import "OpenCVBridge.h"

// Define NO_PRECOMPILED_HEADERS to avoid issues with Xcode header maps
#ifdef __cplusplus
#undef NO
#undef YES
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>
#endif

@implementation OpenCVBridge

+ (UIImage *)applyBilateralFilter:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    
    // cv::Mat is normally RGBA from UIImageToMat
    cv::Mat rgb;
    cv::cvtColor(src, rgb, cv::COLOR_RGBA2RGB);
    
    cv::Mat dst;
    // d=9, sigmaColor=75, sigmaSpace=75 are good defaults for noise reduction while keeping edges
    cv::bilateralFilter(rgb, dst, 9, 75, 75);
    
    cv::Mat result;
    cv::cvtColor(dst, result, cv::COLOR_RGB2RGBA);
    
    return MatToUIImage(result);
}

+ (UIImage *)generateFloodMask:(UIImage *)image
                     atPoint:(CGPoint)point
                   tolerance:(CGFloat)tolerance {
    cv::Mat src;
    UIImageToMat(image, src);
    
    cv::Mat rgb;
    if (src.channels() == 4) {
        cv::cvtColor(src, rgb, cv::COLOR_RGBA2RGB);
    } else {
        rgb = src.clone();
    }
    
    int width = rgb.cols;
    int height = rgb.rows;
    
    // Convert point to pixel coordinates
    cv::Point seedPoint(static_cast<int>(point.x), static_cast<int>(point.y));
    if (seedPoint.x < 0 || seedPoint.x >= width || seedPoint.y < 0 || seedPoint.y >= height) {
        return nil;
    }
    
    // 0-255 tolerance
    double tol = static_cast<double>(tolerance);
    cv::Scalar lowDiff(tol, tol, tol);
    cv::Scalar upDiff(tol, tol, tol);
    
    // Flood fill mask must be 2 pixels wider/taller than source
    cv::Mat mask = cv::Mat::zeros(height + 2, width + 2, CV_8UC1);
    
    // We use cv::FLOODFILL_MASK_ONLY to only update the mask
    // 255 is the color to fill in the mask
    cv::floodFill(rgb, mask, seedPoint, cv::Scalar(255, 255, 255), 0, lowDiff, upDiff, 4 | cv::FLOODFILL_MASK_ONLY | (255 << 8));
    
    // Extract the internal part of the mask (remove the 1px border)
    cv::Mat finalMask = mask(cv::Range(1, height + 1), cv::Range(1, width + 1)).clone();
    
    return MatToUIImage(finalMask);
}

@end
