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

    @NSManaged public var timestamp: Date?

}

extension BaseActivity : Identifiable {

}
