import Foundation
import PathKit

public enum Carthage {
  public enum Platform: String {
    case iOS = "iOS"
    case macOS = "macOS"
    case tvOS = "tvOS"
    case watchOS = "watchOS"
    case all = "all"
  }
  
  public static func update(platforms: [Platform] = [.all], project: Path) throws {
    try Subprocess("carthage", [
      "update",
      "--platform", platforms.map({ $0.rawValue }).joined(separator: ","),
      "--use-xcframeworks",
      "--verbose",
    ], workingDirectory: project.parent()).run()
  }
  
  public static func build(platforms: [Platform] = [.all], project: Path) throws {
    try Subprocess("carthage", [
      "build",
      "--platform", platforms.map({ $0.rawValue }).joined(separator: ","),
      "--use-xcframeworks",
      "--no-skip-current",
      "--cache-builds",
      "--verbose",
    ], workingDirectory: project.parent()).run()
  }
}
