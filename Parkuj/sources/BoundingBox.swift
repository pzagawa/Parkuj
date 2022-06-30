//
//  BoundingBox.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 18/10/2020.
//

import Foundation
import CoreLocation

class BoundingBox: CustomStringConvertible
{
    private var location: CLLocationCoordinate2D = CLLocationCoordinate2D()
    private let kiloMeters: CLLocationDegrees
    private var lonDiffFor1KM: CLLocationDegrees = 0
    private var latDiffFor1KM: CLLocationDegrees = 0

    init(kiloMeters: Int)
    {
        self.kiloMeters = CLLocationDegrees(kiloMeters)
    }
    
    func setLocation(location: CLLocationCoordinate2D)
    {
        if (location.latitude == self.location.latitude) && (location.longitude == self.location.longitude)
        {
            //skip if no location change
            return
        }

        self.location = location

        //calc LON diff for 1000 meters
        let end_lon = GeoTools.calcLocationToWestWithDistance(location: location, meters: 1000)

        //calc LAT diff for 1000 meters
        let end_lat = GeoTools.calcLocationToSouthWithDistance(location: location, meters: 1000)
    
        lonDiffFor1KM = abs(end_lon.longitude - location.longitude)
        latDiffFor1KM = abs(end_lat.latitude - location.latitude)
    }
    
    var latDiff: CLLocationDegrees
    {
        return (latDiffFor1KM * (kiloMeters / 2))
    }

    var lonDiff: CLLocationDegrees
    {
        return (lonDiffFor1KM * (kiloMeters / 2))
    }

    var minLat: CLLocationDegrees
    {
        return (location.latitude + latDiff)
    }

    var maxLat: CLLocationDegrees
    {
        return (location.latitude - latDiff)
    }

    var minLon: CLLocationDegrees
    {
        return (location.longitude - lonDiff)
    }

    var maxLon: CLLocationDegrees
    {
        return (location.longitude + lonDiff)
    }

    var min: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
    }

    var max: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
    }

    var sizeLatMeters: Int
    {
        let min_lat = CLLocation(latitude: minLat, longitude: location.longitude)
        let max_lat = CLLocation(latitude: maxLat, longitude: location.longitude)
        
        return Int(max_lat.distance(from: min_lat))
    }

    var sizeLonMeters: Int
    {
        let min_lon = CLLocation(latitude: location.latitude, longitude: minLon)
        let max_lon = CLLocation(latitude: location.latitude, longitude: maxLon)
        
        return Int(max_lon.distance(from: min_lon))
    }
    
    var sizeToString: String
    {
        return "\(sizeLatMeters)x\(sizeLonMeters)"
    }

    var diffLatToString: String
    {
        return "minLat: \(GeoTools.toString(minLat)). maxLat: \(GeoTools.toString(maxLat))"
    }

    var diffLonToString: String
    {
        return "minLon: \(GeoTools.toString(minLon)). maxLon: \(GeoTools.toString(maxLon))"
    }

    var description: String
    {
        let loc_text = GeoTools.toString(self.location)
        
        return "location: \(loc_text). size km: \(kiloMeters). latDiff: \(GeoTools.toString(latDiff)). lonDiff: \(GeoTools.toString(lonDiff)). size: \(sizeToString)."
    }

    func isInside(place_item: PlaceItem) -> Bool
    {
        if (place_item.lat < minLat) && (place_item.lat > maxLat)
        {
            if (place_item.lon > minLon) && (place_item.lon < maxLon)
            {
                return true
            }
        }

        return false
    }
}
