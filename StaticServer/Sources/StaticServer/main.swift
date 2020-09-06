#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

import libevent

func main() {
  guard let base = event_base_new() else {
    return
  }
  let method = String(cString: event_base_get_method(base))
  print("libevent uses \(method) backend")
}

main()
