//
//  GalleryInstance.swift
//  Celo
//
//  Created by Santanu Karar on 22/09/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import Foundation
import CoreData

@objc(GalleryInstance)
class GalleryInstance: NSManagedObject
{
    @NSManaged var url: String
    @NSManaged var type: String
    @NSManaged var timestamp: NSNumber
}