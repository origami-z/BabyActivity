//
//  Persistence.swift
//  BabyActivity
//
//  Created by Zhihao Cui on 01/02/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static func addSimulatedData(viewContext: NSManagedObjectContext) {
        for i in 0...5 {
            let startingTimeInterval = Double(i) * 60 * -60 * 24 // -i day
            let hourInterval = Double(60 * 60)
            
            let startOfToday = Calendar.current.startOfDay(for: Date())
            
            // sleeps
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval - hourInterval), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 0.5)) // cross-over from previous day
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 2), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 3.5))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 5), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 5.8))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9.6))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 14), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.2))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 17), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 18.1))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 20.5), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 21.7))
            
            // milk
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 1.5), amount: Int32(30 * i))
            
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 6.5), amount: Int32(30 * i))
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 11.2), amount: Int32(30 * i))
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.7), amount: Int32(30 * i))
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 20), amount: Int32(30 * i))
            
            // diaper
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 1.1), isWet: false, isDirty: true)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 3.7), isWet: true, isDirty: false)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 6), isWet: true, isDirty: false)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9.9), isWet: true, isDirty: true)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.4),isWet: true, isDirty: false)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 19.4), isWet: true, isDirty: false)
        }
        
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    
    @MainActor
    static let sleepActivityPreview: SleepActivity = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let sleepActivity = SleepActivity(context: viewContext, timestamp: Date())
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return sleepActivity
    }()
    
    
    @MainActor
    static let milkActivityPreview: MilkActivity = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let activity = MilkActivity(context: viewContext, timestamp: Date(), amount: 90)
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return activity
    }()
    
    @MainActor
    static let diaperActivityPreview: DiaperActivity = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let activity = DiaperActivity(context: viewContext, timestamp: Date(), isWet: true, isDirty: false)
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return activity
    }()
    
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        for i in 0...5 {
            let startingTimeInterval = Double(i) * 60 * -60 * 24 // -i day
            let hourInterval = Double(60 * 60)
            
            let startOfToday = Calendar.current.startOfDay(for: Date())
            
            // sleeps
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval - hourInterval), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 0.5)) // cross-over from previous day
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 2), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 3.5))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 5), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 5.8))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9.6))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 14), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.2))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 17), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 18.1))
            _ = SleepActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 20.5), endTime: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 21.7))
            
            // milk
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 1.5), amount: Int32(30 * i))
            
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 6.5), amount: Int32(30 * i))
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 11.2), amount: Int32(30 * i))
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.7), amount: Int32(30 * i))
            _ = MilkActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 20), amount: Int32(30 * i))
            
            // diaper
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 1.1), isWet: false, isDirty: true)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 3.7), isWet: true, isDirty: false)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 6), isWet: true, isDirty: false)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 9.9), isWet: true, isDirty: true)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 15.4),isWet: true, isDirty: false)
            _ = DiaperActivity(context: viewContext, timestamp: startOfToday.addingTimeInterval(startingTimeInterval + hourInterval * 19.4), isWet: true, isDirty: false)
        }
        
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
            }
        }
    }
    
    let container: NSPersistentCloudKitContainer
//    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "BabyActivityModel")
//        container = NSPersistentContainer(name: "BabyActivityModel") //

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
