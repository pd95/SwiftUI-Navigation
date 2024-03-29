# SwiftUI Navigation

This project is about exploring the `NavigationView`, its features and oddities in full depth, as I run into problems whenever I use it. Therefore I will write here down all the lessons I've learned.

## Basics

### Setup and activation

The basic setup is of a `NavigationView` is hopefully known: There is a `NavigationView` containing a source view (also "main view") which is pushing a destination view whenever a `NavigationLink` is triggered/activated. The `NavigationLink` can be triggered by the user clicking it or toggling the boolean variable (if `isActive` is used on the `NavigationLink`).

```swift
NavigationView {
    VStack(spacing: 30) {
        Text("Main view")
            .font(.largeTitle)
        
        NavigationLink(destination: Text("Child view")) {
            Text("Click the link")
        }
    }
}
```

### Navigation bar title

If you want to  set a title for the view, you can use the `navigationTitle` (as of iOS 14) or the `navigationBarTitle` (in iOS 13) modifier.
You can set the title display mode to `.large`, `.inline` or `.automatic` (=default) using `navigationBarTitleDisplayMode` modifier.
.navigationBarTitle(title)
.navigationBarTitleDisplayMode(.inline)

```swift
NavigationView {
    VStack(spacing: 30) {
        NavigationLink(
            destination: Text("Child view")
                .navigationTitle("Child View")
                .navigationBarTitleDisplayMode(.inline)) {
            Text("Click the link")
        }
    }
    .navigationTitle("Main View")
}
```

### Hiding the "Back" button or the whole navigation bar

If you like the header generated by the NavigationBar, but do not want to allow the user to navigate back to the previous view, you can  remoge the "Back"  button and the related "swipe from the left edge" gesture using the `.navigationBarBackButtonHidden(true)` modifier.

If the top part occupied by the navigation view used to draw the title is not desired, each view (the main view and the each destination view) can hide it individually by applying the `navigationBarHidden(true)` modifier. But **be aware**: If the navigation bar is hidden, there is way for the user to get back to the source view. Neither tapping the "Back" button in the navigation bar nor swiping from the left edge will be possible. You will have to provide some programmatic way to continue navigation.

### Programmatic Navigation: "Push"

To push a view programmatically respectively to activate a `NavigationLink`, you can use a boolean state variable set initially to `false` and pass a binding to the `NavigationLink(destination:, isActive:)` initialiser. Then a `Button` can then toggle this state variable activating the `NavigationLink` and therefore initiating the transition to the destination view.

```swift
@State private var childIsShown = false

NavigationView {
    VStack {
        Button("Go to child view") {
            childIsShown.toggle()
        }
        
        // Hidden navigation link
        NavigationLink(destination: Text("Child view"), isActive: $childIsShown) {
            EmptyView()
        }.hidden()
    }
    .navigationTitle("Main View")
}
```

If you do not want the NavigationLink to be triggered directly by the user, you should hide it using the `.hidden` modifier and omitting the label or setting it to `EmptyView()`. This works great for regular VStacks, but in `Form` or `List` the existence of the `NavigationLink` is reason enough that a row is made visible by SwiftUI. To avoid this, it is possible to add the `NavigationLink` to the background of any child view as shown below:

```swift
Text("Some view")
    .background(
        NavigationLink(destination: Text("Child view"),
            isActive: $childIsShown,
            label: {})
    )
```

### Programmatic Navigation: "Pop"

We have already seen how we can "push" programmatically a destination view onto the navigation stack. But how do you "pop" the current view from the navigation stack? I have tried to pass a binding to the `isActive` boolean to the destination view which allows it to set it back to `false`, therefore "inactivating" the `NavigationLink` which pushed it in the first place.  
This approach works for two "push layers" only. As soon as you have three layers, the popping starts to work unreliable, because SwiftUI seems to "forget" that a NavigationLink is active, therefore toggling the boolean will push again the same view, or setting the boolean to `false` won't do what you expect: the `NavigationView` animates suddenly a push of a view instead of a pop.

The best and most reliable approach is the following: Adding the `presentationMode` environment key and using the `presentationMode.wrappedValue.dismiss()` within your button/action. This will consistently remove the top-most view independently whether it has been pushed "manually" or "programmatically".

```swift
@Environment(\.presentationMode) var presentationMode

Button("Pop current view") {
    presentationMode.wrappedValue.dismiss()
}
```

### onAppear() and onDisappear()

When a `NavigationLink` is activated in the source view, it will be pushed to the leading edge of the screen and the destination view will slide in from the trailing edge. The destination view will appear and the source view will disappear. This can also be confirmed by looking at the `onAppear` and `onDisappear` actions on the respective views.

- Startup:
  - Main appears

- `NavigationLink` triggered
  - Child appears
  - Main disappears

- "Back" navigation triggered
  - Main appears
  - Child disappears

If you look at it, this makes perfectly sense. But to be clear: you cannot easily use `onAppear` and `onDisappear` to maintain a stack of "active views" in your navigation stack (certainly not using simple `Array.push()` and `Array.removeLast()`).

So the question remains: How can we maintain a logical stack in our application which represents the list of currently active views?

**WARNING**: currently (iOS 14.3 - iOS 14.7) the  `onAppear` and `onDisappear` logic seems to be broken (in contrast to iOS 13.7): the initial screen which disappears when the first child is pushed will get a call to `onDisappear` and directly afterwards again `onAppear` even though it is not visible. So it is difficult to know when the first screen is visible again!
Atleast on iOS 15 beta 3 this bug seems to be finally fixed!

### Navigation bar items

In general it is desirable to put the most important actions into the navigation bar where the user finds them quickly. For example an "Add" button in a list view. To do this, there are different methods, depending of the target iOS version.

**For iOS 13** you use the `navigationBarItems(leading:, trailing)` modifier to any view embedded in the `NavigationView` (similar to `navigationBarTitle`). To help tapping the bar buttons you should increase the size of the `Button`s label to at least 44 px.

```swift
.navigationBarItems(trailing:
    Button(action: { childIsActive.toggle()}) {
        Image(systemName: "plus")
            .imageScale(.large)
            .frame(minWidth: 44, minHeight: 44)
    }
)
```

The views provided by the `leading` or `trailing` parameter are replacing the currently show bar button views, so it makes no sense to have multiple `navigationBarItems` modifier in the currently shown view.  
If you want to show multiple bar buttons, you can use a `HStack` to create multiple buttons side-by-side:

```swift
.navigationBarItems(
    trailing: HStack(spacing: 0) {
        Button(action: { childIsActive.toggle()}) {
            Image(systemName: "plus")
                .frame(minWidth: 44, minHeight: 44)
        }
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "minus")
                .frame(minWidth: 44, minHeight: 44)
        }
    }
    .imageScale(.large)
)
```

**For iOS 14** you would normally use the more powerful `toolbar` modifier and the `ToolbarItem`.

```swift
.toolbar {
    ToolbarItem(id: "Push", placement: .navigationBarTrailing) {
        Button(action: { childIsActive.toggle()}) {
            Image(systemName: "plus")
                .imageScale(.large)
                .frame(minWidth: 44, minHeight: 44)
        }
    }
}
```

If you want to add multiple buttons to the same area, you can use the `ToolbarItemGroup` instead:

```swift
.toolbar {
    ToolbarItemGroup(placement: .navigationBarTrailing) {
        Button(action: { childIsActive.toggle()}) {
            Image(systemName: "plus")
                .imageScale(.large)
                .frame(minWidth: 44, minHeight: 44)
        }
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "minus")
                .imageScale(.large)
                .frame(minWidth: 44, minHeight: 44)
        }
    }
}
```

The newly added `placement` parameter allows to place buttons in nearly any area you like: `automatic`, `bottomBar`, `cancellationAction`, `confirmationAction`, `destructiveAction`, `navigation`, `navigationBarLeading`, `navigationBarTrailing`, `primaryAction`, `principal` and `status`.

**Be aware:** in iOS 14 we experience a sudden disappearance of the "Back" button when the navigation stack increases to 3. I don't know if this is intended or whether it is a bug.  
There is a workaround: add the following modifier to your `NavigationView`: `.navigationViewStyle(StackNavigationViewStyle())`

### Navigation View Styles

In general, it is a good idea to set the appropriate `NavigationViewStyle` to the behaviour you expect from your `NavigationView`, as you can avoid a lot of strange bugs/behaviours by using the correct one!

- `StackNavigationViewStyle()` represents the single view stack where only a single top view is shown at a time.
- `DoubleColumnNavigationViewStyle()` represents the primary view/detail view stack, where an entry in the primary view (on the left side) is updating the detail view (on the right side). This is generally the default style for `NavigationView` on an iPad or an bigger iPhone in landscape orientation!  
  If you use this style, make sure you add two views as children to the `NavigationView`. The first represents the primary view and the second is a placeholder for the detail view.

  If your goal is to have sidebar along with the primary/detail view, check-out the my [SwiftUI-Siderbar project](https://github.com/pd95/SwiftUI-Sidebar) where I tackle common problems like row highlighting and navigation.

To set a correct navigation style, it is important to apply the `navigationViewStyle` modifier to the `NavigationView` itself and **not** like the navigation bar title to the child view! See the example below:

```swift
NavigationView {
    Form {
        Text("Hello world!")
    }
}
.navigationViewStyle(StackNavigationViewStyle())
```
