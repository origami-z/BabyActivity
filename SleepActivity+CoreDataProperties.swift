//
//  SleepEntity+CoreDataProperties.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//
//

import Foundation
import CoreData


extension SleepActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepActivity> {
        return NSFetchRequest<SleepActivity>(entityName: "SleepActivity")
    }

    @NSManaged public var endTime: Date?

}


extension SleepActivity {
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

extension SleepActivity {
    override func getKind() -> String {
        return "Sleep"
    }
    
    override func getImage() -> String {
        return "zzz"
    }
    
    override func getShortDescription() -> String {
        return "Sleep" // todo length
    }
}
