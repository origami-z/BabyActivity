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

extension CustomActivity {
    convenience init(
    context moc: NSManagedObjectContext,
    timestamp: Date,
    message: String? = nil
  ) {
      self.init(context: moc)

      self.timestamp = timestamp
      self.type = .Custom
      self.message = message
  }
}

extension CustomActivity {
    override func getKind() -> String {
        return "Custom" // self.message?
    }
    
    override func getImage() -> String {
        return "document.badge.clock"
    }
    
    override func getShortDescription() -> String {
        return self.message ?? "Custom activity"
    }
}
