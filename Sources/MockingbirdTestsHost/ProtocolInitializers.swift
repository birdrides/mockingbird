import Foundation

protocol NoInitializerProtocol {}

protocol EmptyInitializerProtocol {
  init()
}

protocol ParameterizedInitializerProtocol {
  init(param1: Bool, param2: Int)
}

protocol FailableEmptyInitializerProtocol {
  init?()
}

protocol FailableUnwrappedEmptyInitializerProtocol {
  init!()
}

protocol FailableParameterizedInitializerProtocol {
  init?(param1: Bool, param2: Int)
}

protocol FailableUnwrappedParameterizedInitializerProtocol {
  init!(param1: Bool, param2: Int)
}
