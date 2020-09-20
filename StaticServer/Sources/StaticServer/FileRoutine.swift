//
//  File.swift
//  
//
//  Created by a.chetverov on 9/16/20.
//

import Foundation

class FilesCache {
  static let shared = FilesCache()
  var cache = [String: File]()
  
  var cacheMutex = pthread_mutex_t()
  let root_dir: String
  
  private init() {
    pthread_mutex_init(&self.cacheMutex, nil)
    self.root_dir = ProcessInfo.processInfo.environment["STATIC_DIR"]!
  }
  
}

struct File {
  var data: Data? = nil
  var filename: String = ""
  var mimetype: MIMEtype = .unknown
  var size: Int?
  var isIndex: Bool = false
}

extension FilesCache {
  func LookUpForFile(resource: String, returnData: Bool) -> (File?, Status) {
    pthread_mutex_lock(&self.cacheMutex)
    if var file = cache[resource] {
      print("Cache hit")
      pthread_mutex_unlock(&self.cacheMutex)
      if !returnData {
        file.data = nil
      }
      return (file, .OK)
    }
    pthread_mutex_unlock(&self.cacheMutex)
    
    var file = File()
    var path = resource
    if path.last == "/" {
      path += "index.html"
      file.isIndex = true
    }
    
    let url = URL(fileURLWithPath: root_dir + path)
    do {
      if !(try url.checkResourceIsReachable()) {
        return (nil, file.isIndex ? Status.Forbidden : Status.NotFound)
      }
    } catch let error {
      print(error)
      return (nil, file.isIndex ? Status.Forbidden : Status.NotFound)
    }
    
    if let type = MIMEtype.init(rawValue: url.pathExtension) {
      file.mimetype = type
    } else {
      file.mimetype = .unknown
    }
    
    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey])
      file.size = values.fileSize
    } catch let error {
      print(error)
      return (nil, file.isIndex ? Status.Forbidden : Status.NotFound)
    }
    
    pthread_mutex_lock(&self.cacheMutex)

    do {
      file.data = try Data(contentsOf: url, options: .mappedIfSafe)
      cache[resource] = file
      if !returnData {
        file.data = nil
      }
    } catch let error {
      print(error)
      pthread_mutex_unlock(&self.cacheMutex)
      return (nil, file.isIndex ? Status.Forbidden : Status.NotFound)
    }
    
    pthread_mutex_unlock(&self.cacheMutex)
    return (file, .OK)
  }
}
