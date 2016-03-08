//
//  LoginViewController.swift
//  Meetup
//
//  Created by Shukhrat Tursunov on 3/7/16.
//  Copyright © 2016 Shukhrat Tursunov. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

typealias onSuccessBlock = STAccessToken -> Void


class LoginViewController: UIViewController {

  // MARK: - Variables
  
  var successBlock: onSuccessBlock?
  var failureBlock: onFailureBlock?

  // MARK: - Outlets
  
  @IBOutlet weak var webView: UIWebView!

  // MARK: - Lifecycle
 
  convenience init(onSuccess: onSuccessBlock, onFailure: onFailureBlock) {
    self.init()
    self.successBlock = onSuccess
    self.failureBlock = onFailure
  }
  
  deinit {
    webView.delegate = nil
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelAction:")
    self.navigationItem.setRightBarButtonItem(cancelButton, animated: false)
    self.navigationItem.title = "Login"

    var rect = self.view.bounds
    rect.origin = CGPointZero
    
    let webView = UIWebView(frame: rect)
    webView.autoresizingMask = ([.FlexibleHeight, .FlexibleWidth])
    webView.delegate = self
    self.view.addSubview(webView)
    self.webView = webView
    
    let stringURL = API.authorizeURL + "?" + "client_id=" + API.clientID + "&" + "response_type=code" + "&" + "redirect_uri=" + API.redirectURL
    guard let url = NSURL(string: stringURL) else {
      return
    }
    let request = NSURLRequest(URL: url)
    webView.loadRequest(request)
  }
  
  // MARK: - Actions
  
  func cancelAction(sender: UIBarButtonItem) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
}


// MARK: - UIWebViewDelegete

extension LoginViewController: UIWebViewDelegate {
  
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {

    if let url = request.URL where url.host == "stursunov.com" {
      if let code = url.fragments["code"] {

        self.getAccessToken(code, onSuccess: { token in
        
          self.webView.delegate = nil
          if let successBlock = self.successBlock {
            successBlock(token)
          }
          self.dismissViewControllerAnimated(true, completion: nil)
          
        }, onFailure: { error, statusCode in
            
        })
        return false
      }
    }
    return true
  }
  
  func getAccessToken(code: String, onSuccess: STAccessToken -> Void, onFailure: onFailureBlock) {

    let request = NSMutableURLRequest(URL: NSURL(string: "https://secure.meetup.com/oauth2/access")!)
    
    request.HTTPMethod = "POST"
    
    let postString = "client_id=t3fhfpqe6pptmru6ggj2boun9n&client_secret=k4a0l1qk9ui8m0a4dq93tnoedv&grant_type=authorization_code&redirect_uri=https%3A%2F%2Fstursunov.com&code=\(code)"
    
    request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
      
      guard error == nil && data != nil else {
        print("error=\(error)")
        return
      }
      
      if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
        print("statusCode should be 200, but is \(httpStatus.statusCode)")
        print("response = \(response)")
      }
      
      let params = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
      
      //      print(params)
      
      guard let access_token = params["access_token"] as? String,
        refresh_token = params["refresh_token"] as? String,
        token_type = params["token_type"] as? String,
        expires_in = params["expires_in"] as? Int else {
          return
      }
      
      let token = STAccessToken(token: access_token, refreshToken: refresh_token, tokenType: token_type, expiresIn: expires_in)
      onSuccess(token)
      
    }
    task.resume()
  }
  
}