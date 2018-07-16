//
//  ProgressHUDManager.swift
//  Celo
//
//  Created by Santanu Karar on 09/10/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import Foundation
import MBProgressHUD

var HUD: MBProgressHUD!

enum HUDType:String
{
    case HUDTypePie
    case HUDTypeLabel
}

class ProgressHUDManager: NSObject
{
    var isProcessing: Bool
    {
        return (HUD != nil)
    }
    
    fileprivate func getHUD(_ overView:UIView) -> MBProgressHUD
    {
        let _HUD = MBProgressHUD(view: overView)
        _HUD?.delegate = self
        _HUD?.removeFromSuperViewOnHide = true
        _HUD?.color = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        _HUD?.minSize = CGSize(width: 135, height: 135)
        
        overView.addSubview((_HUD)!)
        return _HUD!
    }
    
    func showHUDWithMixProgressItems(_ overView:UIView, withTitle:String)
    {
        HUD = self.getHUD(overView)
        HUD.mode = MBProgressHUDMode.determinate
        HUD.labelText = withTitle
        HUD.show(true)
    }
    
    func showHUDWithTitleOnly(_ overView:UIView, withTitle:String)
    {
        HUD = getHUD(overView)
        HUD.labelText = withTitle
        HUD.show(true)
    }
    
    func setTitle(_ title:String)
    {
        if (HUD != nil)
        {
            //HUD.updateLabel(title)
            HUD.labelText = title
        }
    }
    
    func setProgress(_ value:CGFloat)
    {
        if HUD != nil
        {
            HUD.progress = Float(value)
        }
    }
    
    func setFinish()
    {
        HUD.customView = UIImageView(image: UIImage(named: "37x-Checkmark"))
        OperationQueue.main.addOperation
        { () -> () in
            if HUD != nil
            {
                HUD.mode = MBProgressHUDMode.customView
                HUD.labelText = "Completed";
                self.perform(#selector(ProgressHUDManager.hideHUD), with: nil, afterDelay: 2)
            }
        }
    }
    
    func hideHUD()
    {
        if HUD != nil
        {
            HUD.hide(true)
            DispatchQueue.main.async
            {
                HUD = nil
            }
        }
    }
}

extension ProgressHUDManager: MBProgressHUDDelegate
{
    func hudWasHidden(_ hud: MBProgressHUD!)
    {
        hud.removeFromSuperview()
        HUD = nil;
    }
}
