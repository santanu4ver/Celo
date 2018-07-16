//
//  PhotoOperation.swift
//  VoteYourSpider
//
//  Created by Richard Turton on 17/04/2015.
//  Copyright (c) 2015 raywenderlich. All rights reserved.
//
//  http://www.raywenderlich.com/76341/use-nsoperation-nsoperationqueue-swift
//

import Foundation

enum AssetRecordState
{
    case new, succeed, failed
}

class AssetRecord
{
    let url: String
    let name: String
    var type = PHAssetMediaType.image
    var state = AssetRecordState.new
    var item: PHAsset!
  
    init(url:String, item:PHAsset, name:String)
    {
        self.url = url
        self.item = item
        self.name = name
        self.type = item.mediaType
    }
}

class PendingOperation
{
    lazy var savingInProgress = [AssetSaver]()
    lazy var savingQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Saving queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

//--------------------------------------------------------------------------
//
//  CLASS
//  @NSOperation
//
//--------------------------------------------------------------------------

class AssetSaver: Foundation.Operation
{
    let assetRecord: AssetRecord
    let needThumbail: Bool
    lazy var phManager: PHImageManager =
    {
        return PHImageManager.default()
    }()
    lazy var phOptions: PHImageRequestOptions =
    {
        let options = PHImageRequestOptions()
        options.isSynchronous = true;
        return options
    }()

    init(photoRecord: AssetRecord, thumbnail:Bool=true)
    {
        self.assetRecord = photoRecord
        self.needThumbail = thumbnail
    }
  
    override func main()
    {
        if self.isCancelled
        {
            return
        }
        
        var success = false
        
        // for video
        if self.assetRecord.type == PHAssetMediaType.video
        {
            phManager.requestAVAsset(forVideo: self.assetRecord.item, options: nil) { (asset, audioMix, info) in
                DispatchQueue.main.async(execute: {
                    let asset = asset as? AVURLAsset
                    print("File to be written at: \(self.assetRecord.url)")
                    if let newData:NSData = NSData(contentsOf: (asset?.url)!)
                    {
                        success = newData.write(toFile: self.assetRecord.url, atomically: true)
                        if !success
                        {
                            print("general error - unable to write to file", terminator: "\n")
                            self.assetRecord.state = .failed
                        }
                        else
                        {
                            self.saveThumbnail()
                        }
                    }
                })
            }
        }
        else if self.assetRecord.type == PHAssetMediaType.image
        {
            phManager.requestImageData(for: self.assetRecord.item, options: self.phOptions)
            {
                imageData,dataUTI,orientation,info in
                
                // save actual phasset file
                print("File to be written at: \(self.assetRecord.url)")
                success = (imageData! as NSData).write(toFile: self.assetRecord.url, atomically: true)
                if !success
                {
                    print("general error - unable to write to file", terminator: "\n")
                    self.assetRecord.state = .failed
                }
                else
                {
                    self.saveThumbnail()
                }
            }
        }
    }
    
    func saveThumbnail()
    {
        if self.needThumbail
        {
            // save phasset's thumbnail file
            let option = PHImageRequestOptions()
            option.resizeMode = PHImageRequestOptionsResizeMode.exact
            option.isSynchronous = true
            self.phManager.requestImage(for: self.assetRecord.item, targetSize: CGSize(width: 200, height: 200), contentMode: PHImageContentMode.aspectFill, options: option, resultHandler: { (incomingImage, info) -> Void in
                
                print("Thumb to be written at: \(ConstantsVO.thumbPath.path + "/" + self.assetRecord.name)")
                do
                {
                    var tmpName:String = self.assetRecord.name
                    if (self.assetRecord.type == PHAssetMediaType.video)
                    {
                        var splitItems = self.assetRecord.name.components(separatedBy: ".")
                        _ = splitItems.popLast()
                        tmpName = splitItems.joined(separator: ".") + ".jpg"
                    }
                    
                    try UIImagePNGRepresentation(incomingImage!)!.write(to: URL(fileURLWithPath: ConstantsVO.thumbPath.path + "/" + tmpName), options: .atomic)
                }
                catch
                {
                    print(error)
                }
                
                if self.isCancelled
                {
                    return
                }
                
                self.assetRecord.state = .succeed
            })
        }
        else
        {
            if self.isCancelled
            {
                return
            }
            
            self.assetRecord.state = .succeed
        }
    }
}

//--------------------------------------------------------------------------
//
//  CLASS
//  @NSOperation
//
//--------------------------------------------------------------------------

class ThumbGenerator: Foundation.Operation
{
    let instance: GalleryInstance
    var state = AssetRecordState.new
    var thumb: UIImage!
    
    init(photoRecord: GalleryInstance)
    {
        self.instance = photoRecord
    }
    
    override func main()
    {
        if self.isCancelled
        {
            return
        }
        
        guard let image = UIImage(contentsOfFile: ConstantsVO.thumbPath.path + "/" + self.instance.url) else
        {
            self.state = .failed
            return
        }
        
        self.thumb = image
        self.state = .succeed
    }
}
