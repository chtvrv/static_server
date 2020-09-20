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

struct HttpSession : BufferEventSession {
  var bev: BufferEvent
  var request: UnsafeMutablePointer<HttpRequest>?
  var timer: Timer
  var eventBase: OpaquePointer!
  var socket: Int32
  
  init(socket: Int32, options: Int32, ptr: UnsafeMutablePointer<HttpSession>) {
    self.eventBase = event_base_new()
    self.timer = Timer(fd: socket, ctx: ptr, timeout: timeval(tv_sec: 5, tv_usec: 0))
    self.socket = socket
    
    evutil_make_socket_nonblocking(socket)
    bev = bufferevent_socket_new(eventBase, socket, options)
    bufferevent_socket_connect(bev, nil, 0)
    bufferevent_setcb(bev, HttpSession.readcb, HttpSession.writecb, HttpSession.eventcb, ptr)
    bufferevent_enable(bev, Int16(EV_READ|EV_WRITE));
    // таймеры на чтение
    //bufferevent_set
  }
  
  static func clean(ptr: UnsafeMutablePointer<HttpSession>?) {
    if let ptr = ptr {
      ptr.pointee.clean()
      ptr.deinitialize(count: 1)
      ptr.deallocate()
    }
  }
  
  func getRequest() -> UnsafeMutablePointer<HttpRequest>? {
    return request
  }
  
  func clean() {
    timer.free()
    bufferevent_free(bev)
    event_base_free(eventBase)
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
    
    guard var parser = ctx?.load(as: HttpSession.self) else {
      return
    }
    
    parser.request = HttpRequest.createRequestFromLinesArray(lines: lines)
    guard var request = parser.getRequest() else {
      return
    }
    
    guard let response = HttpResponse.GetResponseForRequest(req: request) else {
      return
    }
    
    guard let data = response.pointee.serialize() else {
      return
    }
    
    _ = data.pointee.withUnsafeBytes { buffer in
     evbuffer_add(output, buffer.baseAddress!.assumingMemoryBound(to: UInt8.self),buffer.count)
    }
    
    response.deinitialize(count: 1)
    response.deallocate()
    
    request.deinitialize(count: 1)
    request.deallocate()
    
    data.deinitialize(count: 1)
    data.deallocate()
  }
}

extension HttpSession {
  static var writecb: bufferevent_data_cb = { (bev, ctx) in
    if let ptr = ctx?.assumingMemoryBound(to: HttpSession.self) {
      event_base_loopexit(ptr.pointee.eventBase, nil)
    }
  }
}

extension HttpSession {
  static var eventcb: bufferevent_event_cb = { (bev, event, arg) in
    if event & Int16(BEV_EVENT_CONNECTED) != 0 {
      print("CONNECTED")
      //var parser = arg?.load(as: HttpSession.self)
      //parser?.timer.stop()
    } else if event & Int16(BEV_EVENT_EOF) != 0 {
      print("EOF")
      //var parser = arg?.load(as: HttpSession.self)
      //parser?.timer.start()
    } else if event & Int16(BEV_EVENT_ERROR) != 0 {
      
      print("ERROR")
    } else if event & Int16(BEV_EVENT_TIMEOUT|BEV_EVENT_READING) != 0 {
      print("TIMEOUT")
    }
  }
}
