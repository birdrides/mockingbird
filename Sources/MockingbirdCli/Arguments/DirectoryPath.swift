import ArgumentParser
import Foundation
import PathKit
import MockingbirdGenerator

class DirectoryPath: ExpressibleByArgument {
  var path: Path
  var defaultValueDescription: String { path.abbreviate().string }
  static var defaultCompletionKind: CompletionKind = .directory
  
  required init?(argument: String) {
    self.path = Path(argument)
  }
  
  init?(path: Path?) {
    guard let path = path else { return nil }
    self.path = path
  }
}

extension DirectoryPath: Encodable {
  func encode(to encoder: Encoder) throws {
    try OptionArgumentEncoding.encode(path, with: encoder)
  }
}

extension DirectoryPath: ValidatableArgument {
  func validate(name: String) throws {
    guard path.exists, path.isDirectory else {
      throw ValidationError("'\(name)' must be an existing directory")
    }
  }
}
