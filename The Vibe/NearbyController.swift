//
//  NearbyController.swift
//  The Vibe
//
//  Created by Rocomenty on 4/16/17.
//  Copyright © 2017 Shuailin Lyu. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseDatabase

class NearbyController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    
    var currentLocation: CLLocation?
    var ref: FIRDatabaseReference?
    var refHandle: UInt!
    
    var data: [[String]] = [] //index 0 is title, index 1 is organizer
    var locationData: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.userTrackingMode = .follow
        ref = FIRDatabase.database().reference()
        if (currentLocation != nil) {
            fetchActivities()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    //adapted from https://www.youtube.com/watch?v=wl2kqGixL90
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            currentLocation = loc
            changeMapSize(location: loc)
        }
    }
    
    
    
    //adapted from https://www.youtube.com/watch?v=wl2kqGixL90
    func changeMapSize(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func locationButtonPressed(_ sender: UIButton) {
        if let userLocation = mapView.userLocation.location {
            changeMapSize(location: userLocation)
            fetchActivities()
        }
    }
    
    func addPins() {
        mapView.removeAnnotations(mapView.annotations)
        for index in 0 ..< data.count {
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationData[index].coordinate
            annotation.title = data[index][0]
            annotation.subtitle = data[index][1]
            mapView.addAnnotation(annotation)
        }
    }
    
    func fetchActivities() {
        data = []
        locationData = []
        refHandle = ref?.child("Activities").observe(.value, with: { (snapshot) in
            print("fetching for map")
            let dic = snapshot.value! as! NSDictionary
            let dicValue = dic.allValues as NSArray
            
            for singleActivity in dicValue {
                let activity = singleActivity as! NSDictionary
                if let long = activity["longitude"] as? String {
                    if let lat = activity["latitude"] as? String {
                        let longitude = CLLocationDegrees(exactly: (long as NSString).floatValue)
                        let latitude = CLLocationDegrees(exactly: (lat as NSString).floatValue)
                        let eventLocation = CLLocation(latitude: latitude!, longitude: longitude!)
                        if (eventLocation.distance(from: self.currentLocation!) < 10000) {
                            self.data.append([activity["title"], activity["organizer"]] as! [String])
                            self.locationData.append(eventLocation)
                        }
                    }

                }
            }
            
            self.addPins()
            
        })
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "checkmark.png"), for: .normal)
        button.addTarget(self, action: #selector(setLocation), for: .touchUpInside)
        pinView?.rightCalloutAccessoryView = button
        return pinView
    }

    
    func setLocation() {
        //segue to detail view
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
