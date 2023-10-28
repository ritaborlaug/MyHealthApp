//
//  HealthKitManager.swift
//  MyHealthApp
//
//  Created by Rita Borlaug on 13/10/2023.
//

import Foundation
import HealthKit
// import SwiftHAPIFHIR

class HealthKitManager {
    var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            fatalError("HealthKit is not available on this device.")
        }
    }
    
    
    // Request HealthKit authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
        let workoutType = HKWorkoutType.workoutType()
        let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        if let healthStore = healthStore {
            healthStore.requestAuthorization(toShare: nil, read: [dateOfBirthType, workoutType, restingHeartRateType, stepCountType, sleepType]) { (success, error) in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    
    // Fetch the date of birth
    func fetchDateOfBirth(completion: @escaping (Date?) -> Void) {
        guard let healthStore = healthStore, HKHealthStore.isHealthDataAvailable() else {
            completion(nil)
            return
        }
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            if let validDateOfBirth = dateOfBirth.date {
                completion(validDateOfBirth)
            } else {
                completion(nil)
            }
        } catch {
            print("Error fetching date of birth: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    
    // Fetch the last registered workout
    func fetchLastWorkout(completion: @escaping (String?, String?, String?, String?) -> Void) {
        let workoutType = HKWorkoutType.workoutType()

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            if let workout = results?.first as? HKWorkout {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd. MMM yyyy"
                let date = dateFormatter.string(from: workout.startDate)
                
                dateFormatter.dateFormat = "HH:mm"
                let time = dateFormatter.string(from: workout.startDate)
                
                let startDate = date
                let startTime = time
                let endDate = workout.endDate
                let duration = Int(endDate.timeIntervalSince(workout.startDate))
                let hours = duration / 3600
                let minutes = (duration % 3600) / 60
                
                let durationString: String
                if hours > 0 {
                    if minutes > 0 {
                        durationString = "\(hours) hour(s) \(minutes) minute(s)"
                    } else {
                        durationString = "\(hours) hour(s)"
                    }
                } else {
                    durationString = "\(minutes) minute(s)"
                }
                
                let workoutType = workout.workoutActivityType
                let typeString = self.workoutTypeString(workoutType)
                
                completion(startDate, startTime, durationString, typeString)
            } else {
                completion(nil, nil, nil, nil) // Handle the case where no workout data is available
            }
        }
        HKHealthStore().execute(query)
    }

    
    // Turns workout type into readable string to display
    func workoutTypeString(_ workoutType: HKWorkoutActivityType) -> String {
        switch workoutType {
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .hiking:
            return "Hiking"
        case .walking:
            return "Walking"
        // Add more cases for other workout types as needed
        default:
            return "Other"
        }
    }
    
    
    // Fetch resting heart rates
    func fetchRestingHeartRate(startDate: Date, endDate: Date, completion: @escaping ([HKQuantitySample]?) -> Void) {
        guard let healthStore = healthStore, HKHealthStore.isHealthDataAvailable() else {
            completion(nil)
            return
        }
        let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let query = HKSampleQuery(sampleType: restingHeartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            if let error = error {
                print("Error fetching resting heart rate data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let results = results as? [HKQuantitySample] {
                completion(results)
            } else {
                completion(nil)
            }
        }
        healthStore.execute(query)
    }
    
    
    // Fetch step counts
    func fetchStepCounts(startDate: Date, endDate: Date, completion: @escaping ([StepCountData]) -> Void) {
        guard let healthStore = healthStore, HKHealthStore.isHealthDataAvailable() else {
            completion([])
            return
        }
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let query = HKStatisticsCollectionQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startDate, intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = { query, results, error in
            if let error = error {
                print("Error fetching step count: \(error.localizedDescription)")
                completion([])
                return
            }
            var stepCountData: [StepCountData] = []
            if let results = results {
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    if let count = statistics.sumQuantity() {
                        let stepCountDataItem = StepCountData(date: statistics.startDate, stepCount: count.doubleValue(for: HKUnit.count()))
                        stepCountData.append(stepCountDataItem)
                    }
                }
            }
            completion(stepCountData)
        }
        healthStore.execute(query)
    }
}
