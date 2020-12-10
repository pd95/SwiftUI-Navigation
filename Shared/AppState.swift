//
//  AppState.swift
//  Navigation
//
//  Created by Philipp on 10.12.20.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var maxDepth: Int = 5
    @Published var navigationStack: [Int] = []
    @Published var activeViews: [Int:Int] = [:]
}
