//
//  File.swift
//  
//
//  Created by a.chetverov on 9/6/20.
//

import libevent

class EventLoop {
  public static let shared = EventLoop()
  internal let eventBase: OpaquePointer
  
  init() {
    eventBase = event_base_new()
  }
  
  deinit {
    event_free(eventBase)
  }

  func run() {
    guard event_base_dispatch(eventBase) == 0 else {
      print("[Server] Event loop error!")
      return
    }
  }
  
  func shutdown() {
    if event_base_loopexit(self.eventBase, nil) != 0 {
      print("Error shutting down loop")
    }
  }
}
