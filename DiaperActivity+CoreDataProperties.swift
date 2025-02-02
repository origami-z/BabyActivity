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

extension DiaperActivity {
    convenience init(
    context moc: NSManagedObjectContext,
    timestamp: Date,
    isWet: Bool = true,
    isDirty: Bool = false
  ) {
      self.init(context: moc)

      self.timestamp = timestamp
      self.type = .Diaper
      self.isWet = isWet
      self.isDirty = isDirty
  }
}

extension DiaperActivity {
    override func getKind() -> String {
        return "Diaper" // wet / dirty
    }
    
    override func getImage() -> String {
        return self.isDirty ? "tornado" : "toilet"
    }
    
    override func getShortDescription() -> String {
        return "\(self.isDirty ? "Dirty " : "")\(self.isWet ? "Wet " : "")Diaper"
    }
}
