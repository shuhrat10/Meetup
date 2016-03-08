//
//  MainViewController.swift
//  Meetup
//
//  Created by Shukhrat Tursunov on 3/7/16.
//  Copyright © 2016 Shukhrat Tursunov. All rights reserved.
//

import UIKit
import CoreLocation

class MainViewController: UITableViewController {

  // MARK: - Variables

  let serverManager = ServerManager.sharedManager
  let locationManager = CLLocationManager()
  var firstTimeAppear = false
  var events = [Event]()
  var totalEvents = 0
  var offsetInRequest = 0

  var userLocation : CLLocation?
  
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
  }
  
  // MARK: - UITableViewController

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.events.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
    let event = self.events[indexPath.row]
    
    cell.textLabel?.text = event.name
    
    return cell
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row == self.events.count - 5 {
      self.showLoadingCell(true)
      self.getEventsFromServer()
    }
  }
  
  // MARK: - Helper method
  
  func authorization() {
    if firstTimeAppear == false {
      firstTimeAppear = true
      
      self.serverManager.authorizeUser({ user, token in
        self.getEventsFromServer()
      }, onFailure: { error, statusCode in
          
      })
    }
  }
  
  func showLoadingCell(show: Bool) {
    
    let view = UIView(frame: CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 50))
    let spiner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    view.backgroundColor = UIColor(red: 0.917, green: 0.917, blue: 0.917, alpha: 1.0)
    spiner.startAnimating()
    view.addSubview(spiner)
    
    spiner.translatesAutoresizingMaskIntoConstraints = false
    
    let centerX = NSLayoutConstraint(item: spiner, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
    let centerY = NSLayoutConstraint(item: spiner, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
    view.addConstraints([centerX, centerY])
    
    tableView.tableFooterView = show ? view : nil
  }

  // MARK: - API
  
  func getEventsFromServer() {
  
    guard let userLocation = userLocation else {
      return
    }
    
    self.serverManager.getEvents(withOffset: offsetInRequest, count: Constants.eventsInRequest, location: userLocation, onSuccess: { events, totalCount in
      
      self.events.appendContentsOf(events)
      
      var newPaths: [NSIndexPath] = [NSIndexPath]()
      
      for index in (self.events.count - events.count)..<self.events.count {
        newPaths.append(NSIndexPath(forRow: index, inSection: 0))
      }
      
      self.tableView.beginUpdates()
      self.tableView.insertRowsAtIndexPaths(newPaths, withRowAnimation: UITableViewRowAnimation.Top)
      self.tableView.endUpdates()
      
      self.offsetInRequest += 1
      
      if totalCount > 0 {
        self.totalEvents = totalCount
        self.showLoadingCell(false)
      }
      
      }, onFailure: { (error, statusCode) -> Void in
        
    })
  }
}


// MARK: - Getting location of current User

extension MainViewController: CLLocationManagerDelegate {
  
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    switch status {
    case .NotDetermined:
      self.locationAskPermission()
    case .Restricted, .Denied:
      self.locationDisabledAlert()
    case .AuthorizedWhenInUse:
      locationManager.startUpdatingLocation()
    default: break
    }
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print("didFailWithError \(error)")
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let location = locations.last!
    
    if location.horizontalAccuracy <= 500.0 {
      locationManager.stopUpdatingLocation()
      self.userLocation = location
      authorization()
    }
  }
  
  // MARK: - Helper methods
  
  func locationAskPermission() {
    
    let alert = UIAlertController(title: "Permission",
      message: "This app needs access to the Location. Do you wanna grant access?",
      preferredStyle: .Alert)
    
    let allowAction = UIAlertAction(title: "Allow", style: .Default) { action in
      self.locationManager.requestWhenInUseAuthorization()
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    
    alert.addAction(allowAction)
    alert.addAction(cancelAction)
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  func locationDisabledAlert() {
    
    let alert = UIAlertController(title: "This app does not have access to Location service", message: "You can enable access in Settings->Privacy->Location->Location Services", preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: "OK", style: .Default) { action in
      
      dispatch_async( dispatch_get_main_queue(), {
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
      })
    }
    alert.addAction(okAction)
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
}
