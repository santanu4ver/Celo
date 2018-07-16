//
//  StartViewController.swift
//  Celo
//
//  Created by Santanu Karar on 18/09/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//

import UIKit
import CTAssetsPickerController

extension PHAssetMediaType
{
    var stringValue: String
    {
        let temperatures = ["Unknown", "Image", "Video", "Audio"]
        return temperatures[self.hashValue]
    }
}

protocol CeloSectionViewController
{
    func dispose()
}

//--------------------------------------------------------------------------
//
//  METHODS
//
//--------------------------------------------------------------------------

class StartViewController: UIViewController, UINavigationControllerDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var tblContents: UITableView!
    
    let titleFont = UIFont.systemFont(ofSize: 36.0, weight: 0)
    let descriptionFont = UIFont.systemFont(ofSize: 14.0)

    var rawPoints:[Int] = []
    var recognizer:DBPathRecognizer?
    var mosaicBrowser: MosaicViewController!
    var imagesCollectionController: ImagesCollectionViewController!
    
    var isImportAsBackground = false
    var isLandscape = false
    var isBrowserAdded = false
    var isAdditionalPopoverOpen = false
    var tableHeaderViewHeight: CGFloat!
    var lpg: UILongPressGestureRecognizer!
    var dtg: UILongPressGestureRecognizer!
    var insideSections: [(name:String, icon:String)] = []
    
    fileprivate var currentSectionIndex = 0
    fileprivate var settingsItem:UIBarButtonItem!
    
    lazy var galleryManager: GalleryManager! =
    {
        var gm = GalleryManager()
        gm.delegate = self
        return gm
    }()
    lazy var backgroundManager: BackgroundImageManager! =
    {
        var bm = BackgroundImageManager()
        bm.delegate = self
        return bm
    }()
    
    fileprivate var onboardingArray:[OnboardingItemInfo]!
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        insideSections.append((name: "IMAGES", icon: "image"))
        insideSections.append((name: "MOVIES", icon: "video"))
        insideSections.append((name: "OTHERS", icon: "others"))
        
        GalleryManager.createLocalDirectory()
        currentSectionIndex = 0
        
        // usual with no background images
        onboardingArray = [("v3Image", "IMAGES", "Tap to open Celo image gallery\nLong-tap to import images from your library", UIImage.Asset.v3Image.rawValue, #colorLiteral(red: 0.66, green: 0.66, blue: 0.66, alpha: 1), UIColor.white, UIColor.white, titleFont, descriptionFont, nil),
                           ("v3Videos", "MOVIES", "Tap to open Celo video gallery\nLong-tap to import videos from your library", UIImage.Asset.v3Image.rawValue, #colorLiteral(red: 0.2731564939, green: 0.1209763363, blue: 0.4366304874, alpha: 1), #colorLiteral(red: 0.002443574136, green: 0.5319675803, blue: 1, alpha: 1), #colorLiteral(red: 0.002443574136, green: 0.5319675803, blue: 1, alpha: 1), titleFont, descriptionFont, nil),
                           ("v3Others", "OTHERS", "Tap to open everything else\nthose are may not images or videos", UIImage.Asset.v3Image.rawValue, #colorLiteral(red: 0.6068458557, green: 0.6020937562, blue: 0.4192479253, alpha: 1), UIColor.white, UIColor.white, titleFont, descriptionFont, nil)]
        
        // if background images
        // starts loading images after moving to the main view
        // and transition ends
        OperationQueue.main.addOperation
        {
            if ConstantsVO.celoConfiguration.hasBackgroundImage
            {
                for index in 1...3
                {
                    // get the image
                    let bgPath = (ConstantsVO.celoPath.path) + "/Background" + String(index) + ConstantsVO.backgroundImageExtensions[index - 1]
                    print(bgPath)
                    
                    // get local image by 'draw' to reduce file size
                    let accessedImage = UIImage(contentsOfFile: bgPath)
                    var bgImage = GenericControls.getAspectFillImageToDrawnInView(accessedImage!, sizeTo: CGRect(origin: CGPoint.init(), size: (accessedImage?.size)!))
                    bgImage = bgImage.applyBlur(withRadius: 0, tintColor: UIColor.clear, saturationDeltaFactor: 1.0, maskImage: nil)
                    self.onboardingArray[index-1].backgroundImage = bgImage
                }
                
                // send notif to PaperOnboard to change it's bgs
                NotificationCenter.default.post(name: Notification.Name(rawValue: ConstantsVO.BACKGROUND_CHANGED), object: nil)
            }
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        ConstantsVO.isInLoginState = true;
        UIApplication.getDelegate().delegate = self
        
        DispatchQueue.main.async
        {
            self.setupUI()
            self.addGestures()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        NotificationCenter.default.addObserver(self, selector: #selector(StartViewController.orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        if ConstantsVO.isLandscape != isLandscape
        {
            isLandscape = ConstantsVO.isLandscape
            self.updateHeaderViewSizeAfterOrientation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        // lets put this listener here sine we'll going to remove and
        // add the listener on every de/seague from gallery views
        addSingleLongTapGesture()
    }
    
    /**
     * Following is to fix an issue of having extra space
     * over the UITableHeaderView when background image removed,
     * and returned from gallery view to start tableviewcontroller
     */
    override func viewDidLayoutSubviews()
    {
        /*if ConstantsVO.uiEdgeInsetsTop == 0
        {
            ConstantsVO.uiEdgeInsetsTop = self.tblContents.contentInset.top
        }
        else if ConstantsVO.uiEdgeInsetsTop != self.tblContents.contentInset.top
        {
            self.tblContents.contentInset = UIEdgeInsetsMake(ConstantsVO.uiEdgeInsetsTop, 0, 0, 0)
        }*/
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        rawPoints = []
        let touch = touches.first
        let location = touch!.location(in: view)
        rawPoints.append(Int(location.x))
        rawPoints.append(Int(location.y))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let touch = touches.first
        let location = touch!.location(in: view)
        if (rawPoints[rawPoints.count-2] != Int(location.x) && rawPoints[rawPoints.count-1] != Int(location.y))
        {
            rawPoints.append(Int(location.x))
            rawPoints.append(Int(location.y))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        var path:Path = Path()
        path.addPointFromRaw(rawPoints)
        
        let gesture:PathModel? = self.recognizer!.recognizePath(path)
        
        if gesture != nil
        {
            let letters = gesture!.datas as? String
            if letters == "B"
            {
                importGalleryItems(title: "Select 3 Images")
            }
            else if letters == "C"
            {
                removeBackgroundImage()
            }
        }
        else
        {
            //letterLabel.text = ""
        }
    }
    
    deinit
    {
        self.dispose()
    }
    
    fileprivate func dispose()
    {
        NotificationCenter.default.removeObserver(self);
        if (self.dtg != nil)
        {
            ((UIApplication.shared.delegate?.window)!)!.removeGestureRecognizer(self.dtg)
        }
        ((UIApplication.shared.delegate?.window)!)!.removeGestureRecognizer(self.lpg)
        ConstantsVO.isBackgrounImage = false
        UIApplication.getDelegate().delegate = nil
        self.galleryManager = nil
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.destination is ImagesCollectionViewController)
        {
            self.setPresentationStyleForSelfController(presentingController: segue.destination)
        }
    }*/
    
    fileprivate func setupUI()
    {
        // we want transparent navigationBar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        // we don't want any back button here
        /*let backBarItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backBarItem*/
        
        // right button item
        // attach only if user not visited help yet
        if !ConstantsVO.isLoggedInAsGuest
        {
            // we want reduced gap between following two items
            // thus a bit extra work
            let settingBtn: UIButton = UIButton(type: UIButtonType.custom)
            settingBtn.setImage(UIImage(named: "Settings"), for: UIControlState.normal)
            settingBtn.addTarget(self, action: #selector(StartViewController.onSettings(_:)), for: UIControlEvents.touchUpInside)
            settingBtn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            settingsItem = UIBarButtonItem(customView: settingBtn)
            settingsItem.tintColor = UIColor.white
            
            let infoItem = UIBarButtonItem(image: UIImage(named: "exclamation"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(StartViewController.onHelp))
            infoItem.tintColor = UIColor.white
            
            self.navigationItem.rightBarButtonItems = [infoItem, settingsItem]
        }
    }
    
    func onHelp()
    {
        // we don't need that help button anymore
        NotificationCenter.default.addObserver(self, selector: #selector(StartViewController.userHelpCancelled), name: NSNotification.Name(rawValue: ConstantsVO.USER_HELP_CANCELLED), object: nil)
        
        let help = HelpUserController()
        help.colors = [#colorLiteral(red: 0.5320516229, green: 0.70357728, blue: 0.8049193621, alpha: 1),#colorLiteral(red: 0.2666860223, green: 0.5116362572, blue: 1, alpha: 1),#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)]
        help.titleArray = ["Welcome to Celo!", "It's your World", "Remain Hideous", "New Way to Videos"]
        help.subTitleArray = ["Swipe left n right for sections\n\nlong press for Import dialog\nload assets to your personal vault!", "Color your walls the way you want\n\ndraw 'B' to set background images\n draw 'I' to reset images.", "Hide in a blink.\n\nTwo finger press and disappear :)", "Control video by finger!\n\nlong-press and pan to control\nthe timeline."]
        help.subImagesArray = ["onboard0", "onboard1", "onboard2", "onboard3"]
        self.present(help, animated: false, completion: nil)
        self.isAdditionalPopoverOpen = true
        
        /*let help = Bundle.main.loadNibNamed("CeloHelpView", owner: self, options: nil)![0] as! CeloHelpView
        help.helpState = 1
        DispatchQueue.main.async
        {
            self.view.addSubview(help)
            help.show()
        }*/
    }
    
    @IBAction func onSettings(_ sender: AnyObject)
    {
        let menuController = SettingsTableViewController()
        menuController.modalPresentationStyle = UIModalPresentationStyle.popover
        menuController.preferredContentSize = CGSize(width: 300, height: 44)
        
        let popoverMenuViewController = menuController.popoverPresentationController
        popoverMenuViewController?.sourceView = self.view
        popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection.any
        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.barButtonItem = self.settingsItem
        present(menuController, animated: true, completion: nil)
    }
    
    func userHelpCancelled()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ConstantsVO.USER_HELP_CANCELLED), object: nil)
        self.dismiss(animated: true, completion: nil)
        self.isAdditionalPopoverOpen = false
    }
    
    func orientationChanged()
    {
        ConstantsVO.isLandscape = UIDevice.current.orientation.isLandscape
        isLandscape = ConstantsVO.isLandscape
    }
    
    func addGestures()
    {
        // 3-finger exit gesture detection
        lpg = UILongPressGestureRecognizer(target: self, action: #selector(StartViewController.handleLongPress(_:)))
        lpg.delegate = self
        //lpg.minimumPressDuration = 0 // lets keep it default 0.5
        lpg.numberOfTouchesRequired = 2
        ((UIApplication.shared.delegate?.window)!)!.addGestureRecognizer(lpg)
        
        // textual gesture detection
        //define the number of direction of PathModel
        let recognizer = DBPathRecognizer(sliceCount: 8, deltaMove: 16.0)
        
        //define specific formes to draw on PathModel
        recognizer.addModel(PathModel(directions: [2,6,0,1,2,3,4,0,1,2,3,4], datas:"B" as AnyObject)) // B for background images
        recognizer.addModel(PathModel(directions: [4,3,2,1,0], datas:"C" as AnyObject)) // C for remove background image

        self.recognizer = recognizer
    }
    
    func addSingleLongTapGesture()
    {
        if (dtg == nil)
        {
            // single-long-tap to import items in gallery
            dtg = UILongPressGestureRecognizer(target: self, action: #selector(StartViewController.handleLongPressSingleTap(_:)))
            dtg.delegate = self
            dtg.minimumPressDuration = 1
            dtg.numberOfTouchesRequired = 1
            ((UIApplication.shared.delegate?.window)!)!.addGestureRecognizer(dtg)
        }
    }
    
    func handleLongPress(_ sender:UILongPressGestureRecognizer)
    {
        if sender.state == UIGestureRecognizerState.ended
        {
            // @Was in 1.0
            //self.kill()
            
            // @Modified in 2.0
            UIApplication.getDelegate().gotoComa(true)
        }
    }
    
    func handleLongPressSingleTap(_ sender:UILongPressGestureRecognizer)
    {
        importGalleryItems()
    }
    
    func kill()
    {
        self.galleryManager.dispose()
        ConstantsVO.celoPath = nil
        
        // kill corrent views immediately
        /*if self.browser != nil
        {
            self.navigationController?.popViewController(animated: false)
        }*/
        
        // kill ohters view
        for viewController in (navigationController?.viewControllers)!
        {
            if (viewController is CeloSectionViewController)
            {
                (viewController as! CeloSectionViewController).dispose()
            }
        }
        
        // dismiss everything
        ConstantsVO.isInLoginState = false
        ConstantsVO.isLoggedInAsGuest = false
        
        DispatchQueue.main.async
        {
            self.dispose()
            self.dismiss(animated: !self.isAdditionalPopoverOpen, completion: nil)
            if self.isAdditionalPopoverOpen
            {
                DispatchQueue.main.async
                {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func onBackgroundRequested()
    {
        let menuController = ActionsTableViewController()
        menuController.collectionOfOption = MosaicActions.arrayForBackgroundImage
        menuController.delegate = self
        menuController.modalPresentationStyle = UIModalPresentationStyle.popover
        menuController.preferredContentSize = CGSize(width: 200, height: 88)
        
        let pointerRect = CGRect(x: self.view.frame.width/2, y: self.view.frame.height/2, width: 10, height: 10)
        let popoverMenuViewController = menuController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection.unknown
        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.sourceView = self.view
        popoverMenuViewController?.sourceRect = pointerRect
        present(menuController, animated: true, completion: nil)
    }
    
    func removeBackgroundImage()
    {
        for index in 0...2
        {
            onboardingArray[index].backgroundImage = nil
        }
        
        // send notif to PaperOnboard to change it's bgs
        NotificationCenter.default.post(name: Notification.Name(rawValue: ConstantsVO.BACKGROUND_CHANGED), object: nil)
        
        // populate background
        ConstantsVO.celoConfiguration.hasBackgroundImage = false
        ConstantsVO.isBackgrounImage = true
        try! UIApplication.getManagedContext()?.save()
    }
    
    fileprivate func restoreUIFromBackgroundImage()
    {
        self.tblContents.backgroundColor = UIColor(red: 0.937255, green: 0.937255, blue: 0.956863, alpha: 1)
        self.tblContents.separatorColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1)
    }
    
    public func generateBackground(_ withImages:[UIImage])
    {
        for (index, var bg) in withImages.enumerated()
        {
            /** NOTE **
             / From version 2.0 noticeable blur background removed
             / however blur applies to the image just to smoothing as much requires
             / tintColor also replaced by UIColor.clearColor() to make the
             / image look more realistic, earlier value was UIColor(white: 0.6, alpha: 0.2)
             **/
            bg = bg.applyBlur(withRadius: 0, tintColor: UIColor.clear, saturationDeltaFactor: 1.0, maskImage: nil)
            onboardingArray[index].backgroundImage = bg
        }
        
        // send notif to PaperOnboard to change it's bgs
        NotificationCenter.default.post(name: Notification.Name(rawValue: ConstantsVO.BACKGROUND_CHANGED), object: nil)
        
        // we want this to be happen once -
        // mainly when there was no background
        if !ConstantsVO.isBackgrounImage
        {
            ConstantsVO.celoConfiguration.hasBackgroundImage = true;
            ConstantsVO.isBackgrounImage = true
            try! UIApplication.getManagedContext()?.save()
        }
    }
    
    fileprivate func addConstraintToBackgroundImage(_ bgView:UIImageView)
    {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
    }
    
    fileprivate func updateHeaderViewSize()
    {
        // for an unknown reason whenever UI updated
        // with a background image, table header view height
        // modified and became thinner. To overcome this problem
        // I found only the least solution to fix it
        if (!ConstantsVO.isLandscape)
        {
            self.tblContents.tableHeaderView?.frame.size.height = self.tableHeaderViewHeight + 35
        }
        let newFrame = self.tblContents.tableHeaderView
        self.tblContents.tableHeaderView = nil
        self.tblContents.tableHeaderView = newFrame
        (self.tblContents.tableHeaderView as! StartTableHeaderView).updateTextColors()
    }
    
    fileprivate func updateHeaderViewSizeAfterOrientation()
    {
        let percentHeight = (ConstantsVO.isLandscape) ? CGFloat(0.65) : CGFloat(0.3)
        self.tblContents.tableHeaderView?.frame.size.height = self.view.frame.height * percentHeight
        self.tblContents.tableHeaderView?.frame.size.height = self.tableHeaderViewHeight + 35

        let newFrame = self.tblContents.tableHeaderView
        self.tblContents.tableHeaderView = nil
        self.tblContents.tableHeaderView = newFrame
        if self.tblContents.tableFooterView != nil
        {
            (self.tblContents.tableHeaderView as! StartTableHeaderView).updateTextColors()
        }
    }
    
    fileprivate func openGallery(_ type:PHAssetMediaType)
    {
        ((UIApplication.shared.delegate?.window)!)!.removeGestureRecognizer(dtg)
        dtg = nil
        
        mosaicBrowser = UIStoryboard.mosaicViewController() as! MosaicViewController
        mosaicBrowser.delegate = galleryManager
        
        /*browser = MWPhotoBrowser()
        browser.displayActionButton = true;
        browser.displayNavArrows = true;
        browser.displaySelectionButtons = false;
        browser.alwaysShowControls = false;
        browser.zoomPhotosToFill = false;
        browser.enableGrid = true;
        browser.startOnGrid = true;
        browser.enableSwipeToDismiss = false;
        browser.autoPlayOnAppear = false;
        browser.delegate = galleryManager;
        browser.type = type.stringValue
        browser.isUserAcceptedClouodDisclaimer = ConstantsVO.isUserAcceptedClouodDisclaimer
        
        if ConstantsVO.isBackgrounImage
        {
            browser.backgroundImage = (ConstantsVO.celoPath.path!) + "/Background.jpg"
        }*/
        
        self.galleryManager.showProgress(self.view, withType: HUDType.HUDTypeLabel, withTitle: "Loading")
        DispatchQueue.main.async
        {
            self.galleryManager.context = UIApplication.getManagedContext()
            self.galleryManager.loadGalleryForImages(type) { () -> Void in
                
                DispatchQueue.main.async
                {
                    self.galleryManager.endProgress()
                    
                    // sometime don't know why the heck
                    // this happens abruptly this calls double time.
                    // I don't want to keep any loose line
                    if !self.isBrowserAdded
                    {
                        self.navigationController?.pushViewController(self.mosaicBrowser, animated: true)
                        self.isBrowserAdded = true
                    }
                }
            }
        }
    }
    
    fileprivate func openOtherItems()
    {
        let othersView = UIStoryboard.othersViewController()
        self.navigationController?.pushViewController(othersView!, animated: true)
    }
    
    fileprivate func importGalleryItems(title:String="Celo")
    {
        isImportAsBackground = (title == "Celo") ? false : true
        ConstantsVO.isImportWindowOpened = true
        isAdditionalPopoverOpen = true
        
        // in case of import from library
        if !isImportAsBackground
        {
            PHPhotoLibrary.requestAuthorization {
                (status:PHAuthorizationStatus) -> Void in
                
                DispatchQueue.main.async
                {
                    let picker = CTAssetsPickerController()
                    picker.title = title
                    picker.delegate = self
                     
                    self.present(picker, animated: true, completion: nil)
                    ConstantsVO.isImportWindowOpened = false
                }
            }
        }
        else
        {
            // in case of import from Celo library to background choose
            self.galleryManager.showProgress(self.view, withType: HUDType.HUDTypeLabel, withTitle: "Loading")
            DispatchQueue.main.async
            {
                self.galleryManager.context = UIApplication.getManagedContext()
                self.galleryManager.loadGalleryForImages(PHAssetMediaType.image) { () -> Void in
                    
                    DispatchQueue.main.async
                    {
                        self.galleryManager.endProgress()
                        
                        self.imagesCollectionController = UIStoryboard.imagesCollectionController() as! ImagesCollectionViewController!
                        self.imagesCollectionController.delegate = self.galleryManager
                        self.imagesCollectionController.backgroundManager = self.backgroundManager
                        
                        let navBar = UINavigationController(rootViewController: self.imagesCollectionController)
                        navBar.modalPresentationStyle = UIModalPresentationStyle.formSheet
                        navBar.modalTransitionStyle = UIModalTransitionStyle.coverVertical
                        self.present(navBar, animated: true, completion: nil)
                        
                        ConstantsVO.isImportWindowOpened = false
                    }
                }
            }
        }
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @UITableView
//
//--------------------------------------------------------------------------

extension StartViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 3
        {
            return 2
        }
        else if (section == 4) && ConstantsVO.celoConfiguration.hasBackgroundImage
        {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell: UITableViewCell
        switch (indexPath as NSIndexPath).section
        {
        case 3:
            if (indexPath as NSIndexPath).row == 0
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) 
                let disclosure = UIImageView(image: UIImage(named: "expand"))
                cell.accessoryView = disclosure
                cell.textLabel?.text = "Import To Celo"
                cell.imageView?.image = UIImage(named: "import")
            }
            else
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "checkCell", for: indexPath)
                (cell as! SwitchTableViewCell).cellTitle.text = "Remove Original"
                (cell as! SwitchTableViewCell).switchSelected = ConstantsVO.celoConfiguration.isRemoveAfterImport
                cell.imageView?.image = UIImage(named: "strom")
            }
        case 4:
            cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)
            let disclosure = UIImageView(image: UIImage(named: "expand"))
            cell.accessoryView = disclosure
            cell.textLabel?.text = ((indexPath as NSIndexPath).row == 0) ? "Change Background" : "Remove Background"
            cell.imageView?.image = ((indexPath as NSIndexPath).row == 0) ? UIImage(named: "changeBG") : UIImage(named: "removeBG")
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "navInsideCell", for: indexPath) 
            cell.imageView?.image = UIImage(named: insideSections[(indexPath as NSIndexPath).section].icon)
            cell.textLabel?.text = insideSections[(indexPath as NSIndexPath).section].name
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath as NSIndexPath).section
        {
        case 0:
            openGallery(PHAssetMediaType.image)
        case 1:
            openGallery(PHAssetMediaType.video)
        case 2:
            openOtherItems()
        case 3:
            if (indexPath as NSIndexPath).row == 0
            {
                importGalleryItems()
            }
        case 4:
            if (indexPath as NSIndexPath).row == 0
            {
                //onBackgroundRequested(tableView.cellForRow(at: indexPath)!)
            }
            else
            {
                //removeBackgroundImage()
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section == 3
        {
            return "Import and Manage"
        }
        else if section == 4
        {
            return "Celo Options"
        }
        
        return ""
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = ConstantsVO.celoConfiguration.hasBackgroundImage ? UIColor.lightGray : UIColor(red: 0.427451, green: 0.427451, blue: 0.447059, alpha: 1)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        if ConstantsVO.celoConfiguration.hasBackgroundImage
        {
            if (indexPath as NSIndexPath).section == 4 && ((indexPath as NSIndexPath).row == 1)
            {
                cell.textLabel?.textColor = UIColor.red
            }
            else
            {
                cell.textLabel?.textColor = UIColor.white
            }
            
            cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
            
            if let switchCell = (cell as? SwitchTableViewCell)
            {
                switchCell.cellTitle.textColor = UIColor.white
            }
        }
        else
        {
            cell.textLabel?.textColor = UIColor.black
            cell.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8)
            if let switchCell = (cell as? SwitchTableViewCell)
            {
                switchCell.cellTitle.textColor = UIColor.black
            }
        }
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @CTAssetsPickerController
//
//--------------------------------------------------------------------------

extension StartViewController: CTAssetsPickerControllerDelegate
{
    func assetsPickerController(_ picker: CTAssetsPickerController!, didFinishPickingAssets assets: [Any]!)
    {
        DispatchQueue.main.async
        {
            picker.dismiss(animated: true, completion: nil)
            self.isAdditionalPopoverOpen = false
            
            // if this import is did for background image
            guard !self.isImportAsBackground else
            {
                // we need to see exact 3 assets if selected
                if assets.count != 3
                {
                    let alert = UIAlertController(title: "", message: "You need to select 3 images to set background.", preferredStyle: UIAlertControllerStyle.alert)
                    let doneAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                    alert.addAction(doneAction)
                    self.present(alert, animated: true, completion: nil)
                    
                    return
                }
                
                // do things for background task
                OperationQueue.main.addOperation
                    { () -> () in
                        //self.backgroundManager.updateToBackground(assets as! [PHAsset])
                    }
                return
            }
            
            self.galleryManager.showProgress(self.view, withType:HUDType.HUDTypePie, withTitle: "Copying")
            self.galleryManager.context = UIApplication.getManagedContext()
            self.galleryManager.updateToGallery(assets as! [PHAsset])
        }
    }
    
    func assetsPickerControllerDidCancel(_ picker: CTAssetsPickerController!)
    {
        picker.dismiss(animated: true, completion: nil)
        self.isAdditionalPopoverOpen = false
    }
    
    func changeBackgroundImages(byAssets:[PHAsset])
    {
        
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @BackgroundImageManagerDelegate
//
//--------------------------------------------------------------------------

extension StartViewController: BackgroundImageManagerDelegate
{
    func backgroundImagesUpdated(_ paths:[String])
    {
        var images = [UIImage]()
        var extensions = [String]()
        for item in paths
        {
            let index = item.index(item.endIndex, offsetBy: -4)
            extensions.append(item.substring(from: index))
            // get local image by 'draw' to reduce file size
            let accessedImage = UIImage(contentsOfFile: item)
            let bgImage = GenericControls.getAspectFillImageToDrawnInView(accessedImage!, sizeTo: CGRect(origin: CGPoint.init(), size: (accessedImage?.size)!))
            images.append(bgImage)
        }
        
        // populate background
        ConstantsVO.celoConfiguration.hasBackgroundImage = true
        UserDefaults.standard.set(extensions, forKey: "backgroundImageExtensions")
        self.isAdditionalPopoverOpen = false
        DispatchQueue.main.async
        {
            self.generateBackground(images)
        }
    }
    
    func backgroundRemoved()
    {
        
    }
    
    func backgroundImageWindowCancelled()
    {
        self.isAdditionalPopoverOpen = false
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @GalleryManager
//
//--------------------------------------------------------------------------

extension StartViewController: GalleryManagerDelegate
{
    func galleryUpdated()
    {
        DispatchQueue.main.async
        {
            //self.browser.reloadData()
            //self.browser.reloadDataAfterDeletion()
        }
    }
    
    func galleryReleased()
    {
        if mosaicBrowser != nil
        {
            self.mosaicBrowser = nil
            self.isBrowserAdded = false
        }
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @UIImagePickerController
//
//--------------------------------------------------------------------------

extension StartViewController: UIImagePickerControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        isAdditionalPopoverOpen = false
        
        // integrity check
        if info[UIImagePickerControllerOriginalImage] == nil
        {
            let alert = UIAlertController(title: "", message: "Selected image has integrity problem. Please check, or choose different one.", preferredStyle: UIAlertControllerStyle.alert)
            let doneAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(doneAction)
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // storing and releasing
        self.dismiss(animated: true, completion: nil)
        
        // moving to new view
        OperationQueue.main.addOperation
        { () -> () in
            // get the image
            var bgImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            let bgPath = (ConstantsVO.celoPath.path) + "/Background.jpg"
            
            // write to app directory
            try? UIImageJPEGRepresentation(bgImage!, 0.5)!.write(to: URL(fileURLWithPath: bgPath), options: [.atomic])
            
            // get local image by 'draw' to reduce file size
            bgImage = GenericControls.getAspectFillImageToDrawnInView(UIImage(contentsOfFile: (ConstantsVO.celoPath.path) + "/Background.jpg")!, sizeTo: self.view.frame)
            
            // populate background
            ConstantsVO.celoConfiguration.hasBackgroundImage = true
            DispatchQueue.main.async
            {
                //self.generateBackground(bgImage!, reloadTable: true)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        isAdditionalPopoverOpen = false
        self.dismiss(animated: true, completion: nil)
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @AppDelegate
//
//--------------------------------------------------------------------------

extension StartViewController: AppDelegateDelegate
{
    func applicationWillResignToBackground()
    {
        kill()
    }
    
    func applicationEnteredFromBackground()
    {
        
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @StartTableHeaderViewDelegate
//
//--------------------------------------------------------------------------

extension StartViewController: StartTableHeaderViewDelegate
{
    func importFromGallery()
    {
        self.importGalleryItems()
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @ActionsTableViewControllerDelegate
//
//--------------------------------------------------------------------------

extension StartViewController: ActionsTableViewControllerDelegate
{
    func onMosaicActionSelected(_ value: MosaicActions)
    {
        switch value
        {
        case MosaicActions.ImportFromGallery:
            print("Import from gallery")
        
        default:
            let uiImagePicker = UIImagePickerController()
            uiImagePicker.delegate = self
            uiImagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            
            ConstantsVO.isImportWindowOpened = true
            isAdditionalPopoverOpen = true
            self.dismiss(animated: false, completion: nil)
            self.present(uiImagePicker, animated: false, completion: nil)
        }
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @UIPopoverPresentationControllerDelegate
//
//--------------------------------------------------------------------------

extension StartViewController: UIPopoverPresentationControllerDelegate
{
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @PaperOnboarding
//
//--------------------------------------------------------------------------

extension StartViewController: PaperOnboardingDelegate
{
    func onboardingWillTransitonToIndex(_ index: Int)
    {
        //do something before slide index change
    }
    
    func onboardingDidTransitonToIndex(_ index: Int)
    {
        self.currentSectionIndex = index
        //do something after slide index change
    }
    
    func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index: Int)
    {
        //    item.titleLabel?.backgroundColor = .redColor()
        //    item.descriptionLabel?.backgroundColor = .redColor()
        //    item.imageView = ...
    }
    
    func gestureControlTapped()
    {
        switch self.currentSectionIndex {
        case 1:
            openGallery(PHAssetMediaType.video)
        case 2:
            let others = UIStoryboard.othersViewController() as! OthersTableViewController
            self.navigationController?.pushViewController(others, animated: true)
        default:
            openGallery(PHAssetMediaType.image)
        }
    }
}

extension StartViewController: PaperOnboardingDataSource
{
    func onboardingItemAtIndex(_ index: Int) -> OnboardingItemInfo
    {
        return onboardingArray[index]
    }
    
    func onboardingItemsCount() -> Int
    {
        return 3
    }
}
