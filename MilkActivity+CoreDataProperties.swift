//
//  MilkActivity+CoreDataProperties.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//
//

import Foundation
import CoreData


extension MilkActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MilkActivity> {
        return NSFetchRequest<MilkActivity>(entityName: "MilkActivity")
    }

    @NSManaged public var amount: Int32
    @NSManaged public var isFormula: Bool

}
