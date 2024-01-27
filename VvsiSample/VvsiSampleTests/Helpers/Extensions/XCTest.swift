import Foundation
import XCTest


/// Used by unit tests to capture and object or value during an asynchronous operation.
/// i.e. Inside of a Combine `.sink {}` closure.
class CapturedObject<T> {
    var object: T?
}


extension XCTestCase {

    /// Wait for the given predicate to evaluate to true or for the specified timeout to expire,
    /// whichever comes first.
    func wait(forPredicate predicate: NSPredicate,
              evaluateWith evaluationObject: Any,
              timeout: TimeInterval) async -> Bool {
        let startTime = Date()
        var didSucceed = false

        while startTime.timeIntervalSinceNow > -timeout && !didSucceed {
            // wait for a few milliseconds to avoid a completely busy wait.
            try? await Task.sleep(for: .milliseconds(timeout / 1000))
            didSucceed = predicate.evaluate(with: evaluationObject)
        }

        return didSucceed
    }

    /// Wait for the specified value to be set on the given object.
    ///
    /// This method is used to validate values that are published by the object being tested.
    /// It needs to wait because publishing is, by nature, asynchronous.
    /// - parameters:
    ///  - state: The state that is expected on the given view interactor once async tasks complete.
    ///  - viewInteractor: The view interactor on which async tasks are in process.
    func expect<T: Equatable>(value: T, on capturedObject: CapturedObject<T>) async {
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! CapturedObject<T>).object == value
        }

        if await wait(forPredicate: predicate, evaluateWith: capturedObject, timeout: 0.5) == false {
            XCTFail("Value \(value) was not set in the allotted time. Actual value: \(String(describing: capturedObject.object))")
        }
    }
}
