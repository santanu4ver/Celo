//
//  CeloHelpView.swift
//  Celo
//
//  Created by Santanu Karar on 18/11/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import UIKit

class CeloHelpView: UIView
{
    var helpState = 0
    
    @IBOutlet weak var txtDescription: UILabel!
    
    func show()
    {
        self.frame = UIScreen.main.bounds
        
        if helpState == 1
        {
            txtDescription.text = "- Use 3 fingers anytime to hide your private place" +
                                    "\n" +
                                    "- Use password 0000 to login as guest\n"
        }
        
        let backgroundImageView = UIImageView()
        insertSubview(backgroundImageView, at: 0)
        
        let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let extraLightBlurView = UIVisualEffectView(effect: darkBlur)
        insertSubview(extraLightBlurView, at: 0)
        
        let blurAreaAmount = self.bounds.height
        (extraLightBlurView.frame, _) = self.bounds.divided(atDistance: blurAreaAmount, from: CGRectEdge.maxYEdge)
        
        //extraLightBlurView.frame.makeIntegralInPlace()
    }
    
    @IBAction func onUnderstood(_ sender: AnyObject)
    {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            self.alpha = 0
            }) { (success) -> Void in
                
                self.removeFromSuperview()
        }
    }
}
