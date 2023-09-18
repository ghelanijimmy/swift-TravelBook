//
//  ViewController.swift
//  TravelBook
//
//  Created by Jimmy Ghelani on 2023-09-18.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var comment: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    var hasData = false
    
    var selectedTitle = ""
    var selectedTitleID: UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationlatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        name.isEnabled = !hasData
        comment.isEnabled = !hasData
        saveButton.isHidden = hasData
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            // core data request
            let stringUUID = selectedTitleID!.uuidString
            
            getData(for: stringUUID)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = .black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: annotationlatitude, longitude: annotationLongitude)) { placemarks, error in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    }
                }
            }
        }
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = name.text
            annotation.subtitle = comment.text
            
            if let nameText = name.text?.isEmpty, let commentText = comment.text?.isEmpty {
                if !nameText && !commentText && !hasData {
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }

    @IBAction func saveButtonPressed(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = Places(context: context)
        newPlace.id = UUID()
        newPlace.title = name.text
        newPlace.subtitle = comment.text
        newPlace.latitude = chosenLatitude
        newPlace.longitude = chosenLongitude
        
        do {
            try context.save()
            name.text = nil
            comment.text = nil
            NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
            navigationController?.popViewController(animated: true)
        } catch {
            print("Couldn't save the data: \(error)")
        }
        
    }
    
    func getData(for placeID: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = Places.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "id == %@", placeID)
        
        do {
            let results = try context.fetch(request)
            for result in results {
                annotationTitle = result.title!
                annotationSubtitle = result.subtitle!
                annotationlatitude = result.latitude
                annotationLongitude = result.longitude
                
                let annotation = MKPointAnnotation()
                annotation.title = annotationTitle
                annotation.subtitle = annotationSubtitle
                let coordinate = CLLocationCoordinate2D(latitude: annotationlatitude, longitude: annotationLongitude)
                annotation.coordinate = coordinate
                
                mapView.addAnnotation(annotation)
                name.text = annotationTitle
                comment.text = annotationSubtitle
                
                locationManager.stopUpdatingLocation()
                
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                
                mapView.setRegion(region, animated: true)
            }
        } catch {
            print("Couldnt' find the place: \(error)")
        }
    }
    
}

#Preview("With Data") {
    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    let controller = storyboard.instantiateViewController(withIdentifier: "mapVC") as! ViewController
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    
    let fetchRequest = Places.fetchRequest()
    do {
        let results = try context.fetch(fetchRequest)
        
        if results.count > 0 {
            controller.hasData = true
            controller.selectedTitle = results[0].title!
            controller.selectedTitleID = results[0].id!
        }
    } catch {
        print("Couldn't fetch data: \(error)")
    }
    
    
    return UINavigationController(rootViewController: controller)
}

#Preview("Without Data") {
    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    let controller = storyboard.instantiateViewController(withIdentifier: "mapVC") as! ViewController
    
    return UINavigationController(rootViewController: controller)
}
