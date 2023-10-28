//
//  ContentView.swift
//  MyHealthApp
//
//  Created by Rita Borlaug on 13/10/2023.
//

import SwiftUI
import HealthKit


struct HeartRateData: Identifiable {
    let date: Date
    let heartRate: Int
    var id: Date { date }
}

struct StepCountData: Identifiable {
    let date: Date
    let stepCount: Double
    var id: Date { date }
}

struct ContentView: View {
    @State private var dateOfBirth: Date?
    @State private var lastWorkoutDate: String?
    @State private var lastWorkoutTime: String?
    @State private var duration: String?
    @State private var workoutType: String?
    @State private var selectedDate = Date()
    @State private var restingHeartRateData: [HeartRateData] = []
    @State private var stepCountData: [StepCountData] = []
    private var healthKitManager = HealthKitManager()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Date of Birth")) {
                    if let dateOfBirth = dateOfBirth {
                        Text("\(dateOfBirth, formatter: DateFormatter.dateOnly)")
                    } else {
                        Text("Date of Birth: Not Available")
                    }
                }
                
                Section(header: Text("Last Workout")) {
                    if let lastWorkoutDate = lastWorkoutDate, let lastWorkoutTime = lastWorkoutTime, let duration = duration, let workoutType = workoutType {
                        Text("Date: \(lastWorkoutDate)")
                        Text("Starting time: \(lastWorkoutTime)")
                        Text("Duration: \(duration)")
                        Text("Type: \(workoutType)")
                    } else {
                        Text("No workout data available")
                    }
                }
                
                Section(header: Text("Resting Heart Rate")) {
                    if restingHeartRateData.isEmpty {
                        Text("No resting heart rate data available")
                    } else {
                        ForEach(restingHeartRateData) { data in
                            Text("\(data.date,formatter:DateFormatter.dateOnly)    -      \(data.heartRate) bpm")
                        }
                    }
                }
                
                Section(header: Text("Step Count")) {
                    if stepCountData.isEmpty {
                        Text("No step count data available")
                    } else {
                        ForEach(stepCountData) { data in
                            Text("\(data.date, formatter: DateFormatter.dateOnly)    -    \(Int(data.stepCount)) steps")
                        }
                    }
                }
            }
            
            .onAppear {
                healthKitManager.requestAuthorization { authorized in
                    if authorized {
                        let calendar = Calendar.current
                        let endDate = Date()
                        if let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) {
                            
                            healthKitManager.fetchDateOfBirth { date in
                                self.dateOfBirth = date
                            }
                            
                            healthKitManager.fetchLastWorkout { date, time, duration, type in
                                if let date = date, let time = time, let duration = duration, let type = type {
                                    self.lastWorkoutDate = date
                                    self.lastWorkoutTime = time
                                    self.duration = duration
                                    self.workoutType = type
                                }
                            }
                            
                            healthKitManager.fetchRestingHeartRate(startDate: startDate, endDate: endDate) {data in
                                if let data = data {
                                    self.restingHeartRateData = data.map {
                                        HeartRateData(date: $0.startDate,heartRate: Int($0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))))
                                    }
                                }
                            }

                            healthKitManager.fetchStepCounts(startDate: startDate, endDate: endDate) { data in
                                self.stepCountData = data
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Health Data")
        }
    }
}
