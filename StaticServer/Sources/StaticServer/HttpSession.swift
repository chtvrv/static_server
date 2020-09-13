//
//  File.swift
//  
//
//  Created by a.chetverov on 9/10/20.
//

import Foundation
import libevent

typealias BufferEvent = OpaquePointer

protocol BufferEventSession {
  var bev: BufferEvent { get }
  static var readcb: bufferevent_data_cb { get }
  static var writecb: bufferevent_data_cb { get }
  static var eventcb: bufferevent_event_cb { get }
}

struct HttpRequest {
  let requestLine: String
  let headers: [String: String]
}

struct HttpSession : BufferEventSession {
  var bev: BufferEvent
  var request: HttpRequest?
  var timer: Timer
  
  init(eventBase: OpaquePointer!, socket: Int32, options: Int32, ptr: UnsafeMutablePointer<HttpSession>) {
    self.timer = Timer(fd: socket, ctx: ptr, timeout: timeval(tv_sec: 5, tv_usec: 0))
    
    evutil_make_socket_nonblocking(socket)
    bev = bufferevent_socket_new(eventBase, socket, options)
    bufferevent_socket_connect(bev, nil, 0)
    bufferevent_setcb(bev, HttpSession.readcb, nil, HttpSession.eventcb, ptr)
    bufferevent_enable(bev, Int16(EV_READ|EV_WRITE));
  }
  
  static func clean(ptr: UnsafeMutablePointer<HttpSession>?) {
    if let ptr = ptr {
      ptr.pointee.clean()
      ptr.deinitialize(count: 1)
      ptr.deallocate()
    }
  }
  
  func getRequest() -> HttpRequest? {
    return request
  }
  
  func clean() {
    timer.free()
    bufferevent_free(bev)
  }
  
  mutating func parseLinesToHttpRequest(lines: [UnsafeMutablePointer<Int8>]) {
    if lines.isEmpty {
      return
    }
    
    let requestLine = String(cString: lines[0])
    var headers = [String: String]()
    
    for i in 1..<lines.count {
      let pair = String(cString: lines[i]).split(separator: ":")
      let header = pair.first ?? ""
      let value = pair.last ?? ""
      headers[String(header)] = String(value)
    }
    
    self.request = HttpRequest(requestLine: requestLine, headers: headers)
    
    lines.forEach {
      free($0)
    }
  }
}

extension HttpSession {
  static var readcb: bufferevent_data_cb = { (bev, ctx) in
    var input: OpaquePointer
    var output: OpaquePointer
    var n = 0
    
    input = bufferevent_get_input(bev)
    output = bufferevent_get_output(bev)
    
    var lines = [UnsafeMutablePointer<Int8>]()

    while true {
      let line = evbuffer_readln(input, &n, EVBUFFER_EOL_CRLF)
      if line == nil {
        break
      }
      
      lines.append(line!)
    }
    
    var parser = ctx?.load(as: HttpSession.self)
    parser?.parseLinesToHttpRequest(lines: lines)
    let request = parser?.getRequest()
    
    
    let string = String("HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nContent-Length: 0\r\n\r\n")
    
    _ = string.withCString { cstr in
      evbuffer_add(output, cstr, string.lengthOfBytes(using: .ascii))
    }
  }
}

extension HttpSession {
  static var writecb: bufferevent_data_cb = { (bev, ctx) in }
}

extension HttpSession {
  static var eventcb: bufferevent_event_cb = { (bev, event, arg) in
    if event & Int16(BEV_EVENT_CONNECTED) != 0 {
      print("CONNECTED")
      var parser = arg?.load(as: HttpSession.self)
      parser?.timer.stop()
    } else if event & Int16(BEV_EVENT_EOF) != 0 {
      print("EOF")
      var parser = arg?.load(as: HttpSession.self)
      parser?.timer.start()
    } else if event & Int16(BEV_EVENT_ERROR) != 0 {
      print("ERROR")
    } else if event & Int16(BEV_EVENT_TIMEOUT|BEV_EVENT_READING) != 0 {
      print("TIMEOUT")
    }
  }
}
