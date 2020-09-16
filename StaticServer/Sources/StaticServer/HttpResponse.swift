//
//  File.swift
//  
//
//  Created by a.chetverov on 9/13/20.
//

import Foundation

enum Status: CustomStringConvertible {
  case OK
  case Forbidden
  case NotFound
  case MethodNotAllowed
  
  var description: String {
    switch self {
      case .OK:
        return "200 OK"
      case .Forbidden:
        return "403 Forbidden"
      case .NotFound:
        return "404 Not Found"
      case .MethodNotAllowed:
        return "405 Method Not Allowed"
    }
  }
}

struct HttpResponse {
  let status: Status
  static let version = "HTTP/1.1"
  
  var headers = [
    "Server" : "SwiftServer",
    "Date" : "none",
    "Content-Length" : "0",
    "Connection" : "keep-alive"
  ]

  var body: Data?
  
  init() {
    self.status = .OK
    self.body = nil
  }
  
  func serialize() -> UnsafeMutablePointer<Data>? {
    let data_ptr = UnsafeMutablePointer<Data>.allocate(capacity: 1)
    data_ptr.initialize(to: Data())
    data_ptr.pointee.append(HttpResponse.version, count: HttpResponse.version.lengthOfBytes(using: .ascii))
    data_ptr.pointee.append(" ", count: 1)
    data_ptr.pointee.append(self.status.description, count: self.status.description.lengthOfBytes(using: .ascii))
    data_ptr.pointee.append("\r\n", count: 2)
    
    for (header, value) in headers {
      data_ptr.pointee.append(header, count: header.lengthOfBytes(using: .ascii))
      data_ptr.pointee.append(": ", count: 2)
      data_ptr.pointee.append(value, count: value.lengthOfBytes(using: .ascii))
      data_ptr.pointee.append("\r\n", count: 2)
    }
    data_ptr.pointee.append("\r\n", count: 2)
    if let body = body {
      data_ptr.pointee.append(body)
    }
    
    return data_ptr
  }
}

extension HttpResponse {
  static func GetResponseForRequest(req: UnsafeMutablePointer<HttpRequest>) -> UnsafeMutablePointer<HttpResponse>? {
    let ptr = UnsafeMutablePointer<HttpResponse>.allocate(capacity: 1)
    ptr.initialize(to: HttpResponse())
    do {
      // перенести на старт
      let root_dir = ProcessInfo.processInfo.environment["STATIC_DIR"]!
      let data = try Data(contentsOf: URL(fileURLWithPath: root_dir + req.pointee.resource), options: .mappedIfSafe)
      print(data.count)
      ptr.pointee.body = data
      ptr.pointee.headers["Content-Length"] = String(data.count)
    } catch let error {
      print(error)
    }
    return ptr
  }
}
