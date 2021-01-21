//
//  AppState.swift
//  Navigation
//
//  Created by Philipp on 10.12.20.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var maxDepth: Int = 5
    @Published var activeViews: [Int:Int] = [:]
    
    var activeViewsDescription: String {
        let r = activeViews.keys.sorted()
            .reduce("[") { (r: String, key: Int) in
                "\(r)\(key):\(activeViews[key]!),"
            }
            .dropLast()
            .appending("]")
        
        return r
    }
}
