//
//  ChildMockStubbableTests.swift
//  MockingbirdTests
//
//  Created by Andrew Chang on 8/16/19.
//  Copyright © 2019 Bird Rides, Inc. All rights reserved.
//

import Foundation
import Mockingbird
@testable import MockingbirdTestsHost

// MARK: - Stubbable declarations

private protocol StubbableChild {
  // MARK: Child
  func getChildComputedInstanceVariable() -> Mockable<VariableDeclaration, () -> Bool, Bool>
  
  func childTrivialInstanceMethod() -> Mockable<FunctionDeclaration, () -> Void, Void>
  func childParameterizedInstanceMethod(param1: @escaping @autoclosure () -> Bool,
                                        _ param2: @escaping @autoclosure () -> Int)
    -> Mockable<FunctionDeclaration, (Bool, Int) -> Bool, Bool>
  
  static func getChildClassVariable() -> Mockable<VariableDeclaration, () -> Bool, Bool>
  static func childTrivialClassMethod() -> Mockable<FunctionDeclaration, () -> Void, Void>
  static func childParameterizedClassMethod(param1: @escaping @autoclosure () -> Bool,
                                            _ param2: @escaping @autoclosure () -> Int)
    -> Mockable<FunctionDeclaration, (Bool, Int) -> Bool, Bool>
  
  // MARK: Parent
  func getParentComputedInstanceVariable() -> Mockable<VariableDeclaration, () -> Bool, Bool>
  
  func parentTrivialInstanceMethod() -> Mockable<FunctionDeclaration, () -> Void, Void>
  func parentParameterizedInstanceMethod(param1: @escaping @autoclosure () -> Bool,
                                         _ param2: @escaping @autoclosure () -> Int)
    -> Mockable<FunctionDeclaration, (Bool, Int) -> Bool, Bool>
  
  static func getParentClassVariable() -> Mockable<VariableDeclaration, () -> Bool, Bool>
  static func parentTrivialClassMethod() -> Mockable<FunctionDeclaration, () -> Void, Void>
  static func parentParameterizedClassMethod(param1: @escaping @autoclosure () -> Bool,
                                             _ param2: @escaping @autoclosure () -> Int)
    -> Mockable<FunctionDeclaration, (Bool, Int) -> Bool, Bool>
  
  // MARK: Grandparent
  func getGrandparentComputedInstanceVariable() -> Mockable<VariableDeclaration, () -> Bool, Bool>
  
  func grandparentTrivialInstanceMethod() -> Mockable<FunctionDeclaration, () -> Void, Void>
  func grandparentParameterizedInstanceMethod(param1: @escaping @autoclosure () -> Bool,
                                              _ param2: @escaping @autoclosure () -> Int)
    -> Mockable<FunctionDeclaration, (Bool, Int) -> Bool, Bool>
  
  static func getGrandparentClassVariable() -> Mockable<VariableDeclaration, () -> Bool, Bool>
  static func grandparentTrivialClassMethod() -> Mockable<FunctionDeclaration, () -> Void, Void>
  static func grandparentParameterizedClassMethod(param1: @escaping @autoclosure () -> Bool,
                                                  _ param2: @escaping @autoclosure () -> Int)
    -> Mockable<FunctionDeclaration, (Bool, Int) -> Bool, Bool>
}
extension ChildMock: StubbableChild {}

// MARK: - Non-stubbable declarations

extension ChildMock {
  func setChildComputedInstanceVariable(_ newValue: @escaping @autoclosure () -> Bool)
    -> Mockable<VariableDeclaration, (Bool) -> Void, Void> { fatalError() }
  static func setChildClassVariable(_ newValue: @escaping @autoclosure () -> Bool)
    -> Mockable<VariableDeclaration, (Bool) -> Void, Void> { fatalError() }
  
  func setParentComputedInstanceVariable(_ newValue: @escaping @autoclosure () -> Bool)
    -> Mockable<VariableDeclaration, (Bool) -> Void, Void> { fatalError() }
  static func setParentClassVariable(_ newValue: @escaping @autoclosure () -> Bool)
    -> Mockable<VariableDeclaration, (Bool) -> Void, Void> { fatalError() }
  
  func setGrandparentComputedInstanceVariable(_ newValue: @escaping @autoclosure () -> Bool)
    -> Mockable<VariableDeclaration, (Bool) -> Void, Void> { fatalError() }
  static func setGrandparentClassVariable(_ newValue: @escaping @autoclosure () -> Bool)
    -> Mockable<VariableDeclaration, (Bool) -> Void, Void> { fatalError() }
}
