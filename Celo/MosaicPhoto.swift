//
//  MosaicPhoto.swift
//  MosaicPhotoGallery
//
//  Created by Santanu Karar on 14/03/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import Foundation
import FastImageCache

let FICDPhotoImageFormatFamily = "FICDPhotoImageFormatFamily";
let FICDPhotoSquareImage16BitBGRFormatName = "com.path.FastImageCacheDemo.FICDPhotoSquareImage16BitBGRFormatName";

class MosaicPhoto: NSObject
{
    var sourceImageURL: URL!
    var sourceVideoURL: URL!
    var sourceThumbURL: URL!
    var caption:String!
    var type:PHAssetMediaType!
    
    fileprivate var _UUID: String!
    
    lazy var sourceImage: UIImage! =
    {   [unowned self] in
        var simg = UIImage(contentsOfFile: (self.type == PHAssetMediaType.image ? self.sourceImageURL.path : self.sourceThumbURL.path))
        return simg
    }()
}

extension MosaicPhoto: FICEntity
{
    /**
     A string that uniquely identifies this entity.
     
     @discussion Within each image table, each entry is identified by an entity's UUID. Ideally, this value should never change for an entity. For example, if your entity class is a person
     model, its UUID might be an API-assigned, unchanging, unique user ID. No matter how the properties of the person change, its user ID should never change.
     */
    @objc(UUID) var uuid: String!
    {
        if _UUID == nil
        {
            // MD5 hashing is expensive enough that we only want to do it once
            // in case of video, since FICDSquareImageFromImage() needs an image file rather than video file
            // we shall continue using thumb image
            let imageName: String = type == PHAssetMediaType.image ? sourceImageURL.lastPathComponent : sourceThumbURL.lastPathComponent
            let UUIDBytes: CFUUIDBytes = FICUUIDBytesFromMD5HashOfString(imageName)
            _UUID = FICStringWithUUIDBytes(UUIDBytes)
        }
        
        return _UUID;
    }
    
    internal var sourceImageUUID: String
    {
        return self.uuid
    }
    
    func sourceImageURL(withFormatName formatName: String!) -> URL!
    {
        return (type == PHAssetMediaType.image ? sourceImageURL : sourceThumbURL)
    }
    
    func drawingBlock(for image: UIImage!, withFormatName formatName: String!) -> FICEntityImageDrawingBlock!
    {
        let drawingBlock: FICEntityImageDrawingBlock = {
            (contextRef, contextSize) in
            
            var contextBound = CGRect.zero
            contextBound.size = contextSize
            contextRef?.clear(contextBound)
            
            contextRef!.setFillColor(UIColor.white.cgColor)
            contextRef!.fill(contextBound)
            
            let squareImage: UIImage = image.FICDSquareImageFromImage()
            
            UIGraphicsPushContext(contextRef!)
            squareImage.draw(in: contextBound)
            UIGraphicsPopContext();
        }
        
        return drawingBlock
    }
}

extension UIImage
{
    func FICDSquareImageFromImage() -> UIImage
    {
        var squareImage: UIImage
        let imageSize: CGSize = self.size
        
        if imageSize.width == imageSize.height
        {
            squareImage = self
        }
        else
        {
            // Compute square crop rect
            let smallerDimension: CGFloat = min(imageSize.width, imageSize.height)
            var cropRect: CGRect = CGRect(x: 0, y:0, width: smallerDimension, height: smallerDimension)
            
            // Center the crop rect either vertically or horizontally, depending on which dimension is smaller
            if imageSize.width <= imageSize.height
            {
                cropRect.origin = CGPoint(x: 0, y: rintf(((imageSize.height - smallerDimension) / CGFloat(2)).float).cgFloat)
            }
            else
            {
                cropRect.origin = CGPoint(x: rintf(((imageSize.height - smallerDimension) / CGFloat(2)).float).cgFloat, y: 0);
            }
            
            let croppedImageRef: CGImage = self.cgImage!.cropping(to: cropRect)!
            squareImage = UIImage(cgImage: croppedImageRef)
        }
        
        return squareImage;
    }
}

extension Float
{
    var cgFloat: CGFloat { return CGFloat(self) }
}

extension CGFloat
{
    var float: Float { return Float(self) }
}
