//
//  NSURLExtension.swift
//  Meetup
//
//  Created by Shukhrat Tursunov on 3/7/16.
//  Copyright © 2016 Shukhrat Tursunov. All rights reserved.
//

import Foundation

extension NSURL {
  var fragments: [String: String] {
    var results = [String: String]()
    
    if let paramsRange = self.description.rangeOfString("?") {
      let params = self.description.substringFromIndex(paramsRange.startIndex.advancedBy(1))
      let pairs = params.componentsSeparatedByString("&")
      if pairs.count > 0 {
        for pair: String in pairs {
          if let keyValue = pair.componentsSeparatedByString("=") as [String]? {
            results.updateValue(keyValue[1], forKey: keyValue[0])
          }
        }
      }
    }
    return results
  }
}