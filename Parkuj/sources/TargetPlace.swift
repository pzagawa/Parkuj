//
//  TargetPlace.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 19/10/2020.
//

import Foundation
import CoreLocation
import MapKit

struct TargetPlace: CustomStringConvertible
{
    let location: CLLocation
    let placeItem: PlaceItem
    let distance: CLLocationDistance
    let tagText: PlaceTagText
    
    init(location: CLLocation, placeItem: PlaceItem)
    {
        self.location = location
        self.placeItem = placeItem
        self.distance = self.location.distance(from: self.placeItem.location)
        self.tagText = placeItem.tagText
    }

    var description: String
    {
        return "distance: \(Int(distance)). place: \(placeItem)."
    }

    var placeMark: MKPlacemark
    {
        let placemark = MKPlacemark(coordinate: self.placeItem.coordinate)
        return placemark
    }
    
    var mapItem: MKMapItem
    {
        let mapitem = MKMapItem(placemark: placeMark)
        mapitem.pointOfInterestCategory = MKPointOfInterestCategory.parking
        return mapitem
    }
    
    static func locationToPlacemark(location: CLLocation, completionHandler: @escaping (CLPlacemark?) -> Void)
    {
        let geocoder = CLGeocoder()
            
        geocoder.reverseGeocodeLocation(location)
        {
            (placemarks, error) in
            
            if error == nil
            {
                let first_placemark = placemarks?.first
                completionHandler(first_placemark)
            }
            else
            {
                completionHandler(nil)
            }
        }
    }
}
