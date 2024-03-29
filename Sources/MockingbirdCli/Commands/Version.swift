import ArgumentParser
import Foundation
import MockingbirdCommon
import MockingbirdGenerator
import PathKit

extension Mockingbird {
  struct Version: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Show the version.",
      shouldDisplay: false
    )
    
    func run() throws {
      logInfo("\(mockingbirdVersion)")
    }
  }
}
