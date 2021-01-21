//
//  ContentView.swift
//  SwiftUI-Navigation
//
//  Created by Philipp on 10.12.20.
//

import SwiftUI

struct ContentView: View {
    @State private var childIsShown = false
    var body: some View {
        NavigationView {
            ChildView(title: "Main", childID: 0, currentIsActive: .constant(true))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ChildView: View {

    @EnvironmentObject var state: AppState
    @Environment(\.presentationMode) var presentationMode

    let title: String
    let childID: Int

    @Binding var currentIsActive: Bool
    @State private var childIsActive = false
    @State private var counter = 0

    init(title: String, childID: Int, currentIsActive: Binding<Bool>) {
        print("init(\(title), \(childID))")
        self.title = title
        self.childID = childID
        self._currentIsActive = .init(get: { () -> Bool in
            currentIsActive.wrappedValue
        }, set: { (newValue) in
            print("Assigning \(newValue) to currentActive")
            currentIsActive.wrappedValue = newValue
        })

    }

    var body: some View {
        Form {
            Section(header: Text("Info")) {
                Text("activeViews = \(state.activeViewsDescription)")
                Text("currentIsActive = ")
                    + Text(currentIsActive.description)
                        .foregroundColor(currentIsActive ? Color.green : Color.primary)
                Text("childIsActive = ")
                + Text(childIsActive.description)
                    .foregroundColor(childIsActive ? Color.green : Color.primary)
            }

            List {
                if allowsMoreChildViews {
                    NavigationLink(
                        "Child \(childID+1)",
                        destination: ChildView(title: "Child \(childID+1)", childID: childID+1, currentIsActive: $childIsActive),
                        isActive: $childIsActive
                    )
                }
                else {
                    Text("This is the end")
                }

                Button("Push Child \(childID+1)") {
                    childIsActive.toggle()
                }
                .disabled(!allowsMoreChildViews)

                Button("Pop current") {
                    presentationMode.wrappedValue.dismiss()
                    //currentIsActive.toggle()
                }
                .disabled(childID == 0)

                Button("Count \(counter)") {
                    counter += 1
                }
            }
        }
        .navigationBarTitle(title)
        .onAppear() {
            print("onAppear: \(title) (depth=\(childID))")
            state.activeViews[childID, default: 0] += 1
        }
        .onDisappear() {
            print("onDisAppear: \(title) (depth=\(childID))")
            state.activeViews[childID, default: 0] -= 1
        }
    }

    var allowsMoreChildViews: Bool {
        childID < state.maxDepth
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
