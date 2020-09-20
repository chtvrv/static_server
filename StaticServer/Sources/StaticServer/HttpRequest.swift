//
//  File.swift
//  
//
//  Created by a.chetverov on 9/13/20.
//

import Foundation

enum Method: String {
  case GET, HEAD, POST, PUT, DELETE, PATCH
}

struct HttpRequest {
  let headers: [String: String]
  let method: Method
  let resource: String
  
  static func createRequestFromLinesArray(lines: [UnsafeMutablePointer<Int8>]) -> UnsafeMutablePointer<HttpRequest>? {
    if lines.isEmpty {
      return nil
    }
    
    defer {
      lines.forEach {
        free($0)
      }
    }
    
    let requestLine = String(cString: lines[0])
    
    let parsed = requestLine.components(separatedBy: " ")
    if parsed.count != 3 {
      return nil
    }
    
    guard let method = Method.init(rawValue: parsed[0]) else {
      return nil
    }
    
    guard let unescapedURI = parsed[1].removingPercentEncoding else {
      return nil
    }
    
    let escapedURI = unescapedURI.replacingOccurrences(of: "/../", with: "")
    let resource: String
    if let unquery = escapedURI.split(separator: "?").first {
      resource = String(unquery)
    } else {
      resource = ""
    }
    
    var headers = [String: String]()
    
    for i in 1..<lines.count {
      let pair = String(cString: lines[i]).split(separator: ":")
      let header = pair.first ?? ""
      let value = pair.last ?? ""
      headers[String(header)] = String(value)
    }
    
    let ptr = UnsafeMutablePointer<HttpRequest>.allocate(capacity: 1)
    ptr.initialize(to: HttpRequest(headers: headers, method: method, resource: resource))
    return ptr
  }
}
