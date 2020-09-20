//
//  File.swift
//  
//
//  Created by a.chetverov on 9/19/20.
//

import Foundation

class Config {
  var threadsCount: Int
  static let shared = Config()
  
  private init() {
    //ProcessInfo.processInfo.arguments
    self.threadsCount = ProcessInfo.processInfo.activeProcessorCount
    print("Threads count: \(self.threadsCount)")
  }
}
