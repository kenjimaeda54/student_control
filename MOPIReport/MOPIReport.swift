//
//  MOPIReport.swift
//  MOPIReport
//
//  Created by kenjimaeda on 14/03/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct MOPIReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
