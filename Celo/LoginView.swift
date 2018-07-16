//
//  LoginView.swift
//  Celo
//
//  Created by Santanu Karar on 17/09/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//

import UIKit

class LoginView: UIView
{
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtRePassword: UITextField!
    @IBOutlet weak var btnGetIn: UIButton!
    @IBOutlet weak var txtPasswordLogin: RoundedTextFields!
    @IBOutlet weak var btnGetInLogin: UIButton!
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var viewRegister: UIView!
    @IBOutlet weak var viewLogin: UIView!
    
    @IBOutlet weak var imgLogo: UIImageView!
    @IBOutlet weak var logoBelowPadding: NSLayoutConstraint!
    @IBOutlet weak var titleBelowPadding: NSLayoutConstraint!
    @IBOutlet weak var descriptionBelowPadding: NSLayoutConstraint!
    @IBOutlet weak var forgotPassBox: UIView!
    @IBOutlet weak var lblLoginWelcomeText: UILabel!
    
    var loginAttempt = 0
    
    func show()
    {
        self.alpha = 0
        self.frame = UIScreen.main.bounds
        
        if ConstantsVO.celoConfiguration.pass == 0
        {
            // in register view
            viewLogin.isUserInteractionEnabled = false
            viewLogin.isHidden = true
            
            self.txtPassword.alpha = 0
            self.txtRePassword.alpha = 0
            self.btnGetIn.alpha = 0
            self.btnGetIn.setCornerRadius(5.0)
        }
        else
        {
            // in login view
            viewRegister.isUserInteractionEnabled = false
            viewRegister.isHidden = true
            lblName.text = "Welcome Back!"
            
            self.txtPasswordLogin.alpha = 0
            self.btnGetInLogin.alpha = 0
            self.btnGetInLogin.setCornerRadius(5.0)
        }
        
        updateSizes()
        
        var tmpImage = GenericControls.getAspectFillImageToDrawnInView(UIImage(named: "bg")!, sizeTo: self.frame)
        var backgroundImageView: UIImageView
        backgroundColor = UIColor.clear
        
        // since UIBlurEffect is not available in older
        // devices like iPad2, we'll use the said class based upon devices
        if GenericControls.isBlurSupported()
        {
            backgroundImageView = UIImageView(image: tmpImage)
            backgroundImageView.frame = UIScreen.main.bounds
            backgroundImageView.contentMode = UIViewContentMode.scaleToFill
            insertSubview(backgroundImageView, at: 0)
            addConstraintToBackgroundImage(backgroundImageView)
            
            let extraLightBlur = UIBlurEffect(style: .extraLight)
            let extraLightBlurView = UIVisualEffectView(effect: extraLightBlur)
            insertSubview(extraLightBlurView, aboveSubview: backgroundImageView)
            addConstraintToBackgroundImage(extraLightBlurView)
            
            let blurAreaAmount = self.bounds.height
            (extraLightBlurView.frame, _) = self.bounds.divided(atDistance: blurAreaAmount, from: CGRectEdge.maxYEdge)
            
            //extraLightBlurView.frame.makeIntegralInPlace()
        }
        else
        {
            tmpImage = tmpImage.applyBlur(withRadius: 30, tintColor: UIColor(white: 1, alpha: 0.5), saturationDeltaFactor: 1.0, maskImage: nil)
            
            backgroundImageView = UIImageView(image: tmpImage)
            backgroundImageView.frame = UIScreen.main.bounds
            backgroundImageView.contentMode = UIViewContentMode.scaleToFill
            insertSubview(backgroundImageView, at: 0)
            addConstraintToBackgroundImage(backgroundImageView)
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            self.alpha = 1
            }) { (success) -> Void in
                
            self.animateUIElements()
        }
        
        // adds listeners to move-up the text fields
        // when keyboard will appear
        if ConstantsVO.deviceScreenHeight < 600
        {
            NotificationCenter.default.addObserver(self, selector: #selector(LoginView.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
            NotificationCenter.default.addObserver(self, selector: #selector(LoginView.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        }
    }
    
    func addConstraintToBackgroundImage(_ bgView:UIView)
    {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: bgView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
    }
    
    func updateSizes()
    {
        // iphone4s
        if ConstantsVO.deviceScreenHeight < 500
        {
            lblName.font = lblName.font.withSize(27)
            lblDescription.font = lblDescription.font.withSize(14)
            
            logoBelowPadding.constant /= 2
            titleBelowPadding.constant /= 2
        }
    }
    
    func animateUIElements()
    {
        if ConstantsVO.celoConfiguration.pass == 0
        {
            // in registration view
            txtPassword.frame.origin.x = -15
            txtRePassword.frame.origin.x = -15
            btnGetIn.frame.origin.x = -15
            
            UIView.animateKeyframes(
                withDuration: 1.0,
                delay: 0,
                options: [],
                animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 1/3, animations: {
                        self.txtPassword.alpha = 1
                        self.txtPassword.frame.origin.x = 0
                    })
                    
                    UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 1/3, animations: {
                        self.txtRePassword.alpha = 1
                        self.txtRePassword.frame.origin.x = 0
                    })
                    
                    UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 1/3, animations: {
                        self.btnGetIn.alpha = 1
                        self.btnGetIn.frame.origin.x = 0
                    })
                },
                completion: {finished in
                }
            )
        }
        else
        {
            // in login view
            txtPasswordLogin.frame.origin.x = -15
            btnGetInLogin.frame.origin.x = -15
            
            UIView.animateKeyframes(
                withDuration: 1.0,
                delay: 0,
                options: [],
                animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 1/3, animations: {
                        self.txtPasswordLogin.alpha = 1
                        self.txtPasswordLogin.frame.origin.x = 0
                    })
                    
                    UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 1/3, animations: {
                        self.btnGetInLogin.alpha = 1
                        self.btnGetInLogin.frame.origin.x = 0
                    })
                },
                completion: {finished in
                }
            )
        }
    }
    
    func animateTextView(_ textView:UITextField)
    {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: textView.center.x - 10, y: textView.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: textView.center.x + 10, y: textView.center.y))
        textView.layer.add(animation, forKey: "position")
        
        // empty the textinput after a short delay to complete the animation
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time)
        {
           textView.text = "";
        }
    }
    
    func initShowForgotPassword()
    {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            self.lblLoginWelcomeText.alpha = 0
            }, completion: nil)
        
        Thread.detachNewThreadSelector(#selector(LoginView.showForgotPassword), toTarget: self, with: nil)
    }
    
    func showForgotPassword()
    {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            self.forgotPassBox.alpha = 1
            }, completion: nil)
    }
    
    func keyboardWillShow(_ notification: Notification)
    {
        if ConstantsVO.keyboardHeight == nil
        {
            let info:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
            let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            ConstantsVO.keyboardHeight = keyboardSize.height
        }
        
        let followTransform = CATransform3DMakeTranslation(0, -40, 0)
        if !self.viewLogin.isHidden
        {
            self.viewLogin.layer.transform = followTransform
        }
        else
        {
            self.viewRegister.layer.transform = followTransform
        }
    }
    
    func keyboardWillHide(_ notification: Notification)
    {
        if !self.viewLogin.isHidden
        {
            self.viewLogin.transform = CGAffineTransform.identity
        }
        else
        {
            self.viewRegister.transform = CGAffineTransform.identity
        }
    }
    
    @IBAction func onCloseLogin(_ sender: AnyObject)
    {
        ConstantsVO.isLoginFormOpen = false
        NotificationCenter.default.post(name: Notification.Name(rawValue: ConstantsVO.USER_LOGIN_CANCELLED), object: nil)
        self.removeFromSuperview()
    }
    
    @IBAction func onGetInConfirm(_ sender: AnyObject)
    {
        guard (!(txtPassword.text?.isEmpty ?? false) && !(txtRePassword.text?.isEmpty ?? false)) else
        {
            return
        }
        
        guard (txtPassword.text == txtRePassword.text) else
        {
            animateTextView(txtRePassword)
            return
        }
        
        // saving the password
        ConstantsVO.celoConfiguration.pass = (txtRePassword.text! as NSString).longLongValue
        try! UIApplication.getManagedContext()?.save()
        
        // send success notif and close
        NotificationCenter.default.post(name: Notification.Name(rawValue: ConstantsVO.USER_LOGIN_SUCCESS), object: nil)
        self.removeFromSuperview()
    }
    
    @IBAction func onLoginRequest(_ sender: AnyObject)
    {
        guard ((txtPasswordLogin.text == String(describing: ConstantsVO.celoConfiguration.pass)) || (txtPasswordLogin.text == "0000")) else
        {
            animateTextView(txtPasswordLogin)
            loginAttempt += 1
            if loginAttempt == 3
            {
                initShowForgotPassword()
            }
            return
        }
        
        // logged in as guest
        if txtPasswordLogin.text == "0000"
        {
            ConstantsVO.isLoggedInAsGuest = true
            ConstantsVO.isBackgrounImage = false
        }
        
        // send success notif and close
        NotificationCenter.default.post(name: Notification.Name(rawValue: ConstantsVO.USER_LOGIN_SUCCESS), object: nil)
        self.removeFromSuperview()
    }
    
    @IBAction func onForgotPassword(_ sender: AnyObject)
    {
        loginAttempt = 0
        GalleryManager.destroyExistings()
        OperationQueue.main.addOperation { () -> Void in

                // in register view
                self.viewLogin.isUserInteractionEnabled = false
                self.viewLogin.isHidden = true
            
                self.viewRegister.isUserInteractionEnabled = true
                self.viewRegister.isHidden = false
                
                self.txtPassword.alpha = 0
                self.txtRePassword.alpha = 0
                self.btnGetIn.alpha = 0
                self.btnGetIn.setCornerRadius(5.0)
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                self.alpha = 1
                }) { (success) -> Void in
                    
                self.animateUIElements()
            }
        }
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @UITextField
//
//--------------------------------------------------------------------------

extension LoginView: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        self.endEditing(true)
    }
}
