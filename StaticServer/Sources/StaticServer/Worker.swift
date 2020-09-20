//
//  File.swift
//  
//
//  Created by a.chetverov on 9/19/20.
//

import Foundation

struct Worker {
  var thread: pthread_t? = nil
  var terminate = 0
  weak var workqueue: WorkQueue?
}


func workerEntryPoint(ctx: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
  defer {
    pthread_exit(nil);
  }
  
  let workerPtr = ctx.assumingMemoryBound(to: Worker.self)
  
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
      // очистить job
    }
  }
  
  workerPtr.deinitialize(count: 1)
  workerPtr.deallocate()
  
  return nil
}
