//
//  ImageSlideshow.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 30.07.15.
//

import UIKit

@objc public enum PageControlPosition: Int {
    case hidden
    case insideScrollView
    case underScrollView
}

open class ImageSlideshow: UIView, UIScrollViewDelegate {
    
    open let scrollView = UIScrollView()
    
    // state properties
    
    open var pageControlPosition = PageControlPosition.insideScrollView {
        didSet {
            setNeedsLayout()
            layoutScrollView()
        }
    }
    
    open var currentSlideshowItem: ImageSlideshowItem? {
        get {
            if (self.slideshowItems.count > self.scrollViewPage) {
                return self.slideshowItems[self.scrollViewPage]
            } else {
                return nil
            }
        }
    }
    
    open fileprivate(set) var scrollViewPage: Int = 0
    
    // preferences
    
    open var circular = true
    open var draggingEnabled = true {
        didSet {
            self.scrollView.isUserInteractionEnabled = draggingEnabled
        }
    }
    open var zoomEnabled = false
    open var slideshowInterval = 0.0 {
        didSet {
            self.slideshowTimer?.invalidate()
            self.slideshowTimer = nil
            setTimerIfNeeded()
        }
    }
    open var contentScaleMode: UIViewContentMode = UIViewContentMode.scaleAspectFit {
        didSet {
            for view in slideshowItems {
                view.imageView.contentMode = contentScaleMode
            }
        }
    }
    
    fileprivate var slideshowTimer: Timer?
    fileprivate(set) var images = [MosaicPhoto]()
    fileprivate var scrollViewImages = [MosaicPhoto]()
    open fileprivate(set) var slideshowItems = [ImageSlideshowItem]()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        self.autoresizesSubviews = true
        self.clipsToBounds = true
        
        // scroll view configuration
        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height - 50.0)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoresizingMask = self.autoresizingMask
        self.addSubview(scrollView)
        
        setTimerIfNeeded()
        layoutScrollView()
    }
    
    override open func layoutSubviews() {
        layoutScrollView()
    }
    
    /// updates frame of the scroll view and its inner items
    func layoutScrollView() {
        let scrollViewBottomPadding: CGFloat = self.pageControlPosition == .underScrollView ? 30.0 : 0.0
        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height - scrollViewBottomPadding)
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width * CGFloat(scrollViewImages.count), height: scrollView.frame.size.height)
        
        var i = 0
        for view in self.slideshowItems {
            if !view.zoomInInitially {
                view.zoomOut()
            }
            view.frame = CGRect(x: scrollView.frame.size.width * CGFloat(i), y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height)
            i += 1
        }
    }
    
    /// reloads scroll view with latest slideshowItems
    func reloadScrollView() {
        for view in self.slideshowItems {
            view.removeFromSuperview()
        }
        self.slideshowItems = []
        
        var i = 0
        for image in scrollViewImages {
            let item = ImageSlideshowItem(image: image, zoomEnabled: self.zoomEnabled)
            item.imageView.contentMode = self.contentScaleMode
            slideshowItems.append(item)
            scrollView.addSubview(item)
            i += 1
        }
        
        if circular && (scrollViewImages.count > 1) {
            scrollViewPage = 1
            scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width, y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height), animated: false)
        } else {
            scrollViewPage = 0
        }
    }
    
    // MARK: image setting
    
    func setImageInputs(_ inputs: [MosaicPhoto]) {
        self.images = inputs
        
        // in circular mode we add dummy first and last image to enable smooth scrolling
        if circular && images.count > 1 {
            var scImages = [MosaicPhoto]()
            
            if let last = images.last {
                scImages.append(last)
            }
            scImages += images
            if let first = images.first {
                scImages.append(first)
            }
            
            self.scrollViewImages = scImages
        } else {
            self.scrollViewImages = images;
        }
        
        reloadScrollView()
        layoutScrollView()
        setTimerIfNeeded()
    }
    
    // MARK: paging methods
    
    open func setCurrentPage(_ currentPage: Int, animated: Bool) {
        var pageOffset = currentPage
        if circular {
            pageOffset += 1
        }
        
        self.setScrollViewPage(pageOffset, animated: animated)
    }
    
    open func setScrollViewPage(_ scrollViewPage: Int, animated: Bool) {
        if scrollViewPage < scrollViewImages.count {
            self.scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width * CGFloat(scrollViewPage), y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height), animated: animated)
            self.setCurrentPageForScrollViewPage(scrollViewPage)
        }
    }
    
    fileprivate func setTimerIfNeeded() {
        if slideshowInterval > 0 && scrollViewImages.count > 1 && slideshowTimer == nil {
            slideshowTimer = Timer.scheduledTimer(timeInterval: slideshowInterval, target: self, selector: #selector(ImageSlideshow.slideshowTick(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func slideshowTick(_ timer: Timer) {
        
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        var nextPage = page + 1
        
        if !circular && page == scrollViewImages.count - 1 {
            nextPage = 0
        }
        
        self.scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width * CGFloat(nextPage), y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height), animated: true)
        
        self.setCurrentPageForScrollViewPage(nextPage);
    }
    
    open func setCurrentPageForScrollViewPage(_ page: Int) {
        if (scrollViewPage != page) {
            // current page has changed, zoom out this image
            if (slideshowItems.count > scrollViewPage) {
                slideshowItems[scrollViewPage].zoomOut()
            }
        }
        
        scrollViewPage = page
    }
    
    /// Stops slideshow timer
    open func pauseTimerIfNeeded() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
    }
    
    /// Restarts slideshow timer
    open func unpauseTimerIfNeeded() {
        setTimerIfNeeded()
    }
    
    // MARK: UIScrollViewDelegate
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if slideshowTimer?.isValid != nil {
            slideshowTimer?.invalidate()
            slideshowTimer = nil
        }
        
        setTimerIfNeeded()
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        setCurrentPageForScrollViewPage(page);
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if circular {
            let regularContentOffset = scrollView.frame.size.width * CGFloat(images.count)
            
            if (scrollView.contentOffset.x >= scrollView.frame.size.width * CGFloat(images.count + 1)) {
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x - regularContentOffset, y: 0)
            } else if (scrollView.contentOffset.x < 0) {
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x + regularContentOffset, y: 0)
            }
        }
    }
}
