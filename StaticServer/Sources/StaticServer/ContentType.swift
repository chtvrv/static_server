//
//  File.swift
//  
//
//  Created by a.chetverov on 9/16/20.
//

import Foundation

// .html, .css, js, jpg, .jpeg, .png, .gif, .swf

enum MIMEtype: String, CustomStringConvertible {
  case html
  case css
  case js
  case jpg
  case jpeg
  case png
  case gif
  case swf
  case unknown
  
  var description: String {
    switch self {
      case .html:
        return "text/html"
      case .css:
        return "text/css"
      case .js:
        return "application/javascript"
      case .jpg:
        return "image/jpeg"
      case .jpeg:
        return "image/jpeg"
      case .png:
        return "image/png"
      case .gif:
        return "image/gif"
      case .swf:
        return "application/x-shockwave-flash"
      case .unknown:
        return "unknown"
    }
  }
}
