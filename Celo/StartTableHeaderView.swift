//
//  StartTableHeaderView.swift
//  Celo
//
//  Created by Santanu Karar on 08/10/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import UIKit

protocol StartTableHeaderViewDelegate: class
{
    func importFromGallery()
}

class StartTableHeaderView: UIView
{
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnImport: UIButton!
    
    @IBOutlet weak var topPadding: NSLayoutConstraint!
    @IBOutlet weak var logoBelowPadding: NSLayoutConstraint!
    @IBOutlet weak var titleBelowPadding: NSLayoutConstraint!
    
    weak var delegate: StartTableHeaderViewDelegate!
    
    var subView: UIView!
    
    override init(frame: CGRect) {
        // 1. setup any properties here
        
        // 2. call super.init(frame:)
        super.init(frame: frame)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    required init(coder aDecoder: NSCoder) {
        // 1. setup any properties here
        
        // 2. call super.init(coder:)
        super.init(coder: aDecoder)!
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    func xibSetup()
    {
        subView = Bundle.main.loadNibNamed("StartTableHeaderView", owner: self, options: nil)![0] as! UIView
        subView.frame = bounds
        self.addSubview(subView)
        
        DispatchQueue.main.async
        {
            self.setupUI()
        }
    }
    
    func setupUI()
    {
        updateTextColors()
        if ConstantsVO.isUserImportedForFirstTime
        {
            btnImport.setTitle("Keep Importing in Celo!", for: UIControlState())
        }
        
            // iphone4s
        if ConstantsVO.deviceScreenHeight < 500
        {
            lblName.font = lblName.font.withSize(27)
            lblDescription.font = lblDescription.font.withSize(14)
            
            topPadding.constant /= 2
            logoBelowPadding.constant /= 2
            titleBelowPadding.constant /= 2
        }
            // iphone5
        else if ConstantsVO.deviceScreenHeight < 600
        {
            lblName.font = lblName.font.withSize(27)
            lblDescription.font = lblDescription.font.withSize(14)
            
            topPadding.constant *= 2
            logoBelowPadding.constant /= 2
            titleBelowPadding.constant /= 2
        }
            // iphone6
        else if ConstantsVO.deviceScreenHeight < 700
        {
            
        }
            // iphone 6+
        else
        {
            logoBelowPadding.constant /= 2
            titleBelowPadding.constant /= 2
            btnImport.isHidden = false
        }
    }
    
    func updateTextColors()
    {
        if (ConstantsVO.celoConfiguration.hasBackgroundImage)
        {
            lblName.textColor = UIColor.white
            lblDescription.textColor = UIColor.white
        }
        else
        {
            lblName.textColor = UIColor.black
            lblDescription.textColor = UIColor.black
        }
    }
    
    /**
     * Following code to catch button click event
     * where the button is out of this view's bound
     */
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        let translatedPoint = btnImport.convert(point, from: self)
        if (btnImport.bounds.contains(translatedPoint))
        {
            return btnImport.hitTest(translatedPoint, with: event)
        }
        
        return super.hitTest(point, with: event)
    }
    
    @IBAction func onImportToCelo(_ sender: AnyObject)
    {
        delegate.importFromGallery()
    }
}
