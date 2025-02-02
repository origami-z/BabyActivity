//
//  BaseActivity+CoreDataProperties.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//
//

import Foundation
import CoreData

// Defined with @objc to allow it to be used with @NSManaged.
@objc public enum ActivityType: Int32
{
    case Custom             = 0
    case Diaper             = 1
    case Milk               = 2
    case Sleep              = 3
}



extension BaseActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseActivity> {
        return NSFetchRequest<BaseActivity>(entityName: "BaseActivity")
    }

    @NSManaged public var timestamp: Date

    @NSManaged public var type: ActivityType
}

extension BaseActivity : Identifiable {

}

extension BaseActivity {
    @objc func getKind() -> String {
        preconditionFailure("This method must be overridden")
    }
    
    @objc func getImage() -> String {
        preconditionFailure("This method must be overridden")
    }
    
    @objc func getShortDescription() -> String {
        preconditionFailure("This method must be overridden")
    }
}
