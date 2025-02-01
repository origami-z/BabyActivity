//
//  SleepEntity+CoreDataProperties.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//
//

import Foundation
import CoreData


extension SleepEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepEntity> {
        return NSFetchRequest<SleepEntity>(entityName: "SleepEntity")
    }

    @NSManaged public var endTime: Date?

}


extension SleepEntity {
    convenience init(
    context moc: NSManagedObjectContext,
    timestamp: Date,
    endTime: Date? = nil
  ) {
      self.init(context: moc)

      self.timestamp = timestamp
      self.endTime = endTime
  }
}
