//
//  CeloConfiguration.swift
//  Celo
//
//  Created by Santanu Karar on 08/10/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import Foundation
import CoreData

@objc(CeloConfiguration)
class CeloConfiguration: NSManagedObject
{
    @NSManaged var hasBackgroundImage: Bool
    @NSManaged var isRemoveAfterImport: Bool
    @NSManaged var pass:Int64
}

extension CeloConfiguration
{
    func resetEverything()
    {
        hasBackgroundImage = false
        isRemoveAfterImport = false
        pass = Int64(0)
    }
}