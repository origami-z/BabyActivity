//
//  DiaperActivity+CoreDataProperties.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//
//

import Foundation
import CoreData


extension DiaperActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DiaperActivity> {
        return NSFetchRequest<DiaperActivity>(entityName: "DiaperActivity")
    }

    @NSManaged public var isWet: Bool
    @NSManaged public var isDirty: Bool

}
