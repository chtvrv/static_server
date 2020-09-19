//
//  File.swift
//  
//
//  Created by a.chetverov on 9/11/20.
//

import Foundation

func getSockAddr() -> sockaddr_in {
  let port : UInt16 = 80
  let ip_string : String = "localhost"
  
#if os(macOS)
  let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
  let htons  = isLittleEndian ? _OSSwapInt16 : { $0 }
  
  var sockAddress = sockaddr_in(
    sin_len:    UInt8(MemoryLayout<sockaddr_in>.size),
    sin_family: sa_family_t(AF_INET),
    sin_port:   htons( port ),
    sin_addr:   in_addr(s_addr: 0),
    sin_zero:   ( 0, 0, 0, 0, 0, 0, 0, 0 )
  )
#else
  var sockAddress = sockaddr_in(
    sin_family: sa_family_t(AF_INET),
    sin_port:   htons( port ),
    sin_addr:   in_addr(s_addr: 0),
    sin_zero:   ( 0, 0, 0, 0, 0, 0, 0, 0 )
  )
#endif
  
  _ = ip_string.withCString({ cs in
    inet_pton(AF_INET, cs, &sockAddress.sin_addr)
  })
  
  return sockAddress
}
