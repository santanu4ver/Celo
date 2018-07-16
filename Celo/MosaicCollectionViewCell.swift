//
//  MosaicCollectionViewCell.swift
//  MosaicGallery
//
//  Created by Santanu Karar on 10/03/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit
import FastImageCache

class MosaicCollectionViewCell: UICollectionViewCell
{
    fileprivate var _imagePath: MosaicPhoto!
    
    // Create new UIImageView and attach to contentView
    lazy var mosaicImageView: UIImageView! = {
        [unowned self] in
        
        var imageView = UIImageView(frame: self.bounds)
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        self.contentView.addSubview(imageView)
        
        return imageView
    }()
    
    lazy var nonSelectedIcon: UIImageView! = {
       [unowned self] in
        
        var imageView = UIImageView(image: UIImage(named: "selectedNormal"))
        imageView.frame = CGRect(x: self.frame.size.width-10, y: 10, width: 50, height: 50)
        return imageView
    }()
    
    lazy var selectedIcon: UIImageView! = {
        [unowned self] in
        
        var imageView = UIImageView(image: UIImage(named: "Checkmark"))
        imageView.frame = CGRect(x: 10, y: 10, width: 30, height: 30)
        return imageView
    }()
    
    var sIcon:UIImageView!
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // *Requisite*
    // Update mosaicImageView bounds everytime
    override var bounds: CGRect
    {
        didSet
        {
            self.mosaicImageView.frame = self.bounds
        }
    }
    
    // Sets image path
    var imagePath: MosaicPhoto!
    {
        get
        {
            return _imagePath
        }
        set
        {
            if _imagePath != newValue
            {
                _imagePath = newValue
                FICImageCache.shared().retrieveImage(for: newValue, withFormatName: FICDPhotoSquareImage16BitBGRFormatName)
                { (entity, imageFormat, image) -> Void in
                    
                    self.mosaicImageView.image = image
                }
            }
        }
    }
    
    func addSelectedImage()
    {
        self.contentView.addSubview(selectedIcon)
        selectedIcon.alpha = 0
    }
    
    // on selected toggle
    func setDeleteKeySelected(_ value:Bool)
    {
        selectedIcon.alpha = value ? 1 : 0
    }
}
