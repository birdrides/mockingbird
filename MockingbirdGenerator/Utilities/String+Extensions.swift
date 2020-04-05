//
//  String+Extensions.swift
//  MockingbirdCli
//
//  Created by Andrew Chang on 8/16/19.
//  Copyright © 2019 Bird Rides, Inc. All rights reserved.
//

import Foundation

public extension Dictionary where Key == Character, Value == Character {
  static var allGroups: [Character: Character] {
    return ["(": ")", "[": "]", "<": ">"]
  }
}

public extension Set where Element == Character {
  static var whitespacesAndNewlines: Set<Character> {
    return ["\t", "\n", "\r", " "]
  }
}

public extension String {
  /// Capitalizes only the first character of the string.
  var capitalizedFirst: String {
    return prefix(1).uppercased() + dropFirst()
  }

  /// Wraps the string with backticks, e.g. for escaping keywords
  var backtickWrapped: String {
    return "`\(self)`"
  }
  
  /// Wraps the string in single quotes.
  var singleQuoted: String {
    return "'\(self)'"
  }
  
  /// Wraps the string in double quotes.
  var doubleQuoted: String {
    return "\"\(self)\""
  }
  
  /// Splits a string into substrings given a character delimiter.
  ///
  /// - Note: This method is 2x faster than the built-in method on Release builds.
  ///
  /// - Parameter delimiter: A character to use to split the string.
  /// - Returns: An array of substrings.
  func substringComponents(separatedBy delimiter: Character) -> [Substring] {
    return self[...].substringComponents(separatedBy: delimiter)
  }
  
  /// Adds two-space indentation `offset` number of times.
  ///
  /// - Parameter offset: The number of times to indent the current string.
  /// - Returns: A new indented string instance.
  func indent(by offset: UInt = 1) -> String {
    guard offset > 0, !isEmpty else { return self }
    let lines = substringComponents(separatedBy: "\n")
    var indentation = "  "
    for _ in 0..<(offset-1) { indentation += "  " }
    return lines.map({
      guard !$0.isEmpty else { return String($0) }
      return indentation + $0
    }).joined(separator: "\n")
  }
  
  /// Returns a new string created by removing implicitly unwrapped optionals.
  func removingImplicitlyUnwrappedOptionals() -> String {
    return replacingOccurrences(of: "!", with: "")
  }
  
  /// Returns a new string created by removing function parameter attributes.
  func removingParameterAttributes() -> String {
    // Happy path; heuristically determines if we need to perform the complex encode-decode routine.
    // This is potentially dangerous but saves a lot of computation time.
    guard firstIndex(of: ":") != nil // Has label
      || firstIndex(of: "!") != nil // Has implicitly unwrapped optional
      || firstIndex(of: "@") != nil // Has attribute
      || contains("...") // Is variadic
      || contains("inout") // Is inout (probably)
      else { return self }
    
    var options = SerializationRequest.Options.standard
    options.insert(.shouldExcludeImplicitlyUnwrappedOptionals)
    let request = SerializationRequest(method: .notQualified,
                                       context: SerializationRequest.Context(),
                                       options: options)
    return Function.Parameter(from: self).type.serialize(with: request)
  }
  
  /// Returns a new string created by removing generic typing, e.g. `SomeType<T>` becomes `SomeType`
  func removingGenericTyping() -> String {
    guard let genericTypeStartIndex = firstIndex(of: "<") else { return self }
    guard contains(".") else { return String(self[..<genericTypeStartIndex]) }
    return self[...]
      .components(separatedBy: ".", excluding: .allGroups)
      .map({ component -> Substring in
        guard let genericTypeStartIndex = component.firstIndex(of: "<") else { return component }
        return component[..<genericTypeStartIndex]
      }).joined(separator: ".")
  }
  
  /// Whether the string contains `needle`, ignoring any characters within the excluded `groups`.
  ///
  /// - Parameters:
  ///   - needle: The character to search for.
  ///   - groups: A map containing start group characters to end group characters.
  func contains(_ needle: Character, excluding groups: [Character: Character]) -> Bool {
    return self[...].contains(needle, excluding: groups)
  }
  
  /// The start of the first index of `needle` found in the string, excluding grouped characters.
  ///
  /// - Parameters:
  ///   - needle: The character to search for.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: The first index if found, `nil` if `needle` does not exist.
  func firstIndex(of needle: Character, excluding groups: [Character: Character]) -> String.Index? {
    return self[...].firstIndex(of: needle, excluding: groups)
  }
  
  /// Whether the string contains `needle`, ignoring any characters within the excluded `groups`.
  ///
  /// - Parameters:
  ///   - needle: The string to search for.
  ///   - groups: A map containing start group characters to end group characters.
  func contains(_ needle: String, excluding groups: [Character: Character]) -> Bool {
    return self[...].contains(needle, excluding: groups)
  }
  
  /// The start of the first index of `needle` found in the string, excluding grouped characters.
  ///
  /// - Parameters:
  ///   - needle: The string to search for.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: The first index if found, `nil` if `needle` does not exist.
  func firstIndex(of needle: String, excluding groups: [Character: Character]) -> String.Index? {
    return self[...].firstIndex(of: needle, excluding: groups)
  }
  
  /// Split the string by a single delimiter character, excluding any characters found in groups.
  ///
  /// - Parameters:
  ///   - delimiter: A character to split the string by.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: Substring components from splitting the current string.
  func components(separatedBy delimiter: Character,
                  excluding groups: [Character: Character]) -> [Substring] {
    return self[...].components(separatedBy: delimiter, excluding: groups)
  }
  
  /// Split the string by multiple delimiters, excluding any characters found in groups.
  ///
  /// - Parameters:
  ///   - delimiters: A set of characters to split the string by.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: Substring components from splitting the current string.
  func components(separatedBy delimiters: Set<Character>,
                  excluding groups: [Character: Character]) -> [Substring] {
    return self[...].components(separatedBy: delimiters, excluding: groups)
  }
}

public extension Substring {
  /// Splits a substring into substrings given a character delimiter.
  ///
  /// - Note: This method is 2x faster than the built-in method on Release builds.
  ///
  /// - Parameter delimiter: A character to use to split the substring.
  /// - Returns: An array of substrings.
  func substringComponents(separatedBy delimiter: Character) -> [Substring] {
    var components = [Substring]()
    var currentSubstring = self[..<endIndex]
    while true {
      let index = currentSubstring.firstIndex(of: delimiter) ?? endIndex
      let component = currentSubstring[..<index]
      components.append(component)
      guard index != endIndex else { break }
      currentSubstring = currentSubstring[currentSubstring.index(after: index)..<endIndex]
    }
    return components
  }
  
  /// Whether the substring contains `needle`, ignoring any characters within the excluded `groups`.
  ///
  /// - Parameters:
  ///   - needle: The character to search for.
  ///   - groups: A map containing start group characters to end group characters.
  func contains(_ needle: Character, excluding groups: [Character: Character]) -> Bool {
    return firstIndex(of: needle, excluding: groups) != nil
  }
  
  /// The start of the first index of `needle` found in the substring, excluding grouped characters.
  ///
  /// - Parameters:
  ///   - needle: The character to search for.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: The first index if found, `nil` if `needle` does not exist.
  func firstIndex(of needle: Character, excluding groups: [Character: Character]) -> String.Index? {
    var currentGroups = [Character]()
    for (i, scalarValue) in utf8.enumerated() {
      let character = Character(UnicodeScalar(scalarValue))
      
      if currentGroups.isEmpty && character == needle {
        return index(startIndex, offsetBy: i)
      }
      
      if groups[character] != nil {
        currentGroups.append(character)
      }
      if let groupEnd = currentGroups.last, groups[groupEnd] == character {
        currentGroups.removeLast()
      }
    }
    return nil
  }
  
  /// Whether the substring contains `needle`, ignoring any characters within the excluded `groups`.
  ///
  /// - Parameters:
  ///   - needle: The string to search for.
  ///   - groups: A map containing start group characters to end group characters.
  func contains(_ needle: String, excluding groups: [Character: Character]) -> Bool {
    return firstIndex(of: needle, excluding: groups) != nil
  }
  
  /// The start of the first index of `needle` found in the substring, excluding grouped characters.
  ///
  /// - Parameters:
  ///   - needle: The string to search for.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: The first index if found, `nil` if `needle` does not exist.
  func firstIndex(of needle: String, excluding groups: [Character: Character]) -> String.Index? {
    var currentGroups = [Character]()
    var stateMachineStartIndex: Int?
    var stateMachine = 0
    for (i, scalarValue) in utf8.enumerated() {
      let character = Character(UnicodeScalar(scalarValue))
      
      if currentGroups.isEmpty {
        let needleIndex = needle.index(needle.startIndex, offsetBy: stateMachine)
        if character != needle[needleIndex] {
          stateMachine = 0
        } else {
          stateMachine += 1
          if stateMachine == 1 { stateMachineStartIndex = i }
          if stateMachine == needle.count {
            return index(startIndex, offsetBy: stateMachineStartIndex ?? 0)
          }
        }
      }
      
      if groups[character] != nil {
        currentGroups.append(character)
        stateMachine = 0
      }
      if let groupEnd = currentGroups.last, groups[groupEnd] == character {
        currentGroups.removeLast()
        stateMachine = 0
      }
    }
    return nil
  }
  
  /// Split the substring by a single delimiter character, excluding any characters found in groups.
  ///
  /// - Parameters:
  ///   - delimiter: A character to split the substring by.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: Substring components from splitting the current substring.
  func components(separatedBy delimiter: Character,
                  excluding groups: [Character: Character]) -> [Substring] {
    return components(separatedBy: [delimiter], excluding: groups)
  }
  
  /// Split the substring by multiple delimiters, excluding any characters found in groups.
  ///
  /// - Parameters:
  ///   - delimiters: A set of characters to split the substring by.
  ///   - groups: A map containing start group characters to end group characters.
  /// - Returns: Substring components from splitting the current substring.
  func components(separatedBy delimiters: Set<Character>,
                  excluding groups: [Character: Character]) -> [Substring] {
    var currentGroups = [Character]()
    var components = [Substring]()
    var currentComponent = Substring()
    for scalarValue in utf8 {
      let character = Character(UnicodeScalar(scalarValue))
      if groups[character] != nil {
        currentGroups.append(character)
      }
      if let groupEnd = currentGroups.last, groups[groupEnd] == character {
        currentGroups.removeLast()
      }
      if delimiters.contains(character) && currentGroups.isEmpty {
        components.append(currentComponent)
        currentComponent = Substring()
      }
      if !currentGroups.isEmpty || !delimiters.contains(character) {
        currentComponent.append(character)
      }
    }
    components.append(currentComponent)
    return components
  }
}
