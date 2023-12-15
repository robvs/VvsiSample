# VvsiSample
This is a sample application that illustrates use of the VVSI UI design pattern in SwiftUI.

VVSI stands for View-ViewState-ViewInteractor. It's a design pattern born out of MVVM while borrowing a little from MVC and VIP. VVSI is intended to provide a consistent and clear approach towards organizing view-related code.

## Background

### MVC
MVC (model-view-controller) is the natural design pattern for use in UIKit applications. In practice in iOS applications, you'd often end up with a View Controller that's bloated, difficult to maintain and difficult to test.

### MVVM
MVVM (model-view-view model) is a more natural design pattern for use in SwiftUI applications. It is an improvement over MVC, but View Models still tend to include too much business logic and have too many dependencies. This leads to overly complicated preview code and overly complicated unit tests for many of the views in an application.

## VVSI
VVSI (View-View State-View Interactor) attempts to address the primary issues with complex MVVM scenarios and provides guidelines for when the overhead of a View State or View Interactor is or isn't warranted.

### View
A SwiftUI View provides the layout of a full screen or a subview.

Views should follow these guidelines:

- Hard-code values that are never change. I'm not saying to pepper your view code with magic strings and numbers (those should still be stored in constants or wherever your app stores them). I'm saying that static values should not come from the View State object.
- Use calculated properties and functions to encapsulate logical subviews and to keep the main layout code clean and readable.
- Avoid business/domain logic. This includes avoiding simple logic that is based on model values. For example, if a subview is shown or hidden based on whether a particular model value is or isn't nil, then the View State should provide an "is shown" property to be used by the View. This make the View State object a closer proxy to the View and helps the View State unit tests to indicate intent.

### View State
A View State is tightly coupled to a view, usually via an `EnvironmentObject` or `ObservedObject`. It supplies values to the view that need to be determined at runtime.

View States should follow these guidelines:

- Create a View State for full-screen views and for sub views that have enough complexity to warrant it. View State objects are generally not necessary for simple sub views such as buttons.
- Use @Published properties for all dynamic values (values that may change during the view's lifetime).
- Use regular `let` properties for values that are determined at runtime but do not change during the view's lifecycle.
- Avoid business/domain logic. Logic should be focussed on transforming model values into what's needed for the View.
- Avoid dependencies on system resources such as databases, web services, etc. that's what View Interactors are for.

The View and View State are tightly coupled and should be all that is needed to render previews. Although some simple model objects are often needed as well.

Unit tests of View States focus on validating screen element changes and, when done correctly, avoid the complexities of use cases or mocked system resources

### View Interactor
A View Interactor handles interactions between the View/View State and the rest of the system.

View Interactors should follow these guidelines:

- Create a View Interactor for views that require interaction with the rest of the system. If a view does not need to interact with the rest of the system (i.e. the view simply gathers info from the user), then a View Interactor should not be created for that view.
- Dependencies include system resources such as databases and web services. However, I recommend wrapping most behavior inside of Use Case objects. This helps cut down on the number of dependencies inside the View Interactor and also results in cleaner code.
- This is were business/domain logic required by a view is performed. But, in general, avoid transformation logic between a domain object and what's needed for the View - that is what the View State is for.
