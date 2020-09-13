//
//  File.swift
//  
//
//  Created by a.chetverov on 9/6/20.
//

import Foundation
import libevent

enum EventType: Int16 {
  case timeout     = 0x01
  case read        = 0x02
  case write       = 0x04
  case signal      = 0x08
  case persistent  = 0x10
  case finalize    = 0x40
  case closed      = 0x80
}

struct Event {
  let types: [EventType]
  let fd: Int32
  var internalEvent: OpaquePointer?
  
  init(types: [EventType], fd: Int32, cb: event_callback_fn?, ctx: UnsafeMutableRawPointer!) {
    self.types = types
    self.fd = fd
    internalEvent = event_new(
      EventLoop.shared.eventBase,
      fd,
      toRaw(),
      cb,
      ctx)
  }
  
  public func add(timeout: UnsafePointer<timeval>! = nil) {
    if let internalEvent = internalEvent {
      event_add(internalEvent, timeout)
    }
  }
  
  public func remove() {
    if let internalEvent = internalEvent {
      event_del(internalEvent)
    }
  }
  
  public func free() {
    if let internalEvent = internalEvent {
      event_free(internalEvent)
    }
  }
  
  @inline(__always) func toRaw() -> Int16 {
    return types.reduce(0) { return $0 + $1.rawValue }
  }

}
