//
//  CustomActivity+CoreDataProperties.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//
//

import Foundation
import CoreData


extension CustomActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomActivity> {
        return NSFetchRequest<CustomActivity>(entityName: "CustomActivity")
    }

    @NSManaged public var message: String?

}
