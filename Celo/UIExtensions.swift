//
//  UIStoryBoard.swift
//  ShadowChat
//
//  Created by Santanu Karar on 14/02/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//

import Foundation
import UIKit
import CoreData

private let DeviceList = [
    /* iPod 5 */          "iPod5,1": "iPod Touch 5",
    /* iPhone 4 */        "iPhone3,1":  "iPhone 4", "iPhone3,2": "iPhone 4", "iPhone3,3": "iPhone 4",
    /* iPhone 4S */       "iPhone4,1": "iPhone 4S",
    /* iPhone 5 */        "iPhone5,1": "iPhone 5", "iPhone5,2": "iPhone 5",
    /* iPhone 5C */       "iPhone5,3": "iPhone 5C", "iPhone5,4": "iPhone 5C",
    /* iPhone 5S */       "iPhone6,1": "iPhone 5S", "iPhone6,2": "iPhone 5S",
    /* iPhone 6 */        "iPhone7,2": "iPhone 6",
    /* iPhone 6 Plus */   "iPhone7,1": "iPhone 6 Plus",
    /* iPad 2 */          "iPad2,1": "iPad 2", "iPad2,2": "iPad 2", "iPad2,3": "iPad 2", "iPad2,4": "iPad 2",
    /* iPad 3 */          "iPad3,1": "iPad 3", "iPad3,2": "iPad 3", "iPad3,3": "iPad 3",
    /* iPad 4 */          "iPad3,4": "iPad 4", "iPad3,5": "iPad 4", "iPad3,6": "iPad 4",
    /* iPad Air */        "iPad4,1": "iPad Air", "iPad4,2": "iPad Air", "iPad4,3": "iPad Air",
    /* iPad Air 2 */      "iPad5,1": "iPad Air 2", "iPad5,3": "iPad Air 2", "iPad5,4": "iPad Air 2",
    /* iPad Mini */       "iPad2,5": "iPad Mini", "iPad2,6": "iPad Mini", "iPad2,7": "iPad Mini",
    /* iPad Mini 2 */     "iPad4,4": "iPad Mini", "iPad4,5": "iPad Mini", "iPad4,6": "iPad Mini",
    /* iPad Mini 3 */     "iPad4,7": "iPad Mini", "iPad4,8": "iPad Mini", "iPad4,9": "iPad Mini",
    /* Simulator */       "x86_64": "Simulator", "i386": "Simulator"
]

extension UIScreen
{
    static var isRetina: Bool {
        return screenScale >= 2.0
    }
    
    static var isRetinaHD: Bool {
        return screenScale >= 3.0
    }
    
    static var screenScale:CGFloat {
        return UIScreen.main.scale
    }
}

extension UIStoryboard
{
    class func mainStoryboard() -> UIStoryboard
    {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    
    class func startViewController() -> UINavigationController?
    {
        return mainStoryboard().instantiateViewController(withIdentifier: "startView") as? UINavigationController
    }
    
    class func guestViewController() -> UIViewController?
    {
        return mainStoryboard().instantiateViewController(withIdentifier: "guestView")
    }
    
    class func mosaicViewController() -> UIViewController?
    {
        return mainStoryboard().instantiateViewController(withIdentifier: "mosaicCollectionView")
    }
    
    class func othersViewController() -> UIViewController?
    {
        return mainStoryboard().instantiateViewController(withIdentifier: "othersTableview")
    }
    
    class func otherDetailsViewController() -> UIViewController?
    {
        return mainStoryboard().instantiateViewController(withIdentifier: "otherDetails")
    }
    
    class func imagesCollectionController() -> UIViewController?
    {
        return mainStoryboard().instantiateViewController(withIdentifier: "imagesCollectionController")
    }
}

extension UIDevice
{
    var modelName: String
    {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        //let mirror = reflect(machine)                // Swift 1.2
        let mirror = Mirror(reflecting: machine)  // Swift 2.0
        var identifier = ""
        
        // Swift 1.2 - if you use Swift 2.0 comment this loop out.
        /*for i in 0..<mirror.count
        {
            if let value = mirror[i].1.value as? Int8 where value != 0
            {
                identifier.append(UnicodeScalar(UInt8(value)))
            }
        }*/
        
        // Swift 2.0 and later - if you use Swift 2.0 uncomment his loop
        for child in mirror.children where child.value as? Int8 != 0
        {
            identifier.append(String(UnicodeScalar(UInt8(child.value as! Int8))))
        }
        
        return DeviceList[identifier] ?? identifier
    }
    
}

extension NSRange
{
    func toRange(_ string: String) -> Range<String.Index>
    {
        let startIndex = string.characters.index(string.startIndex, offsetBy: location)
        let endIndex = string.characters.index(startIndex, offsetBy: length)
        return startIndex..<endIndex
    }
}

extension UIView
{
    class func getViewWithNibName(_ nibName:String) -> AnyObject!
    {
        return Bundle.main.loadNibNamed(nibName, owner: self, options: nil)![0] as AnyObject
    }
    
    func roundCorner(_ corners: UIRectCorner, radius: CGFloat)
    {
        let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.cgPath;
        self.layer.mask = maskLayer;
    }
}

extension UIImageView
{
    func setRoundImage(_ borderSize:CGFloat, color:UIColor)
    {
        let borderColor = color
        self.layer.cornerRadius = self.frame.size.width/2;
        self.clipsToBounds = true
        self.layer.borderWidth = borderSize
        self.layer.borderColor = borderColor.cgColor
    }
}

extension UIImage
{
    enum Asset: String
    {
        case v3Image = "v3Images"
        
        var image: UIImage
        {
            return UIImage(asset: self)
        }
    }
    
    convenience init!(asset: Asset)
    {
        self.init(named: asset.rawValue)
    }
    
    func grayScaleImage() -> UIImage
    {
        let imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height);
        let colorSpace = CGColorSpaceCreateDeviceGray();
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGBitmapInfo().rawValue)
        context!.draw(self.cgImage!, in: imageRect);
        let imageRef = context!.makeImage();
        let newImage = UIImage(cgImage: imageRef!)
        return newImage
    }
    
    func getThumbnailImage(_ thumbsize:CGSize) -> UIImage
    {
        let rect = CGRect(x: 0, y: 0, width: thumbsize.width, height: thumbsize.height)
        UIGraphicsBeginImageContextWithOptions(thumbsize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func getPortionedScreenshot(_ targetRect:CGRect) -> UIImage!
    {
        UIGraphicsBeginImageContext(CGSize(width: targetRect.width, height: targetRect.height));
        self.draw(at: CGPoint(x: targetRect.origin.x, y: targetRect.origin.y))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return newImage
    }
}

extension UITextField
{
    var isEmail: Bool
    {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        return emailTest.evaluate(with: self.text)
    }
}

extension UIButton
{
    func setActivityIndicator()
    {
        if ConstantsVO.activityIndicator == nil
        {
            self.isEnabled = false
            ConstantsVO.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            ConstantsVO.activityIndicator.frame = CGRect(x: self.frame.width - 30, y: (self.frame.height-10)/2, width: 10, height: 10)
            ConstantsVO.activityIndicator.startAnimating()
            self.addSubview(ConstantsVO.activityIndicator)
        }
    }
    
    func stopActivityIndicator()
    {
        if ConstantsVO.activityIndicator != nil
        {
            self.isEnabled = true
            ConstantsVO.activityIndicator.stopAnimating()
            ConstantsVO.activityIndicator.removeFromSuperview()
            ConstantsVO.activityIndicator = nil
        }
    }
    
    func setCornerRadius(_ value:CGFloat)
    {
        self.layer.cornerRadius = value
    }
}

extension Array
{
    mutating func getObjectIndex<U: Equatable>(_ object: U) -> Int!
    {
        for (idx, objectToCompare) in self.enumerated()
        {
            if let to = objectToCompare as? U
            {
                if object == to
                {
                    return idx
                }
            }
        }
        
        return nil
    }
}

extension UIColor
{
    class func getUIColorBasedUponRGBValue(_ r:CGFloat, g:CGFloat, b:CGFloat) -> UIColor!
    {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
}

extension UIApplication
{
    class func getManagedContext() -> NSManagedObjectContext?
    {
        return (UIApplication.shared.delegate as! AppDelegate).getContext()
    }
    
    class func getDelegate() -> AppDelegate
    {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    class func clearCoreData(_ entity:String)
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let managedContext = getManagedContext()!
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: entity, in: managedContext)
        fetchRequest.includesPropertyValues = false
        do {
            if let results = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
            {
                for result in results
                {
                    managedContext.delete(result)
                }
                
                try managedContext.save()
            }
        }
        catch let error as NSError
        {
            NSLog("\(error.localizedDescription)")
        }
        catch
        {
            print("general error - \(error)", terminator: "\n")
        }
    }
}
