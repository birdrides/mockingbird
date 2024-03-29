import Foundation

struct FunctionDefinitionTemplate: Template {
  let leadingTrivia: String
  let attributes: [String]
  let declaration: String
  let genericConstraints: [String]
  let body: String
  
  init(leadingTrivia: String = "",
       attributes: [String] = [],
       declaration: String,
       genericConstraints: [String] = [],
       body: String) {
    self.leadingTrivia = leadingTrivia
    self.attributes = attributes
    self.declaration = declaration
    self.genericConstraints = genericConstraints
    self.body = body
  }

  func render() -> String {
    let genericConstraintsString = genericConstraints.isEmpty ? "" :
      " where \(separated: genericConstraints)"
    return String(lines: [
      leadingTrivia,
      attributes.filter({ !$0.isEmpty }).joined(separator: " "),
      declaration + genericConstraintsString + " " + BlockTemplate(body: body).render()
    ])
  }
}
