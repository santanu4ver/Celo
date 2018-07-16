//
//  AppDelegate.swift
//  Celo
//
//  Created by Santanu Karar on 09/11/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit
import CoreData
import FastImageCache

protocol AppDelegateDelegate: class
{
    func applicationWillResignToBackground()
    func applicationEnteredFromBackground()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIGestureRecognizerDelegate
{

    var window: UIWindow?
    var lpg: UILongPressGestureRecognizer!
    
    weak var delegate: AppDelegateDelegate!
    
    fileprivate var blackUI: UIView!
    fileprivate var btnRestore: UIButton!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // fastImage cache config
        let mutableImageFormats = NSMutableArray()
        
        //let squareImageFormatDevices = FICImageFormatDevices.Phone | FICImageFormatDevices.Pad;
        var squareImageFormatDevices = FICImageFormatDevices.phone;
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        {
            squareImageFormatDevices = FICImageFormatDevices.pad;
        }
        
        var squareImageSize = MosaicPhotoSquareImageSizeNonRetina
        if UIScreen.isRetina
        {
            squareImageSize = MosaicPhotoSquareImageSizeRetina
        }
        
        // ...16-bit BGR
        let squareImageFormat16BitBGR: FICImageFormat = FICImageFormat(name: FICDPhotoSquareImage16BitBGRFormatName, family: FICDPhotoImageFormatFamily, imageSize: squareImageSize, style: FICImageFormatStyle.style16BitBGR, maximumCount: 400, devices: squareImageFormatDevices, protectionMode: FICImageFormatProtectionMode.none)
        mutableImageFormats.add(squareImageFormat16BitBGR)
        
        // Configure the image cache
        let sharedImageCache = FICImageCache.shared()
        sharedImageCache?.delegate = self
        sharedImageCache?.setFormats(mutableImageFormats as [AnyObject])
        
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
        if ((ConstantsVO.isInLoginState || ConstantsVO.isLoginFormOpen) && !ConstantsVO.isImportWindowOpened && !ConstantsVO.isAppTurnToComa)
        {
            self.gotoComa()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        if ConstantsVO.isAppTurnToComa
        {
            // add only when the button is not already added
            if (self.btnRestore == nil)
            {
                self.addQuarantineButton()
            }
            ConstantsVO.isAppTurnToComa = false
        }
    }
    
    func gotoComa(_ addRevive:Bool=false)
    {
        // @modified in Version 2.0
        // only a black UI covering the screen
        blackUI = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        blackUI.backgroundColor = UIColor.black
        blackUI.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        self.window?.addSubview(blackUI)
        
        ConstantsVO.isAppTurnToComa = true
        
        // attach Revive button if necessary
        if addRevive
        {
            addQuarantineButton()
        }
    }
    
    func addQuarantineButton()
    {
        if blackUI != nil
        {
            // also attach a button to release black UI
            btnRestore = UIButton()
            btnRestore.setTitle("REVIVE", for: UIControlState())
            btnRestore.backgroundColor = UIColor.darkGray
            btnRestore.setCornerRadius(7.0)
            btnRestore.addTarget(self, action: #selector(AppDelegate.onRevive), for: UIControlEvents.touchUpInside)
            blackUI.addSubview(btnRestore)
            
            btnRestore.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 9.0, *)
            {
                btnRestore.centerXAnchor.constraint(equalTo: blackUI.centerXAnchor, constant: 0).isActive = true
                btnRestore.centerYAnchor.constraint(equalTo: blackUI.centerYAnchor, constant: 0).isActive = true
                btnRestore.leadingAnchor.constraint(equalTo: blackUI.leadingAnchor, constant: 100).isActive = true
                btnRestore.trailingAnchor.constraint(equalTo: blackUI.trailingAnchor, constant: -100).isActive = true
            }
            else
            {
                blackUI.addConstraint(NSLayoutConstraint(item: btnRestore, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: blackUI, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 100))
                blackUI.addConstraint(NSLayoutConstraint(item: btnRestore, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: blackUI, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: -100))
                blackUI.addConstraint(NSLayoutConstraint(item: btnRestore, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: blackUI, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
                blackUI.addConstraint(NSLayoutConstraint(item: btnRestore, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: blackUI, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
            }
            
            /*lpg = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
             lpg.delegate = self
             lpg.minimumPressDuration = 2.0
             lpg.numberOfTouchesRequired = 2
             self.window?.addGestureRecognizer(lpg)*/
        }
    }
    
    func onRevive()
    {
        DispatchQueue.main.async
            {
                if ConstantsVO.isInLoginState && !ConstantsVO.isImportWindowOpened
                {
                    self.delegate.applicationWillResignToBackground()
                    self.delegate = nil
                }
                else if ConstantsVO.isLoginFormOpen
                {
                    self.delegate.applicationWillResignToBackground()
                }
                
                ConstantsVO.isImportWindowOpened = false
                
                // remove background in a slight delay
                // This requires to hide any user screen visibility
                // when any popover screen may closing
                UIView.animate(withDuration: 0.5, animations:
                    {
                        self.btnRestore.alpha = 0
                })
                
                let delay = 0.5 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time)
                {
                    self.blackUI.removeFromSuperview()
                    self.blackUI = nil
                    self.btnRestore = nil
                }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    func handleLongPress(_ sender:UILongPressGestureRecognizer)
    {
        if sender.state == UIGestureRecognizerState.ended
        {
            self.window?.removeGestureRecognizer(self.lpg)
            self.window?.subviews[(self.window?.subviews.count)!-1].removeFromSuperview()
        }
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Celo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func getContext () -> NSManagedObjectContext
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension AppDelegate: FICImageCacheDelegate
{
    // Images typically come from the Internet rather than from the app bundle directly, so this would be the place to fire off a network request to download the image.
    // For the purposes of this demo app, we'll just access images stored locally on disk.
    func imageCache(_ imageCache: FICImageCache!, wantsSourceImageFor entity: FICEntity!, withFormatName formatName: String!, completionBlock: FICImageRequestCompletionBlock!)
    {
        DispatchQueue.global(qos: .default).async
            {
                let sourceImage: UIImage = (entity as! MosaicPhoto).sourceImage
                DispatchQueue.main.async
                    {
                        completionBlock(sourceImage)
                }
        }
    }
    
    func imageCache(_ imageCache: FICImageCache!, shouldProcessAllFormatsInFamily formatFamily: String!, for entity: FICEntity!) -> Bool
    {
        return false
    }
    
    func imageCache(_ imageCache: FICImageCache!, errorDidOccurWithMessage errorMessage: String!)
    {
        print(errorMessage)
    }
}
