//
//  Interceptor.swift
//  SwiftGRPC
//
//  Created by Michael Rebello on 5/18/18.
//

import Foundation

//extension CallStyle {
//  func makeRequest(interceptors: [Interceptor.Type], metadata: Metadata) {
//    let interceptableCall = interceptors.map { interceptableCall(call: self, )}
//    let metadata = interceptors.reversed().
//  }
//}

protocol AsyncInterceptor {
  init?(call: InterceptableCall)

  func didReceiveResponse(_ result: CallResult)
}

/// <#function description#>
public final class InterceptableCall {
  private enum TaskType {
    case interceptor(Interceptor.Type)
    case completion(CompletionClosure)
  }

  private let nextTask: TaskType

  /// The method that will be used by this call.
  public let method: String

  /// The style being used for the API call.
  public let style: CallStyle

  /// The metadata associated with the call.
  public var metadata: Metadata

  /// <#function description#>
  ///
  /// - returns: <#return value description#>
  public func next() -> CallResult {
    switch self.nextTask {
    case .interceptor(let interceptor):
      return interceptor.intercept(self)
    case .completion(let completion):
      return completion(self)
    }
  }

  /// <#function description#>
  ///
  /// - returns: <#return value description#>
  public func cancel() -> CallResult {
    return .cancelled
  }

  /// <#function description#>
  typealias CompletionClosure = (InterceptableCall) -> CallResult

  /// <#function description#>
  ///
  /// - parameter call:       <#call description#>
  /// - parameter style:      <#style description#>
  /// - parameter metadata:   <#metadata description#>
  /// - parameter next:       <#next description#>
  /// - parameter completion: <#completion description#>
  init(call: ClientCallBase.Type, style: CallStyle, metadata: Metadata, next: Interceptor.Type?,
       completion: @escaping CompletionClosure) {
    if let nextInterceptor = next {
      self.nextTask = .interceptor(nextInterceptor)
    } else {
      self.nextTask = .completion(completion)
    }

    self.method = call.method
    self.metadata = metadata
    self.style = style
  }
}

/// <#function description#>
public protocol Interceptor {
  /// <#function description#>
  ///
  /// - parameter call: <#call description#>
  static func intercept(_ call: InterceptableCall) -> CallResult
}
