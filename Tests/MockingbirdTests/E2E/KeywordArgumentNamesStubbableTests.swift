import Foundation
import Mockingbird
@testable import MockingbirdTestsHost

// MARK: - Stubbable declarations

private protocol StubbableKeywordArgNamesProtocol {
  func methodWithKeywordParam(`inout`: @autoclosure () -> String)
      -> Mockable<FunctionDeclaration, (String) -> Void, Void>
  func methodWithNamedKeywordParam(with `inout`: @autoclosure () -> String)
      -> Mockable<FunctionDeclaration, (String) -> Void, Void>
  func methodWithUnnamedKeywordParam(_ `inout`: @autoclosure () -> String)
      -> Mockable<FunctionDeclaration, (String) -> Void, Void>
  func methodWithParamNamedKeyword(`inout` param: @autoclosure () -> String)
      -> Mockable<FunctionDeclaration, (String) -> Void, Void>
}

extension KeywordArgNamesProtocolMock: StubbableKeywordArgNamesProtocol {}

extension KeywordArgNamesClassMock: StubbableKeywordArgNamesProtocol {}
