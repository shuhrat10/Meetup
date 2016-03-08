//
//  Event.swift
//  Meetup
//
//  Created by Shukhrat Tursunov on 3/7/16.
//  Copyright © 2016 Shukhrat Tursunov. All rights reserved.
//

import Foundation
import SwiftyJSON

class Event {
  
  var id: String
  var name: String
  var description: String
  var distance: Double
  var eventURL: NSURL
  
  init(json: JSON) {
    self.id =  json["id"].stringValue
    self.name = json["name"].stringValue
    self.description = json["description"].stringValue
    self.distance = json["distance"].doubleValue
    self.eventURL = NSURL(string: json["event_url"].stringValue)!
  }
  
}