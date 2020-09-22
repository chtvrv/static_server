import Foundation
import libevent

class Server {
  func start() {
    print("Server starting...")
    
    if !WorkQueue.shared.configureWorkers() {
      perror("Couldn't create workers")
      return
    }
    
    var sockAddress = getSockAddr()
    
    let listener = withUnsafePointer(to: &sockAddress) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        evconnlistener_new_bind(EventLoop.shared.eventBase, Server.accept_conn_cb, nil, LEV_OPT_CLOSE_ON_FREE|LEV_OPT_REUSEABLE, -1, $0, Int32(UInt8(MemoryLayout<sockaddr_in>.size)))
      }
    }
    if listener == nil {
      perror("Couldn't create listener")
      return
    }
    
    evconnlistener_set_error_cb(listener, Server.accept_error_cb)
    EventLoop.shared.run()
  }
  
  func shutdown() {
    print("Shutdown listener");
    EventLoop.shared.shutdown()
    print("Stopping workers");
    WorkQueue.shared.shutdown()
  }
}

extension Server {
  static var accept_conn_cb: evconnlistener_cb = { (listener, socket, addr, len, ctx) in
    let parser = UnsafeMutablePointer<HttpSession>.allocate(capacity: 1)
    parser.initialize(to: HttpSession(
      socket: socket,
      options: Int32(BEV_OPT_CLOSE_ON_FREE.rawValue),
      ptr: parser)
    )
    
    let job = Job(function: dispatchJob, data: parser)
    WorkQueue.shared.addJobToQueue(job: job)
    
  }
  
  static var accept_error_cb: evconnlistener_errorcb = { (listener, ctx) in
    let base = evconnlistener_get_base(listener)
    print(stderr, "Got an error on the listener. ",
          "Shutting down.\n", errno)
    event_base_loopexit(base, nil)
  }
}

var server = Server()

Signals.trap(signal: .int) { signal in
  server.shutdown()
}

server.start()

