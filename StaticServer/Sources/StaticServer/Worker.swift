//
//  File.swift
//  
//
//  Created by a.chetverov on 9/19/20.
//

import Foundation

struct Worker {
#if os(macOS)
  var thread: pthread_t? = nil
#else
  var thread = pthread_t()
#endif
  var terminate = 0
  weak var workqueue: WorkQueue?
}

#if os(macOS)
typealias workerPtr = UnsafeMutableRawPointer
#else
typealias workerPtr = UnsafeMutableRawPointer?
#endif


func workerEntryPoint(ctx: workerPtr) -> UnsafeMutableRawPointer? {
  defer {
    pthread_exit(nil);
  }
#if os(macOS)
  let workerPtr = ctx.assumingMemoryBound(to: Worker.self)
#else
  let workerPtr = ctx!.assumingMemoryBound(to: Worker.self)
#endif
  
  while true {
    pthread_mutex_lock(&workerPtr.pointee.workqueue!.jobsMutex)
    
    while (workerPtr.pointee.workqueue!.waitingJobs.isEmpty) {
      if workerPtr.pointee.terminate == 1 {
        break
      }
      
      pthread_cond_wait(&workerPtr.pointee.workqueue!.jobsCond, &workerPtr.pointee.workqueue!.jobsMutex)
    }
    
    if workerPtr.pointee.terminate == 1 {
      break
    }
    
    let jobNode = workerPtr.pointee.workqueue!.waitingJobs.first
    if let jobNode = jobNode {
      _ = workerPtr.pointee.workqueue!.waitingJobs.remove(node: jobNode)
    }
    
    pthread_mutex_unlock(&workerPtr.pointee.workqueue!.jobsMutex)
    if let jobNode = jobNode {
      jobNode.value.function(jobNode.value)
    }
  }
  
  workerPtr.deinitialize(count: 1)
  workerPtr.deallocate()
  pthread_exit(nil)
}
