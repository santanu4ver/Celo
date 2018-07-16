//
//  RoundedTextFields.swift
//  VoteYourSpider
//
//  Created by Santanu Karar on 05/08/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//

import UIKit

class RoundedTextFields: UITextField
{
    let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10);
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 5.0
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect
    {
        return self.newBounds(bounds)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect
    {
        return self.newBounds(bounds)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect
    {
        return self.newBounds(bounds)
    }
    
    fileprivate func newBounds(_ bounds: CGRect) -> CGRect
    {
        var newBounds = bounds
        newBounds.origin.x += padding.left
        newBounds.origin.y += padding.top
        newBounds.size.height -= (padding.top * 2) - padding.bottom
        newBounds.size.width -= (padding.left * 2) - padding.right
        
        return newBounds
    }
}
