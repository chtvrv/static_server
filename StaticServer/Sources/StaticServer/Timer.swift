//
//  File.swift
//  
//
//  Created by a.chetverov on 9/12/20.
//

import Foundation
import libevent

struct Timer {
  static let timeoutcb: event_callback_fn = { (socket, event, ctx) in
    print("TIME CALLBACK")
    HttpSession.clean(ptr: ctx?.assumingMemoryBound(to: HttpSession.self))
    print("Closed")
  }
  
  var event: Event
  var timeout: timeval
  
  init(fd: Int32, ctx: UnsafeMutableRawPointer, timeout: timeval) {
    self.event = Event(types: [EventType.timeout], fd: fd, cb: Timer.timeoutcb, ctx: ctx)
    self.timeout = timeout
  }

  public mutating func start() {
    event.add(timeout: &self.timeout)
  }
  
  public func stop() {
    event.remove()
  }
  
  public func free() {
    event.free()
  }
}
