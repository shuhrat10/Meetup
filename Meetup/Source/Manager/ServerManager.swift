//
//  ServerManager.swift
//  Meetup
//
//  Created by Shukhrat Tursunov on 3/7/16.
//  Copyright © 2016 Shukhrat Tursunov. All rights reserved.
//

import Alamofire
import SwiftyJSON
import CoreLocation


struct STAccessToken {
  let token: String
  let refreshToken: String
  let tokenType: String
  let expiresIn: Int
}

typealias onFailureBlock = (error: NSError, statusCode: Int) -> Void


class ServerManager {
  
  static let sharedManager = ServerManager()
  var accessToken: STAccessToken?

  
  func authorizeUser(onSuccess: (user: User, token: STAccessToken) -> Void, onFailure: onFailureBlock) {
   
    let LoginView = LoginViewController( onSuccess: { token in
      
        self.accessToken = token
        onSuccess(user: User(name: "Demo User"), token: token)
      
      }) { (error, statusCode) -> Void in
      
    }
    
    let nav = UINavigationController(rootViewController: LoginView)
    let mainVC = UIApplication.sharedApplication().keyWindow?.rootViewController
    mainVC?.presentViewController(nav, animated: true, completion: nil)
  }
  
  
  // Get user info
  
  func getUser(onSuccess: User -> Void, onFailure: onFailureBlock) {
    
  }
  
  // Get events 
    
  func getEvents(withOffset offset: Int, count: Int, location: CLLocation, onSuccess: (events: [Event], totalCount: Int) -> Void, onFailure: onFailureBlock) {
    
    guard let token = self.accessToken?.token else {
      print("Token is not exist.")
      return
    }
    
    let params = [
      "lat": String(location.coordinate.latitude),
      "lon": String(location.coordinate.longitude),
      "category": "34",
      "page": String(count),
      "offset": String(offset),
      "access_token": token,
    ]
    
    Alamofire.request(.GET, "https://api.meetup.com/2/open_events", parameters: params)
      .responseJSON { response in
        
        if let value = response.result.value {
          
          let json = JSON(value)
          var events = [Event]()
          
          for (_, eventJSON):(String, JSON) in json["results"] {
            events.append(Event(json: eventJSON))
          }
          
          let totalCount = json["meta"]["total_count"].intValue
          
          onSuccess(events: events, totalCount: totalCount > 0 ? totalCount - 1 : 0)
        }
    }
  }
}