import Foundation
import PathKit

public enum XcodeSelect {
  public static func printPath() throws -> Path {
    let (path, _) = try Subprocess("xcrun", ["xcode-select", "--print-path"]).runWithStringOutput()
    return Path(path.trimmingCharacters(in: .whitespacesAndNewlines))
  }
}
