//
//  GalleryController.swift
//  Celo
//
//  Created by Santanu Karar on 21/09/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import Foundation
import CoreData

protocol BackgroundImageManagerDelegate: class
{
    func backgroundImagesUpdated(_ paths:[String])
    func backgroundRemoved()
    func backgroundImageWindowCancelled()
}

//--------------------------------------------------------------------------
//
//  METHODS
//
//--------------------------------------------------------------------------

class BackgroundImageManager: NSObject
{
    weak var delegate: BackgroundImageManagerDelegate!
    
    fileprivate var queue: OperationQueue!
    fileprivate var assetRecordCount = 0
    fileprivate var currentRecordCount = 0
    fileprivate var progressPercent: CGFloat = 0
    fileprivate var completionPercent: CGFloat!
    fileprivate var backgroundAssets = [String]()
    
    func updateToBackground(_ assets:[MosaicPhoto])
    {
        var lastRequest: StartBackgroundSavingProcess!
        var opertions = [AnyObject]()
        
        progressPercent = CGFloat(1 / Float(assets.count))
        completionPercent = progressPercent
        currentRecordCount = 0
        assetRecordCount = 0
        backgroundAssets = [String]()
        
        for (index, item) in assets.enumerated()
        {
            let shallStartInMain = index == 0 ? true : false
            // NSOperation queue 1
            lastRequest = StartBackgroundSavingProcess(item: item, index: index, completionHandler: { (url, name, success) -> Void in
                
                self.currentRecordCount += 1
                self.backgroundAssets.append(url!)
                if assets.count == self.currentRecordCount
                {
                    self.delegate.backgroundImagesUpdated(self.backgroundAssets)
                }
                
                }, startInMainThread: shallStartInMain)
            opertions.append(lastRequest)
        }
        
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "save_all_randomobjects"
        queue.addOperations(opertions as! [Foundation.Operation], waitUntilFinished: false)
    }
    
    func backgroundImageWindowCancelled()
    {
        delegate.backgroundImageWindowCancelled()
    }
}

//--------------------------------------------------------------------------
//
//  CLASS
//  @NSOperation
//
//--------------------------------------------------------------------------

class StartBackgroundSavingProcess: Operation
{
    fileprivate var asset: MosaicPhoto!
    fileprivate var handler: StartSavingProcessHandler!
    fileprivate var countNumber:Int!
    
    init(item:MosaicPhoto, index:Int, completionHandler:@escaping StartSavingProcessHandler, startInMainThread:Bool=false)
    {
        super.init(startOnMainThread: startInMainThread, finishInMain: false)
        self.handler = completionHandler
        self.asset = item
        self.countNumber = index
        self.name = "saverequest"
    }
    
    override func start()
    {
        super.start()
        
        DispatchQueue.main.async
        {
            let fileManager = FileManager.default
            let nameArr = self.asset.sourceImageURL.path.components(separatedBy: "/")
            let name = nameArr[nameArr.count - 1]
            let count = String(self.countNumber + 1)
            let tmpImgeURL = URL(fileURLWithPath: (ConstantsVO.celoPath.path) + "/Background" + count + "." + self.asset.sourceImageURL.pathExtension)
            
            OperationQueue.main.addOperation
            {
                do {
                    try fileManager.copyItem(at: self.asset.sourceImageURL, to: tmpImgeURL)
                } catch _ {

                    print("File probably exists - trying replacing")
                    
                    // since some weird reason commented out replaceItem command
                    // was never working, thus this deletion and copying process
                    do
                    {
                        try fileManager.removeItem(at: tmpImgeURL)
                        do
                        {
                            try fileManager.copyItem(at: self.asset.sourceImageURL, to: tmpImgeURL)
                        } catch _
                        {
                            print("Copying is failing again")
                            self.cancel()
                        }
                        
                    } catch _
                    {
                        print("Background deletion failed")
                        self.cancel()
                    }
                    
                    /*do
                    {
                        try fileManager.replaceItem(at: tmpImgeURL, withItemAt: self.asset.sourceImageURL, backupItemName: nil, options: FileManager.ItemReplacementOptions.usingNewMetadataOnly, resultingItemURL: nil)
                    } catch _
                    {
                        print("Background replace failed")
                        self.cancel()
                    }*/
                }
                
                self.handler(tmpImgeURL.path, name, true)
                self.finish()
            }
        }
    }
    
    override func cancel()
    {
        super.cancel()
    }
}
