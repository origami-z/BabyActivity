//
//  BaseActivity+CoreDataProperties.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//
//

import Foundation
import CoreData


extension BaseActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseActivity> {
        return NSFetchRequest<BaseActivity>(entityName: "BaseActivity")
    }

    @NSManaged public var timestamp: Date

}

extension BaseActivity : Identifiable {

}

extension BaseActivity {
    @objc func getKind() -> String { // todo, change to enum..?, or add kind to persistent as Int32?
        preconditionFailure("This method must be overridden")
    }
    
    @objc func getImage() -> String {
        preconditionFailure("This method must be overridden")
    }
    
    @objc func getShortDescription() -> String {
        preconditionFailure("This method must be overridden")
    }
}
