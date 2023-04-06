// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

argument = ["D": 1, "C": 1, "imports": [A, B], "testable_imports": B]


final class IViewModelsFactoryMock: IViewModelsFactory {




    // MARK: - buildViewModel

    var buildViewModelCallsCount = 0
    var buildViewModelCalled: Bool {
        return buildViewModelCallsCount > 0
    }
    var buildViewModelReturnValue: [String]!
    var buildViewModelClosure: (() -> [String])?

    func buildViewModel() -> [String] {
        buildViewModelCallsCount += 1
        if let buildViewModelClosure = buildViewModelClosure {
            return buildViewModelClosure()
        } else {
            return buildViewModelReturnValue
        }
    }

}
