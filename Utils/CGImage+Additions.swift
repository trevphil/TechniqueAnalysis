//
//  CGImage+Additions.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/27/19.
//

import Foundation

extension CGImage {

    var asPixelBuffer: CVPixelBuffer? {
        let image = UIImage(cgImage: self)
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(image.size.width),
                                         Int(image.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer = pixBuffer else {
            return nil
        }

        let flags = CVPixelBufferLockFlags(rawValue: 0)
        CVPixelBufferLockBaseAddress(pixelBuffer, flags)
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

        guard let context = CGContext(data: pixelData,
                                      width: Int(image.size.width),
                                      height: Int(image.size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                                        return nil
        }

        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, flags)

        return pixelBuffer
    }

}
