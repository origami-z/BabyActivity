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

extension MilkActivity {
    convenience init(
    context moc: NSManagedObjectContext,
    timestamp: Date,
    amount: Int32,
    isFormula: Bool = true
  ) {
      self.init(context: moc)

      self.timestamp = timestamp
      self.type = .Milk
      self.amount = amount
      self.isFormula = isFormula
  }
}

extension MilkActivity {
    override func getKind() -> String {
        return "Milk" 
    }
    
    override func getImage() -> String {
        return "backpack.circle"
    }
    
    override func getShortDescription() -> String {
        return "Milk \(self.amount)ml" // todo formula
    }
}
