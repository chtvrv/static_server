//
//  File.swift
//  
//
//  Created by a.chetverov on 9/19/20.
//

import Foundation

class WorkQueue {
  static let shared = WorkQueue()
  
  var workers: LinkedList<UnsafeMutablePointer<Worker>>
  var waitingJobs: LinkedList<Job>
  var jobsMutex = pthread_mutex_t()
  var jobsCond = pthread_cond_t()
  
  private init() {
    pthread_cond_init(&self.jobsCond, nil)
    pthread_mutex_init(&self.jobsMutex, nil)
    
    self.workers = LinkedList<UnsafeMutablePointer<Worker>>()
    self.waitingJobs = LinkedList<Job>()
  }
  
  func configureWorkers() -> Bool {
    for _ in (0..<Config.shared.threadsCount) {
      let workerPtr = UnsafeMutablePointer<Worker>.allocate(capacity: 1)
      workerPtr.initialize(to: Worker(workqueue: self))
      
      if pthread_create(&workerPtr.pointee.thread, nil, workerEntryPoint, workerPtr) != 0 {
        print("pthread_create failed")
        workerPtr.deinitialize(count: 1)
        workerPtr.deallocate()
        return false
      }
      self.workers.append(value: workerPtr)
    }
    return true
  }
  
  func addJobToQueue(job: Job) {
    pthread_mutex_lock(&self.jobsMutex)
    self.waitingJobs.append(value: job)
    pthread_cond_signal(&self.jobsCond)
    pthread_mutex_unlock(&self.jobsMutex)
  }
  
  func shutdown() {
    var worker = self.workers.first

    while worker != nil {
      worker!.value.pointee.terminate = 1
      worker = worker!.next
    }
    
    pthread_mutex_lock(&self.jobsMutex)
    self.workers.removeAll()
    self.waitingJobs.removeAll()
    pthread_cond_broadcast(&self.jobsCond)
    pthread_mutex_unlock(&self.jobsMutex)
  }
  
}
