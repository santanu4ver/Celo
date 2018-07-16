//
//  ViewController.swift
//  Celo
//
//  Created by Santanu Karar on 09/11/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit
import CoreData

let MosaicPhotoSquareImageSizeNonRetina = CGSize(width: 100, height: 100)
let MosaicPhotoSquareImageSizeRetina = CGSize(width: 200, height: 200)

class ViewController: UIViewController, UIGestureRecognizerDelegate, UIAlertViewDelegate
{    
    var animationController: ADVAnimationController!
    var lpg: UILongPressGestureRecognizer!
    var help: HelpUserController!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        addUI()
        //addCalculator()
        add2018()
        
        /*TEMP*
         let delay = 2 * Double(NSEC_PER_SEC)
         let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
         dispatch_after(time, dispatch_get_main_queue())
         {
         self.moveToStart()
         }*/
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        UIApplication.getDelegate().delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onUserLoginSuccess), name: NSNotification.Name(rawValue: ConstantsVO.USER_LOGIN_SUCCESS), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.userLoginCancelled), name: NSNotification.Name(rawValue: ConstantsVO.USER_LOGIN_CANCELLED), object: nil)
        
        if (!ConstantsVO.isUserHelpAchieved)
        {
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onUserHelpAsked), name: NSNotification.Name(rawValue: ConstantsVO.OPENING_HELP_REQUESTED), object: nil)
        }
        
        getConfiguration()
        addPressGesture()
        F3HUtil.addRemoveGestureControls(false)
        
        ConstantsVO.isInLoginState = false;
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self);
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self);
    }
    
    func addUI()
    {
        ConstantsVO.isLandscape = UIDevice.current.orientation.isLandscape
    }
    
    func addPressGesture()
    {
        lpg = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongPress(_:)))
        lpg.delegate = self
        lpg.minimumPressDuration = 2.0
        lpg.numberOfTouchesRequired = 2
        ((UIApplication.shared.delegate?.window)!)!.addGestureRecognizer(lpg)
    }
    
    func orientationChanged()
    {
        ConstantsVO.isLandscape = UIDevice.current.orientation.isLandscape
    }
    
    func userLoginCancelled()
    {
        F3HUtil.addRemoveGestureControls(false)
    }
    
    func onUserHelpAsked()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ConstantsVO.OPENING_HELP_REQUESTED), object: nil)
        ConstantsVO.isUserHelpAchieved = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.userNoteCancelled), name: NSNotification.Name(rawValue: ConstantsVO.USER_HELP_CANCELLED), object: nil)
        
        help = HelpUserController()
        help.colors = [#colorLiteral(red: 0.9980840087, green: 0.3723873496, blue: 0.4952875376, alpha: 1)]
        help.titleArray = ["This Message Will Not Come Again"]
        help.subTitleArray = ["Two-fingers' long-press\nwill lead you to open your\nLOGIN section."]
        help.subImagesArray = ["onboard2"]
        
        help.view.frame = self.view.frame
        F3HUtil.attachCeloHelp(help)
    }
    
    func userNoteCancelled()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ConstantsVO.USER_HELP_CANCELLED), object: nil)
        help.removeFromParentViewController();
        help.view.removeFromSuperview();
        help = nil
    }
    
    func onUserLoginSuccess()
    {
        // for guest user login
        if ConstantsVO.isLoggedInAsGuest
        {
            getConfiguration(true)
        }
        
        // after a slight delay lets proceed
        ConstantsVO.isLoginFormOpen = false
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time)
        {
            self.moveToStart()
        }
    }
    
    func addCalculator()
    {
        let calculator = UIView.getViewWithNibName("KJTipCalculatorView") as! KJTipCalculatorView
        calculator.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        view.addSubview(calculator)
        calculator.setupUI()
    }
    
    func add2018()
    {
        DispatchQueue.main.async
        {
            F3HUtil.attachGameController(self)
        }
    }
    
    func getConfiguration(_ asGuest:Bool=false)
    {
        let userConfigurationType: String = !asGuest ? "CeloConfiguration" : "CeloConfigurationGuest"
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: userConfigurationType)
        var getItems = [CeloConfiguration]()
        do
        {
            getItems = try UIApplication.getManagedContext()?.fetch(fetchRequest) as! [CeloConfiguration]
        }
        catch let error as NSError
        {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        // update local configuration
        if getItems.count > 0
        {
            ConstantsVO.celoConfiguration = getItems[0] as CeloConfiguration
        }
        else
        {
            // first time default config creation and saving
            ConstantsVO.celoConfiguration = NSEntityDescription.insertNewObject(forEntityName: !asGuest ? "CeloConfiguration" : "CeloConfigurationGuest", into: UIApplication.getManagedContext()!) as! CeloConfiguration
            try! UIApplication.getManagedContext()?.save()
        }
    }
    
    func moveToStart()
    {
        ((UIApplication.shared.delegate?.window)!)!.removeGestureRecognizer(self.lpg)
        
        let startView = UIStoryboard.startViewController()
        animationController = ZoomAnimationController()
        startView!.transitioningDelegate  = self;
        self.present(startView!, animated: true, completion: nil)
    }
    
    func handleLongPress(_ sender:UILongPressGestureRecognizer)
    {
        // avoid next processing if login already opening
        guard !ConstantsVO.isLoginFormOpen else
        {
            return
        }
        
        if sender.state == UIGestureRecognizerState.ended
        {
            // this will not show help icon in calculator view next time
            if !ConstantsVO.isUserHelpAchieved
            {
                ConstantsVO.isUserHelpAchieved = true
                UserDefaults.standard.set(true, forKey: "isUserHelpAchieved")
            }
            
            ConstantsVO.isLoginFormOpen = true
            let login = Bundle.main.loadNibNamed("LoginView", owner: self, options: nil)![0] as! LoginView
            DispatchQueue.main.async
                {
                    self.view.addSubview(login)
                    login.show()
                    F3HUtil.addRemoveGestureControls(true);
            }
        }
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @UIViewControllerTransition
//
//--------------------------------------------------------------------------

extension ViewController: UIViewControllerTransitioningDelegate
{
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        self.animationController.isPresenting = true
        return self.animationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        self.animationController.isPresenting = false
        return self.animationController
    }
}

extension UIViewControllerContextTransitioning
{
    func disposeWhenDone()
    {
        
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @AppDelegatDelegate
//
//--------------------------------------------------------------------------

extension ViewController: AppDelegateDelegate
{
    func applicationWillResignToBackground()
    {
        let loginView = self.view.subviews[self.view.subviews.count-1] as! LoginView
        loginView.removeFromSuperview()
        ConstantsVO.isLoginFormOpen = false
    }
    
    func applicationEnteredFromBackground()
    {
        
    }
}
