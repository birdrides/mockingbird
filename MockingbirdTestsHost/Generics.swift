//
//  Generics.swift
//  MockingbirdTestsHost
//
//  Created by Andrew Chang on 8/20/19.
//  Copyright © 2019 Bird Rides, Inc. All rights reserved.
//

import Foundation
import AppKit

public protocol AssociatedTypeProtocol {
  associatedtype EquatableType: Equatable
  associatedtype HashableType: Hashable

  func methodUsingEquatableType(equatable: EquatableType)
  func methodUsingHashableType(hashable: HashableType)
  func methodUsingEquatableTypeWithReturn(equatable: EquatableType) -> EquatableType

  static func methodUsingEquatableTypeWithReturn(equatable: EquatableType) -> EquatableType

  var equatableTypeVariable: EquatableType { get }
  static var equatableTypeVariable: EquatableType { get }
}

public class AssociatedTypeGenericImplementer<EquatableType: Equatable, S: Sequence>: AssociatedTypeProtocol
where S.Element == EquatableType {
  public typealias HashableType = String

  public func methodUsingEquatableType(equatable: EquatableType) {}
  public func methodUsingHashableType(hashable: HashableType) {}
  public func methodUsingEquatableTypeWithReturn(equatable: EquatableType) -> EquatableType {
    fatalError()
  }

  public static func methodUsingEquatableTypeWithReturn(equatable: EquatableType) -> EquatableType {
    fatalError()
  }

  public var equatableTypeVariable: EquatableType { return 1 as! EquatableType }
  public static var equatableTypeVariable: EquatableType { return 1 as! EquatableType }
}

public protocol AssociatedTypeImplementerProtocol {
  func request<T: AssociatedTypeProtocol>(object: T)
    where T.EquatableType == Int, T.HashableType == String

  func request<T: AssociatedTypeProtocol>(object: T) -> T.HashableType
    where T.EquatableType == Int, T.HashableType == String

  func request<T: AssociatedTypeProtocol>(object: T) -> T.HashableType
    where T.EquatableType == Bool, T.HashableType == String
}

public class AssociatedTypeImplementer {
  func request<T: AssociatedTypeProtocol>(object: T)
    where T.EquatableType == Int, T.HashableType == String {}

  func request<T: AssociatedTypeProtocol>(object: T) -> T.EquatableType
    where T.EquatableType == Int, T.HashableType == String { return 1 }

  // Not possible to override overloaded methods where uniqueness is from generic constraints.
  // https://forums.swift.org/t/cannot-override-more-than-one-superclass-declaration/22213
  func request<T: AssociatedTypeProtocol>(object: T) -> T.EquatableType
    where T.EquatableType == Bool, T.HashableType == String { return true }
}

public protocol AssociatedTypeGenericConstraintsProtocol {
  associatedtype ConstrainedType: AssociatedTypeProtocol
    where ConstrainedType.EquatableType == Int, ConstrainedType.HashableType == String

  func request(object: ConstrainedType) -> Bool
}

public protocol AssociatedTypeGenericConformingConstraintsProtocol {
  associatedtype ConformingType: AssociatedTypeProtocol where
    ConformingType.EquatableType: EquatableConformingProtocol,
    ConformingType.HashableType: HashableConformingProtocol

  func request(object: ConformingType) -> Bool
}

public protocol AssociatedTypeSelfReferencingProtocol {
  // Swift 5.1 has regressions on self-referencing where clauses in type declarations.
  // https://bugs.swift.org/browse/SR-11503
  associatedtype SequenceType: Sequence, Hashable// where SequenceType.Element == Self
  
  func request(array: SequenceType)
  func request<T: Sequence>(array: T) where T.Element == Self
  
  func request(object: Self)
}

public protocol InheritingAssociatedTypeSelfReferencingProtocol: AssociatedTypeSelfReferencingProtocol {}

public protocol SecondLevelSelfConstrainedAssociatedTypeProtocol
where Self: AssociatedTypeSelfReferencingProtocol {}

public protocol TopLevelSelfConstrainedAssociatedTypeProtocol
where Self: SecondLevelSelfConstrainedAssociatedTypeProtocol, Self.Element: Hashable {
  associatedtype Element
}

public protocol OpaqueClassSelfConstrainedAssociatedTypeProtocol
where Self: NSViewController {}

public protocol OpaqueProtocolSelfConstrainedAssociatedTypeProtocol
where Self: Hashable {}

public class ReferencedGenericClass<T> {}
public class ReferencedGenericClassWithConstraints<S: Sequence> where S.Element: Hashable {}

public protocol GenericClassReferencer {
  var genericClassVariable: ReferencedGenericClass<String> { get set }
  var genericClassWithConstraintsVariable: ReferencedGenericClassWithConstraints<[String]> { get set }
  
  func genericClassMethod<Z>() -> ReferencedGenericClass<Z>
  func genericClassWithConstraintsMethod<Z>() -> ReferencedGenericClassWithConstraints<Z>
  
  func genericClassMethod<T, Z: ReferencedGenericClass<T>>(metatype: Z.Type) -> Z.Type
  func genericClassWithConstraintsMethod<T, Z: ReferencedGenericClassWithConstraints<T>>(metatype: Z.Type)
    -> Z.Type
}

public class UnalphabetizedGenericClass<C, B, A> {
  func genericReferencingMethod(a: A, b: B, c: C) -> (A, B, C) { fatalError() }
  func genericMethod<Z, Y, X>(x: X, y: Y, z: Z) -> (X, Y, Z) { fatalError() }
}

public class GenericBaseClass<T> {
  var baseVariable: T { fatalError() }
  func baseMethod(param: T) -> T { fatalError() }
}

public struct ShadowedType {}

public class ShadowedGenericType<ShadowedType> {
  func shadowedClassScope(param: ShadowedType) -> ShadowedType { fatalError() }
  func shadowedFunctionScope<ShadowedType>(param: ShadowedType) -> ShadowedType { fatalError() }
  
  public class NestedShadowedGenericType {
    func shadowedClassScope(param: ShadowedType) -> ShadowedType { fatalError() }
    func shadowedFunctionScope<ShadowedType>(param: ShadowedType) -> ShadowedType { fatalError() }
  }
  
  public class NestedDoublyShadowedGenericType<ShadowedType> {
    func shadowedClassScope(param: ShadowedType) -> ShadowedType { fatalError() }
    func shadowedFunctionScope<ShadowedType>(param: ShadowedType) -> ShadowedType { fatalError() }
  }
}

class SpecializedGenericSubclass: GenericBaseClass<Bool> {}
protocol SpecializedGenericProtocol: GenericBaseClass<Bool> {}
protocol AbstractSpecializedGenericProtocol: GenericBaseClass<Bool> {
  associatedtype EquatableType: Equatable
}

class SpecializedShadowedGenericSubclass: ShadowedGenericType<NSObject> {}
protocol SpecializedShadowedGenericProtocol: ShadowedGenericType<NSObject> {}

class UnspecializedGenericSubclass<T>: GenericBaseClass<T> {}

class ConstrainedUnspecializedGenericSubclass<T: Equatable>: GenericBaseClass<T> {}

class UnspecializedMultipleGenericSubclass<T, R>: GenericBaseClass<T> {}
