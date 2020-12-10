//
//  SwiftUI_NavigationApp.swift
//  SwiftUI-Navigation
//
//  Created by Philipp on 10.12.20.
//

import SwiftUI

@main
struct SwiftUI_NavigationApp: App {
    @StateObject var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
        }
    }
}
