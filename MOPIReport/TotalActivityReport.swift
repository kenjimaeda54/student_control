//
//  TotalActivityReport.swift
//  MOPIReport
//
//  Created by kenjimaeda on 14/03/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI
internal import ManagedSettings

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
        let content: (String) -> TotalActivityView
        
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        
        var appNames: [String] = []
        var totalDuration: TimeInterval = 0
        
        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalDuration += segment.totalActivityDuration
                
                for await category in segment.categories {
                    for await app in category.applications {
                        let name = app.application.localizedDisplayName ?? "App desconhecido"
                        appNames.append(name)
                        print(name)
                    }
                }
            }
        }
        
        if let sharedDefaults = UserDefaults(suiteName: "group.com.moppi.student") {
            sharedDefaults.set(appNames, forKey: "last_selection_bundles")
            sharedDefaults.synchronize()
            print(appNames)
        }
        
        return formatter.string(from: totalDuration) ?? "No activity data"
    }
}
