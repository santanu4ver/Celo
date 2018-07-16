//
//  GestureControl.swift
//  AnimatedPageView
//
//  Created by Alex K. on 21/04/16.
//  Copyright © 2016 Alex K. All rights reserved.
//

import UIKit

protocol GestureControlDelegate {
  func gestureControlDidSwipe(_ direction: UISwipeGestureRecognizerDirection)
    func gestureControlTapped()
}

class GestureControl: UIView {
  
  let delegate: GestureControlDelegate
  
  init(view: UIView, delegate: GestureControlDelegate) {
    self.delegate = delegate
    
    super.init(frame: CGRect.zero)
    
    let swipeLeft       = UISwipeGestureRecognizer(target: self, action: #selector(GestureControl.swipeHandler(_:)))
    swipeLeft.direction = .left
    addGestureRecognizer(swipeLeft)
    
    let swipeRight       = UISwipeGestureRecognizer(target: self, action: #selector(GestureControl.swipeHandler(_:)))
    swipeRight.direction = .right
    addGestureRecognizer(swipeRight)
    
    let tap             = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
    tap.numberOfTapsRequired = 1
    addGestureRecognizer(tap)
    
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor                           = .clear
    
    view.addSubview(self)
    // add constraints 
    for attribute: NSLayoutAttribute in [.left, .right, .top, .bottom] {
      (view , self) >>>- {
        $0.attribute = attribute
        return
      }
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: actions

extension GestureControl {
  
  dynamic func swipeHandler(_ gesture: UISwipeGestureRecognizer) {
    delegate.gestureControlDidSwipe(gesture.direction)
  }
    
    dynamic func tapHandler(_ gesture: UITapGestureRecognizer)
    {
        delegate.gestureControlTapped()
    }

}
