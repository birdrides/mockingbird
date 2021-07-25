//
//  ExceptionsStubbableTests.swift
//  MockingbirdTests
//
//  Created by Andrew Chang on 9/14/19.
//

import Foundation
import Mockingbird
@testable import MockingbirdTestsHost

// MARK: - Stubbable declarations

private protocol StubbableThrowingProtocol: Mock {
  func throwingMethod() throws -> Mockable<ThrowingFunctionDeclaration, () throws -> Void, Void>
  func throwingMethod() throws -> Mockable<ThrowingFunctionDeclaration, () throws -> Bool, Bool>
  func throwingMethod(block: @escaping @autoclosure () -> () throws -> Bool) throws
    -> Mockable<ThrowingFunctionDeclaration, (() throws -> Bool) throws -> Void, Void>
}
extension ThrowingProtocolMock: StubbableThrowingProtocol {}

private protocol StubbableRethrowingProtocol: RethrowingProtocol, Mock {
  // @nocommit
  func rethrowingMethod(block: @escaping @autoclosure () -> () throws -> Bool)
    -> Mockable<ThrowingFunctionDeclaration, (() throws -> Bool) throws -> Void, Void>
  func rethrowingMethod(block: @escaping @autoclosure () -> () throws -> Bool)
    -> Mockable<ThrowingFunctionDeclaration, (() throws -> Bool) throws -> Bool, Bool>
}
extension RethrowingProtocolMock: StubbableRethrowingProtocol {}
