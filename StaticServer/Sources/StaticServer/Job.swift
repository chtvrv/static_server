//
//  File.swift
//  
//
//  Created by a.chetverov on 9/19/20.
//

import Foundation
import libevent

struct Job {
  var function: (Job) -> Void
  var data: UnsafeMutablePointer<HttpSession>
}

func dispatchJob(job: Job) {
  let client = job.data
  event_base_dispatch(client.pointee.eventBase)
  HttpSession.clean(ptr: job.data)
}
