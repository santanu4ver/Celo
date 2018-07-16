//
//  FullScreenSlideshowViewController.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//

import UIKit

open class FullScreenSlideshowViewController: UIViewController {
    
    lazy var slideshow: ImageSlideshow = {
        let slideshow = ImageSlideshow()
        slideshow.zoomEnabled = true
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFit
        // turns off the timer
        slideshow.slideshowInterval = 0
        slideshow.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        return slideshow
    }()
    open var closeButton = UIButton()
    
    open var pageSelected: ((_ page: Int) -> ())?
    open var initialPage: Int = 0
    var inputs: GalleryItems!
    
    open var backgroundColor = UIColor.black
    open var zoomEnabled = true {
        didSet {
            slideshow.zoomEnabled = zoomEnabled
        }
    }
    
    fileprivate var isInit = true
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = backgroundColor
        
        // slideshow view configuration
        slideshow.frame = self.view.frame
        slideshow.backgroundColor = backgroundColor
        
        if let inputs = inputs {
            slideshow.setImageInputs(inputs)
        }
        
        slideshow.frame = self.view.frame
        self.view.addSubview(slideshow);
        
        // close button configuration
        closeButton.frame = CGRect(x: 10, y: 20, width: 40, height: 40)
        closeButton.setImage(UIImage(named: "ic_cross_white"), for: UIControlState())
        closeButton.addTarget(self, action: #selector(FullScreenSlideshowViewController.close), for: UIControlEvents.touchUpInside)
        self.view.addSubview(closeButton)
    }
    
    override open var prefersStatusBarHidden : Bool {
        return true
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isInit {
            isInit = false
            slideshow.setScrollViewPage(self.initialPage, animated: false)
        }
    }
    
    func close() {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(slideshow.scrollViewPage)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
