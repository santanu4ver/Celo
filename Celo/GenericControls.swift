//
//  GenericControls.swift
//  VoteYourSpider
//
//  Created by Santanu Karar on 06/08/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//

import Foundation
import SystemConfiguration

class GenericControls: NSObject
{
    class func getAspectFillImageToDrawnInView(_ sourceImage:UIImage, sizeTo:CGRect) -> UIImage
    {
        let newSize = CGSize(width: sizeTo.width, height: sizeTo.height)
        var ratio: CGFloat
        var newWidth: CGFloat
        var newX: CGFloat
        
        if !ConstantsVO.isLandscape
        {
            ratio = newSize.height/sourceImage.size.height;
            newWidth = ratio * sourceImage.size.width
            newX = (newWidth - sizeTo.width) / 2
        }
        else
        {
            ratio = newSize.width/sourceImage.size.width;
            newWidth = ratio * sourceImage.size.height
            newX = (newWidth - sizeTo.height) / 2
        }
        
        UIGraphicsBeginImageContext(newSize);
        if !ConstantsVO.isLandscape
        {
            sourceImage.draw(in: CGRect(x: -newX, y: 0, width: newWidth, height: newSize.height))
        }
        else
        {
            sourceImage.draw(in: CGRect(x: 0, y: -newX, width: newSize.width, height: newWidth))
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage!;
    }
    
    class func isBlurSupported() -> Bool
    {
        var supported = Set<String>()
        supported.insert("iPad")
        supported.insert("iPad1,1")
        supported.insert("iPhone1,1")
        supported.insert("iPhone1,2")
        supported.insert("iPhone2,1")
        supported.insert("iPhone3,1")
        supported.insert("iPhone3,2")
        supported.insert("iPhone3,3")
        supported.insert("iPod1,1")
        supported.insert("iPod2,1")
        supported.insert("iPod2,2")
        supported.insert("iPod3,1")
        supported.insert("iPod4,1")
        supported.insert("iPad2,1")
        supported.insert("iPad2,2")
        supported.insert("iPad2,3")
        supported.insert("iPad2,4")
        supported.insert("iPad3,1")
        supported.insert("iPad3,2")
        supported.insert("iPad3,3")
        
        return !supported.contains(hardwareString())
    }
    
    class func hardwareString() -> String
    {
        var name: [Int32] = [CTL_HW, HW_MACHINE]
        var size: Int = 2
        sysctl(&name, 2, nil, &size, &name, 0)
        var hw_machine = [CChar](repeating: 0, count: Int(size))
        sysctl(&name, 2, &hw_machine, &size, &name, 0)
        
        let hardware: String = String(cString: hw_machine)
        return hardware
    }
    
    class func isConnectedToNetwork() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags.connectionAutomatic
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    class func previewImageForLocalVideo(_ url:NSURL, sizeTo:CGRect!) -> UIImage?
    {
        let asset = AVAsset(url: url as URL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        
        // if possible - take not the first frame (it could be completely black or white on camara's videos)
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            var newImage = UIImage(cgImage: imageRef)
            // resize image
            if sizeTo != nil
            {
                let newSize = CGSize(width: sizeTo.width, height: sizeTo.height)
                UIGraphicsBeginImageContext(newSize);
                newImage.draw(in: CGRect(x: 0, y: 0, width: sizeTo.width, height: sizeTo.height))
                newImage = UIGraphicsGetImageFromCurrentImageContext()!;
                UIGraphicsEndImageContext();
            }
            
            return newImage
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}
