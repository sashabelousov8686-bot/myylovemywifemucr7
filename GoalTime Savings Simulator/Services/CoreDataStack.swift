import Foundation
import CoreData

// MARK: - Programmatic Core Data Stack (no .xcdatamodeld needed)

final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    init(inMemory: Bool = false) {
        // Create model programmatically
        let model = Self.createModel()
        container = NSPersistentContainer(name: "GoalTimeSavings", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Log and attempt recovery - delete the store and retry
                print("Core Data load error: \(error), \(error.userInfo)")
                if let storeURL = self.container.persistentStoreDescriptions.first?.url {
                    try? FileManager.default.removeItem(at: storeURL)
                    self.container.loadPersistentStores { _, retryError in
                        if retryError != nil {
                            print("Core Data recovery failed: \(retryError!)")
                        }
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Programmatic Model Definition
    
    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // SavingsGoal Entity
        let goalEntity = NSEntityDescription()
        goalEntity.name = "SavingsGoalEntity"
        goalEntity.managedObjectClassName = NSStringFromClass(SavingsGoalEntity.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        nameAttr.defaultValue = ""
        
        let targetAmountAttr = NSAttributeDescription()
        targetAmountAttr.name = "targetAmount"
        targetAmountAttr.attributeType = .doubleAttributeType
        targetAmountAttr.defaultValue = 0.0
        
        let targetDateAttr = NSAttributeDescription()
        targetDateAttr.name = "targetDate"
        targetDateAttr.attributeType = .dateAttributeType
        targetDateAttr.isOptional = true
        
        let currentSavingsAttr = NSAttributeDescription()
        currentSavingsAttr.name = "currentSavings"
        currentSavingsAttr.attributeType = .doubleAttributeType
        currentSavingsAttr.defaultValue = 0.0
        
        let monthlyDepositAttr = NSAttributeDescription()
        monthlyDepositAttr.name = "monthlyDeposit"
        monthlyDepositAttr.attributeType = .doubleAttributeType
        monthlyDepositAttr.defaultValue = 0.0
        
        let expectedReturnAttr = NSAttributeDescription()
        expectedReturnAttr.name = "expectedReturn"
        expectedReturnAttr.attributeType = .doubleAttributeType
        expectedReturnAttr.defaultValue = 7.0
        
        let inflationRateAttr = NSAttributeDescription()
        inflationRateAttr.name = "inflationRate"
        inflationRateAttr.attributeType = .doubleAttributeType
        inflationRateAttr.defaultValue = 3.0
        
        let currencyAttr = NSAttributeDescription()
        currencyAttr.name = "currency"
        currencyAttr.attributeType = .stringAttributeType
        currencyAttr.defaultValue = "USD"
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        let isPrimaryAttr = NSAttributeDescription()
        isPrimaryAttr.name = "isPrimary"
        isPrimaryAttr.attributeType = .booleanAttributeType
        isPrimaryAttr.defaultValue = false
        
        let userAgeAttr = NSAttributeDescription()
        userAgeAttr.name = "userAge"
        userAgeAttr.attributeType = .integer32AttributeType
        userAgeAttr.defaultValue = 30
        
        goalEntity.properties = [
            idAttr, nameAttr, targetAmountAttr, targetDateAttr,
            currentSavingsAttr, monthlyDepositAttr, expectedReturnAttr,
            inflationRateAttr, currencyAttr, createdAtAttr, isPrimaryAttr,
            userAgeAttr
        ]
        
        // Milestone Entity
        let milestoneEntity = NSEntityDescription()
        milestoneEntity.name = "MilestoneEntity"
        milestoneEntity.managedObjectClassName = NSStringFromClass(MilestoneEntity.self)
        
        let msIdAttr = NSAttributeDescription()
        msIdAttr.name = "id"
        msIdAttr.attributeType = .UUIDAttributeType
        msIdAttr.isOptional = false
        
        let msNameAttr = NSAttributeDescription()
        msNameAttr.name = "name"
        msNameAttr.attributeType = .stringAttributeType
        msNameAttr.defaultValue = ""
        
        let msAgeAttr = NSAttributeDescription()
        msAgeAttr.name = "targetAge"
        msAgeAttr.attributeType = .integer32AttributeType
        msAgeAttr.defaultValue = 35
        
        let msAmountAttr = NSAttributeDescription()
        msAmountAttr.name = "targetAmount"
        msAmountAttr.attributeType = .doubleAttributeType
        msAmountAttr.defaultValue = 0.0
        
        let msIconAttr = NSAttributeDescription()
        msIconAttr.name = "icon"
        msIconAttr.attributeType = .stringAttributeType
        msIconAttr.defaultValue = "star.fill"
        
        // Relationship: Milestone -> Goal
        let milestoneToGoal = NSRelationshipDescription()
        milestoneToGoal.name = "goal"
        milestoneToGoal.destinationEntity = goalEntity
        milestoneToGoal.maxCount = 1
        milestoneToGoal.minCount = 0
        milestoneToGoal.isOptional = true
        milestoneToGoal.deleteRule = .nullifyDeleteRule
        
        // Relationship: Goal -> Milestones
        let goalToMilestones = NSRelationshipDescription()
        goalToMilestones.name = "milestones"
        goalToMilestones.destinationEntity = milestoneEntity
        goalToMilestones.maxCount = 0 // to-many
        goalToMilestones.minCount = 0
        goalToMilestones.isOptional = true
        goalToMilestones.deleteRule = .cascadeDeleteRule
        
        milestoneToGoal.inverseRelationship = goalToMilestones
        goalToMilestones.inverseRelationship = milestoneToGoal
        
        milestoneEntity.properties = [msIdAttr, msNameAttr, msAgeAttr, msAmountAttr, msIconAttr, milestoneToGoal]
        goalEntity.properties.append(goalToMilestones)
        
        model.entities = [goalEntity, milestoneEntity]
        
        return model
    }
    
    // MARK: - CRUD Operations
    
    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }
    
    func createGoal(
        name: String,
        targetAmount: Double,
        targetDate: Date?,
        currentSavings: Double,
        monthlyDeposit: Double,
        expectedReturn: Double,
        inflationRate: Double,
        currency: String,
        isPrimary: Bool = true,
        userAge: Int = 30
    ) -> SavingsGoalEntity {
        let goal = SavingsGoalEntity(context: viewContext)
        goal.id = UUID()
        goal.name = name
        goal.targetAmount = targetAmount
        goal.targetDate = targetDate
        goal.currentSavings = currentSavings
        goal.monthlyDeposit = monthlyDeposit
        goal.expectedReturn = expectedReturn
        goal.inflationRate = inflationRate
        goal.currency = currency
        goal.createdAt = Date()
        goal.isPrimary = isPrimary
        goal.userAge = Int32(userAge)
        
        // If setting as primary, unset others
        if isPrimary {
            unsetOtherPrimaries(except: goal)
        }
        
        save()
        return goal
    }
    
    private func unsetOtherPrimaries(except goal: SavingsGoalEntity) {
        guard let goalId = goal.id else { return }
        let request = SavingsGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isPrimary == YES AND id != %@", goalId as CVarArg)
        
        if let others = try? viewContext.fetch(request) {
            for other in others {
                other.isPrimary = false
            }
        }
    }
    
    func fetchPrimaryGoal() -> SavingsGoalEntity? {
        let request = SavingsGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isPrimary == YES")
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    func fetchAllGoals() -> [SavingsGoalEntity] {
        let request = SavingsGoalEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)]
        return (try? viewContext.fetch(request)) ?? []
    }
    
    func deleteGoal(_ goal: SavingsGoalEntity) {
        viewContext.delete(goal)
        save()
    }
}

// MARK: - NSManagedObject Subclasses

@objc(SavingsGoalEntity)
public class SavingsGoalEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var targetAmount: Double
    @NSManaged public var targetDate: Date?
    @NSManaged public var currentSavings: Double
    @NSManaged public var monthlyDeposit: Double
    @NSManaged public var expectedReturn: Double
    @NSManaged public var inflationRate: Double
    @NSManaged public var currency: String
    @NSManaged public var createdAt: Date?
    @NSManaged public var isPrimary: Bool
    @NSManaged public var userAge: Int32
    @NSManaged public var milestones: NSSet?
    
    public static func fetchRequest() -> NSFetchRequest<SavingsGoalEntity> {
        return NSFetchRequest<SavingsGoalEntity>(entityName: "SavingsGoalEntity")
    }
    
    var yearsToTarget: Double {
        guard let targetDate = targetDate else { return 20 }
        let interval = targetDate.timeIntervalSince(Date())
        return max(1, interval / (365.25 * 24 * 3600))
    }
    
    var milestonesArray: [MilestoneEntity] {
        let set = milestones as? Set<MilestoneEntity> ?? []
        return set.sorted { $0.targetAge < $1.targetAge }
    }
}

@objc(MilestoneEntity)
public class MilestoneEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var targetAge: Int32
    @NSManaged public var targetAmount: Double
    @NSManaged public var icon: String
    @NSManaged public var goal: SavingsGoalEntity?
    
    public static func fetchRequest() -> NSFetchRequest<MilestoneEntity> {
        return NSFetchRequest<MilestoneEntity>(entityName: "MilestoneEntity")
    }
}

// MARK: - Preview Helper

extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
}
