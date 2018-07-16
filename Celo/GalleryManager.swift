//
//  GalleryController.swift
//  Celo
//
//  Created by Santanu Karar on 21/09/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import Foundation
import CoreData
import CTAssetsPickerController

typealias GalleryItemWithCoreKey = Dictionary<MosaicPhoto, GalleryInstance>
typealias GalleryItems = [MosaicPhoto]
typealias StartSavingProcessHandler = (_ url:String?, _ name:String?, _ success: Bool) -> Void
typealias OneDriveAuthHandler = (_ success: Bool, _ client: AnyObject?, _ item: AnyObject?) -> Void

let pendingOperations = PendingOperation()

protocol GalleryManagerDelegate: class
{
    func galleryUpdated()
    func galleryReleased()
}

//--------------------------------------------------------------------------
//
//  METHODS
//
//--------------------------------------------------------------------------

class GalleryManager: NSObject
{
    lazy var progressManager = ProgressHUDManager()
    lazy var otherFiles = [String]()
    
    weak var context: NSManagedObjectContext?
    weak var delegate: GalleryManagerDelegate!
    
    fileprivate var list: GalleryItems!
    fileprivate var listThumbs: GalleryItems!
    fileprivate var listTable: GalleryItemWithCoreKey!
    fileprivate var selections: [Bool]!
    fileprivate var queue: OperationQueue!
    fileprivate var assetRecordCount = 0
    fileprivate var currentRecordCount = 0
    fileprivate var totalThumbCount = 0
    fileprivate var currentThumbCount = 0
    fileprivate var currentAssets: [PHAsset]!
    fileprivate var progressPercent: CGFloat = 0
    fileprivate var completionPercent: CGFloat!
    
    class func createLocalDirectory()
    {
        // we want termination if folder url already loaded
        if (ConstantsVO.celoPath != nil)
        {
            return
        }
        
        let docuPath:URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0])
        ConstantsVO.celoPath = docuPath.appendingPathComponent(!ConstantsVO.isLoggedInAsGuest ? "celogallery" : "celogalleryguest")
        ConstantsVO.thumbPath = ConstantsVO.celoPath.appendingPathComponent("thumbs")
        ConstantsVO.othersPath = ConstantsVO.celoPath.appendingPathComponent("others")
        
        if !FileManager.default.fileExists(atPath: ConstantsVO.celoPath.path)
        {
            do
            {
                try FileManager.default.createDirectory(atPath: ConstantsVO.celoPath.path, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(atPath: ConstantsVO.thumbPath.path, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(atPath: ConstantsVO.othersPath.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                NSLog("\(error.localizedDescription)")
            }
            catch
            {
                print("general error - \(error)", terminator: "\n")
            }
            
            //print(NSFileManager.defaultManager().isWritableFileAtPath(ConstantsVO.celoPath!))
            // we don't want this folder to be backup to icloud
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try! ConstantsVO.celoPath.setResourceValues(resourceValues)
        }
    }
    
    class func destroyExistings()
    {
        // this requires to determine the path if user
        // 1. starts the app
        // 2. came to the login screen
        // 3. wants to remove existing without logged in once
        if ConstantsVO.celoPath == nil
        {
            let docuPath:URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0])
            ConstantsVO.celoPath = docuPath.appendingPathComponent("celogallery")
        }
        
        // remove folders
        if ConstantsVO.celoPath != nil
        {
            do
            {
                try FileManager.default.removeItem(at: ConstantsVO.othersPath != nil ? ConstantsVO.othersPath : URL(fileURLWithPath: "others"))
            }
            catch
            {
                print("general error - \(error)", terminator: "\n")
            }
            do
            {
                try FileManager.default.removeItem(at: ConstantsVO.thumbPath != nil ? ConstantsVO.thumbPath : URL(fileURLWithPath: "thumbs"))
            }
            catch
            {
                print("general error - \(error)", terminator: "\n")
            }
            do
            {
                try FileManager.default.removeItem(at: ConstantsVO.celoPath as URL)
            }
            catch
            {
                print("general error - \(error)", terminator: "\n")
            }
        }
        
        // remove path value
        ConstantsVO.celoPath = nil
        
        // reset configuration coredata
        ConstantsVO.celoConfiguration.resetEverything()
        try! UIApplication.getManagedContext()?.save()
        
        // delete items coredata
        UIApplication.clearCoreData(!ConstantsVO.isLoggedInAsGuest ? "GalleryInstance" : "GalleryInstanceGuest")
    }
    
    func showProgress(_ overView:UIView, withType:HUDType, withTitle:String)
    {
        if !progressManager.isProcessing
        {
            switch withType
            {
            case .HUDTypePie:
                progressManager.showHUDWithMixProgressItems(overView, withTitle:withTitle)
            case .HUDTypeLabel:
                progressManager.showHUDWithTitleOnly(overView, withTitle:withTitle)
            }
        }
    }
    
    func endProgress()
    {
        if progressManager.isProcessing
        {
            progressManager.setFinish()
        }
    }

    func loadGalleryForImages(_ loadType:PHAssetMediaType, finishHandler:() -> Void)
    {
        list = GalleryItems()
        listThumbs = GalleryItems()
        listTable = GalleryItemWithCoreKey()
        totalThumbCount = 0
        currentThumbCount = 0
        
        // get saved item list from coredata
        let userConfigurationType: String = !ConstantsVO.isLoggedInAsGuest ? "GalleryInstance" : "GalleryInstanceGuest"
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: userConfigurationType)
        var getItems = [GalleryInstance]()
        do
        {
            getItems = try context?.fetch(fetchRequest) as! [GalleryInstance]
        }
        catch let error as NSError
        {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        getItems = getItems.filter{ $0.type == loadType.stringValue}
        totalThumbCount = getItems.count
        
        for item in getItems
        {
            let tmpImgeURL = URL(fileURLWithPath: (ConstantsVO.celoPath.path) + "/" + item.url)
            var photo: MosaicPhoto!
            
            if loadType == PHAssetMediaType.image
            {
                photo = MosaicPhoto()
                photo.sourceImageURL = tmpImgeURL
            }
            else if loadType == PHAssetMediaType.video
            {
                photo = MosaicPhoto()
                photo.sourceVideoURL = tmpImgeURL
            }
            
            var tmpName:String = item.url
            if (item.type == PHAssetMediaType.video.stringValue)
            {
                var splitItems = item.url.components(separatedBy: ".")
                _ = splitItems.popLast()
                tmpName = splitItems.joined(separator: ".") + ".jpg"
            }
            
            photo.sourceThumbURL = URL(fileURLWithPath: (ConstantsVO.thumbPath.path) + "/" + tmpName)
            photo.type = loadType
            photo.caption = item.url
            list.append(photo)
            
            // asynchronous thumb generation
            /*let saver = ThumbGenerator(photoRecord: item)
            saver.completionBlock = {
                if saver.cancelled {
                    return
                }
                
                self.currentThumbCount++
                for (index, value) in pendingOperations.savingInProgress.enumerate()
                {
                    if value === saver
                    {
                        photo = MWPhoto(image: saver.thumb)
                        self.listThumbs.append(photo)
                        
                        // remove footprint
                        pendingOperations.savingInProgress.removeAtIndex(index)
                        break
                    }
                }
                
                // say complete to caller
                if self.totalThumbCount == self.currentThumbCount
                {
                    finishHandler()
                }
            }
            
            pendingOperations.savingInProgress.append(saver)
            pendingOperations.savingQueue.addOperation(saver)*/
            
            // keep the coreData reference to delete
            // when the photo assets been deleted
            listTable[photo] = item
        }
        
        // probable termination if type of item is empty
        if totalThumbCount == 0
        {
            finishHandler()
        }
        
        selections = [Bool]()
        for _ in list.enumerated() {
            selections.append(false)
        }
        
        finishHandler()
    }
    
    func getOthersItems(_ finishHandler:(_ hasUpdate:Bool) -> Void)
    {
        var files = [String]()
        var hasNewFile = false
        let docuPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        do {
            files = try FileManager.default.contentsOfDirectory(atPath: docuPath)
        } catch {
            print(error)
        }
        
        // lets check first if any new files requires to be copied
        for file:String in files
        {
            let fileURLextension = NSURL(fileURLWithPath: file).pathExtension?.lowercased()
            if (fileURLextension == OthersType.Doc.rawValue) || (fileURLextension == OthersType.PDF.rawValue) || (fileURLextension == OthersType.RTF.rawValue) || (fileURLextension == OthersType.TXT.rawValue)
            {
                if FileManager.default.fileExists(atPath: ConstantsVO.othersPath.path)
                {
                    let moveToPath = ConstantsVO.othersPath.path + ("/" + file)
                    let fromPath = docuPath + ("/" + file)
                    try! FileManager.default.moveItem(atPath: fromPath, toPath: moveToPath)
                    hasNewFile = true
                }
            }
        }
        
        // old files those exists in managed folder
        self.otherFiles = [String]()
        do {
            self.otherFiles = try FileManager.default.contentsOfDirectory(atPath: ConstantsVO.othersPath.path)
        } catch {
            print(error)
        }
        
        // return everything
        finishHandler(hasNewFile)
    }
    
    func suspendAllOperations ()
    {
        pendingOperations.savingQueue.isSuspended = true
    }
    
    func resumeAllOperations ()
    {
        pendingOperations.savingQueue.isSuspended = false
    }
    
    func updateToGallery(_ assets:[PHAsset])
    {
        var lastRequest: StartSavingProcess!
        var opertions = [AnyObject]()
        var assetRecords = [AssetRecord]()
        
        progressPercent = CGFloat(1 / Float(assets.count))
        completionPercent = progressPercent
        currentAssets = nil
        currentRecordCount = 0
        assetRecordCount = 0
        
        for (index, item) in assets.enumerated()
        {
            let shallStartInMain = index == 0 ? true : false
            // NSOperation queue 1
            lastRequest = StartSavingProcess(item: item, completionHandler: { (url, name, success) -> Void in
                
                assetRecords.append(AssetRecord(url: url!, item: item, name: name!))
                if index == assets.count-1
                {
                    self.assetRecordCount = assets.count
                    if (ConstantsVO.celoConfiguration.isRemoveAfterImport)
                    {
                        self.currentAssets = assets // store this only if user selected 'delete after import' option
                    }
                    for record in assetRecords
                    {
                        // NSOperation queue 2
                        self.startOperationsForSaveRecordData(record)
                    }
                }
                
                }, startInMainThread: shallStartInMain)
            opertions.append(lastRequest)
        }
        
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "save_all_randomobjects"
        queue.addOperations(opertions as! [Foundation.Operation], waitUntilFinished: false)
        
        // mark that user once imported something
        if !ConstantsVO.isUserImportedForFirstTime
        {
            ConstantsVO.isUserImportedForFirstTime = true
            UserDefaults.standard.set(true, forKey: "isUserImportedForFirstTime")
        }
    }
    
    func startOperationsForSaveRecordData(_ recordDetails: AssetRecord)
    {
        switch (recordDetails.state) {
        case .new:
            startDownloadRecordData(recordDetails)
        /*case .Downloaded:
            startFiltrationForRecord(photoDetails, indexPath: indexPath)*/
        default:
            NSLog("do nothing")
        }
    }
    
    func startDownloadRecordData(_ recordDetails: AssetRecord)
    {
        let saver = AssetSaver(photoRecord: recordDetails)
        saver.completionBlock = {
            self.currentRecordCount += 1
            if saver.isCancelled {
                return
            }
            DispatchQueue.main.async(execute: {
                self.progressManager.setProgress(self.completionPercent)
                self.completionPercent = self.completionPercent + self.progressPercent

                for (index, value) in pendingOperations.savingInProgress.enumerated()
                {
                    if value === saver
                    {
                        // save locally to determine userID vs. upVote or downVoted
                        let localVote = NSEntityDescription.insertNewObject(forEntityName: !ConstantsVO.isLoggedInAsGuest ? "GalleryInstance" : "GalleryInstanceGuest", into: self.context!) as! GalleryInstance
                        localVote.url = saver.assetRecord.name
                        localVote.type = saver.assetRecord.type.stringValue
                        localVote.timestamp = Date().timeIntervalSince1970 as NSNumber

                        do {
                            try self.context?.save()
                        } catch _ {
                        }
                        
                        // remove footprint
                        pendingOperations.savingInProgress.remove(at: index)
                        break
                    }
                }
                
                // remove assets from gallery
                // if selected the option by user
                if (ConstantsVO.celoConfiguration.isRemoveAfterImport) && (self.assetRecordCount == self.currentRecordCount)
                {
                    ConstantsVO.isImportWindowOpened = true
                    PHPhotoLibrary.shared().performChanges({ () -> Void in
                        PHAssetChangeRequest.deleteAssets(self.currentAssets as NSFastEnumeration)
                        }, completionHandler: { (success, error) -> Void in
                            self.currentAssets = nil
                            ConstantsVO.isImportWindowOpened = false
                    })
                }
                if self.assetRecordCount == self.currentRecordCount
                {
                    // We also need to satisfy that duplicate item import
                    // do not creates duplicate item as that would create
                    // many other problems during removing the entry
                    let userConfigurationType: String = !ConstantsVO.isLoggedInAsGuest ? "GalleryInstance" : "GalleryInstanceGuest"
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: userConfigurationType)
                    var getItems = [GalleryInstance]()
                    do
                    {
                        getItems = try self.context?.fetch(fetchRequest) as! [GalleryInstance]
                    }
                    catch let error as NSError
                    {
                        // failure
                        print("Fetch failed: \(error.localizedDescription)")
                    }
                    
                    // sort it first
                    getItems.sort(by: { $0.url > $1.url })
                    // remove it consecutive items now
                    var lastURL = ""
                    for aItem in getItems
                    {
                        if lastURL == aItem.url
                        {
                            self.context?.delete(aItem)
                        }
                        else
                        {
                            lastURL = aItem.url
                        }
                    }
                    // saving coredata
                    do {
                        try self.context?.save()
                    } catch _ {
                    }
                    
                    self.progressManager.setFinish()
                }
            })
        }
        
        pendingOperations.savingInProgress.append(saver)
        pendingOperations.savingQueue.addOperation(saver)
    }
    
    func removeAssets(_ items:[Int], onCompletion:@escaping () -> Void)
    {
        let fileManager = FileManager.default
        DispatchQueue.main.async
        {
            // removal from device drive
            for index in items
            {
                let tmpImgeURL = (ConstantsVO.celoPath.path) + "/" + self.listTable[self.list[index]]!.url
                let tmpThumbURL = (ConstantsVO.thumbPath.path) + "/" + self.listTable[self.list[index]]!.url
                do {
                    try fileManager.removeItem(atPath: tmpImgeURL)
                    try fileManager.removeItem(atPath: tmpThumbURL)
                } catch _ {
                    print("Caught in error")
                }
                self.context?.delete(self.listTable[self.list[index]]!)
                self.listTable.removeValue(forKey: self.list[index])
            }
            
            // saving coredata
            do {
                try self.context?.save()
            } catch _ {
            }
            
            // updating current list and ui
            var offset = 0
            for index2 in items
            {
                self.list.remove(at: index2-offset)
                //self.listThumbs.removeAtIndex(index2-offset)
                self.selections.remove(at: index2-offset)
                offset += 1
            }
            onCompletion()
        }
    }
    
    func dispose()
    {
        list = GalleryItems()
        listThumbs = GalleryItems()
        listTable = GalleryItemWithCoreKey()
        selections = [Bool]()
        queue = nil
        assetRecordCount = 0
        currentRecordCount = 0
        totalThumbCount = 0
        currentThumbCount = 0
        currentAssets = nil
        
        delegate.galleryReleased()
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @CTAssetsPickerController
//
//--------------------------------------------------------------------------

extension GalleryManager: CTAssetsPickerControllerDelegate
{
    func assetsPickerController(_ picker: CTAssetsPickerController!, didFinishPickingAssets assets: [Any]!)
    {
        picker.dismiss(animated: true, completion: nil)
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @MosaicViewController
//
//--------------------------------------------------------------------------

extension GalleryManager: MosaicViewControllerDelegate
{
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: MosaicViewController?) -> Int
    {
        return list.count
    }
    
    func photoBrowser(_ photoBrowser: MosaicViewController!, photoAtIndex index: Int) -> MosaicPhoto!
    {
        if index < list.count
        {
            return list[index]
        }
        
        return nil
    }
    
    func photoBrowser(_ photoBrowser: MosaicViewController!, didDisplayPhotoAtIndex index: Int)
    {
        print("Photo Displaying on index: \(index)")
    }
    
    func photoBrowser(_ photoBrowser: MosaicViewController!, isPhotoSelectedAtIndex index: Int) -> Bool
    {
        if selections.count == 0
        {
            return false
        }
        return selections[index]
    }
    
    func photoBrowser(_ photoBrowser: MosaicViewController!, photoAtIndex index: Int, selectedChanged selected: Bool)
    {
        selections[index] = selected
    }
    
    func photoBrowser(_ reOrderFrom:Int, reOrderTo:Int)
    {
        let image = list[reOrderFrom]
        list.remove(at: reOrderFrom)
        list.insert(image, at: reOrderTo)
    }
    
    func getGalleryItems() -> GalleryItems
    {
        return list
    }
    
    func getSelectionsArray() -> [Bool]
    {
        return selections
    }
    
    func resetSelectedItems()
    {
        for (index, _) in selections.enumerated()
        {
            selections[index] = false
        }
    }
    
    func deleteSelectedItems(_ onCompletion:@escaping () -> Void)
    {
        let selectedItems = getSelectedItems()
        removeAssets(selectedItems, onCompletion: onCompletion)
    }
    
    func photoBrowserDidFinishModalPresentation(_ photoBrowser: MosaicViewController!)
    {
        //self.dismissViewControllerAnimated(true, completion: nil)
        self.dispose()
    }
    
    func photoBrowser(_ photoBrowser: MosaicViewController!, onEditActionButtonPressed value: String!, withClient client: AnyObject!)
    {
        //let selectedItems = getSelectedItems()
        
        switch(value)
        {
        case "Delete":
            //removeAssets(selectedItems, () -> ())
            print("")
        default:
            // probable termination
            print("")
        }
    }
    
    func orientationChanged(_ isLandscape: Bool)
    {
        ConstantsVO.isLandscape = isLandscape
    }
    
    func cloudDriveOpens(_ isOpen: Bool)
    {
        ConstantsVO.isImportWindowOpened = isOpen
    }
    
    func getSelectionCount() -> Int32
    {
        let selectedItems = getSelectedItems()
        return Int32(selectedItems.count)
    }
    
    func oneDriveDisclaimerAccepted()
    {
        ConstantsVO.isUserAcceptedClouodDisclaimer = true
        UserDefaults.standard.set(true, forKey: "isUserAcceptedClouodDisclaimer")
    }
    
    func isConnectedToNetwork() -> Bool
    {
        return GenericControls.isConnectedToNetwork()
    }
    
    fileprivate func getSelectedItems() -> [Int]
    {
        var selectedItems = [Int]()
        for (index, value) in selections.enumerated()
        {
            if value
            {
                selectedItems.append(index)
            }
        }
        
        return selectedItems
    }
}

//--------------------------------------------------------------------------
//
//  CLASS
//  @NSOperation
//
//--------------------------------------------------------------------------

class StartSavingProcess: Operation
{
    fileprivate var asset: PHAsset!
    fileprivate var handler: StartSavingProcessHandler!
    
    init(item:PHAsset, completionHandler:@escaping StartSavingProcessHandler, startInMainThread:Bool=false)
    {
        super.init(startOnMainThread: startInMainThread, finishInMain: false)
        self.handler = completionHandler
        self.asset = item
        self.name = "saverequest"
    }
    
    override func start()
    {
        super.start()

        asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler:
        { (input, _) in
            
            let name = self.asset.value(forKey: "filename") as! String
            let tmpImgeURL = (ConstantsVO.celoPath.path) + "/" + name
            self.handler(tmpImgeURL, name, true)
            
            self.finish()
                
        })
    }
    
    override func cancel()
    {
        super.cancel()
    }
}

//--------------------------------------------------------------------------
//
//  CLASS
//  @NSOperation
//
//--------------------------------------------------------------------------

class StartCopyingProcess: Operation
{
    init(item:PHAsset, completionHandler:StartSavingProcessHandler, startInMainThread:Bool=false)
    {
        super.init(startOnMainThread: startInMainThread, finishInMain: false)
        self.name = "copyrequest"
    }
    
    override func start()
    {
        super.start()
    }
    
    override func cancel()
    {
        super.cancel()
    }
}
