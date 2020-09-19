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
  var status: Status
  static let version = "HTTP/1.1"
  
  var headers = [
    "Server" : "SwiftStaticServer",
    "Connection" : "closed"
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
    let response = UnsafeMutablePointer<HttpResponse>.allocate(capacity: 1)
    response.initialize(to: HttpResponse())
    
    let RFC3339DateFormatter = DateFormatter()
    RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    if req.pointee.method != .GET && req.pointee.method != .HEAD {
      let date = Date()
      response.pointee.headers["Date"] = RFC3339DateFormatter.string(from: date)
      response.pointee.status = .MethodNotAllowed
      return response
    }
    
    let result = LookUpForResource(resource: req.pointee.resource, returnData: req.pointee.method == .GET)
    
    if result.1 == .OK {
      response.pointee.headers["Content-Length"] = String(result.0?.size ?? 0)
      response.pointee.headers["Content-Type"] = result.0?.mimetype.description
      response.pointee.body = result.0?.data
    } else {
      response.pointee.status = result.1
      response.pointee.headers["Content-Length"] = "0"
    }
    
    return response
  }
}
