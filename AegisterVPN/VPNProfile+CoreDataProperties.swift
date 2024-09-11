//
//  VPNProfile+CoreDataProperties.swift
//  
//
//  Created by Aly Salman on 11/09/24.
//
//

import Foundation
import CoreData


extension VPNProfile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VPNProfile> {
        return NSFetchRequest<VPNProfile>(entityName: "VPNProfile")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var configurationData: Data?

}
