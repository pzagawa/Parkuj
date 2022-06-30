//
//  GeoTools.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 09/09/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import CoreLocation

struct GeoLimits
{
    //POLAND
    //https://en.wikipedia.org/wiki/Decimal_degrees
    //decimal
    //places   degrees          distance
    //-------  -------          --------
    //0        1                111  km
    //1        0.1              11.1 km
    //2        0.01             1.11 km
    //3        0.001            111  m
    //4        0.0001           11.1 m
    //5        0.00001          1.11 m
    //6        0.000001         11.1 cm

    //LONGITUDE - długość geograficzna (0 do 180°E, 0 do -180°W). Południk 15° Stargard.
    static let MIN_LON: CLLocationDegrees  = 14.1  //zachód
    static let MAX_LON: CLLocationDegrees  = 24.0  //wschód
    
    //LATITUDE - szerokość geograficzna (+90° = 90°N, –90° = 90°S). Równik to 0°, bieguny to 90°.
    static let MAX_LAT: CLLocationDegrees  = 54.8  //północ
    static let MIN_LAT: CLLocationDegrees  = 49.2  //południe

    static var lonSpan: CLLocationDegrees
    {
        return abs(MAX_LON - MIN_LON)
    }

    static var latSpan: CLLocationDegrees
    {
        return abs(MAX_LAT - MIN_LAT)
    }

    static var center: CLLocationCoordinate2D
    {
        let lat = MIN_LAT + (latSpan / 2)
        let lon = MIN_LON + (lonSpan / 2)

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

class GeoTools
{
    static private let EARTH_RADIUS             = 6378100.0
    static private let BEARING_WEST             = 90.0
    static private let BEARING_SOUTH            = 180.0
    static private let ROUND_PRECISION: Double  = 100000 //5 decimal places - 1 meter precision
    static private let DEG_CALC_STEP: Double    = 0.0001

    static func toString(_ degrees: CLLocationDegrees) -> String
    {
        return String(format: "%.5f", degrees)
    }

    static func toString(_ location: CLLocationCoordinate2D) -> String
    {
        let lat = toString(location.latitude)
        let lon = toString(location.longitude)
        return "\(lat),\(lon)"
    }

    static func toString(_ location: CLLocation) -> String
    {
        return toString(location.coordinate)
    }

    static func roundLocation(_ value: Double) -> Double
    {
        return trunc(value * ROUND_PRECISION) / ROUND_PRECISION
    }

    static func roundLocation(location: CLLocationCoordinate2D) -> CLLocationCoordinate2D
    {
        let lat = roundLocation(location.latitude)
        let lon = roundLocation(location.longitude)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    static func locationToWest(distanceMeters: Double, origin: CLLocationCoordinate2D) -> CLLocationCoordinate2D
    {
        return locationWithBearing(bearing: BEARING_WEST, distanceMeters: distanceMeters, origin: origin)
    }

    static func locationToSouth(distanceMeters: Double, origin: CLLocationCoordinate2D) -> CLLocationCoordinate2D
    {
        return locationWithBearing(bearing: BEARING_SOUTH, distanceMeters: distanceMeters, origin: origin)
    }

    static func locationWithBearing(bearing: Double, distanceMeters: Double, origin: CLLocationCoordinate2D) -> CLLocationCoordinate2D
    {
        let distRadians = distanceMeters / EARTH_RADIUS // earth radius in meters

        let lat1 = origin.latitude.deg2Rad
        let lon1 = origin.longitude.deg2Rad

        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing.deg2Rad))
        let lon2 = lon1 + atan2(sin(bearing.deg2Rad) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2.rad2Deg, longitude: lon2.rad2Deg)
    }

    //szukaj lokacji z lewa na prawo (W 2 E)
    //długość zmienia się zależnie od lat/szerokości geogr.
    //wolne ale precyzyjne
    static func calcLocationToWestWithDistance(location: CLLocationCoordinate2D, meters: Int) -> CLLocationCoordinate2D
    {
        let start_coords = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        var end_coords = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let start_location = CLLocation(latitude: start_coords.latitude, longitude: start_coords.longitude)

        while (true)
        {
            let end_location = CLLocation(latitude: end_coords.latitude, longitude: end_coords.longitude)
           
            if (end_location.distance(from: start_location) >= CLLocationDistance(meters))
            {
                break
            }
            else
            {
                end_coords.longitude += DEG_CALC_STEP
            }
        }

        return end_coords;
    }

    //szukaj lokacji z góry na dół (N 2 S)
    //długość zawsze taka sama niezależnie od lon/długości geogr.
    //wolne ale precyzyjne
    static func calcLocationToSouthWithDistance(location: CLLocationCoordinate2D, meters: Int) -> CLLocationCoordinate2D
    {
        let start_coords = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        var end_coords = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let start_location = CLLocation(latitude: start_coords.latitude, longitude: start_coords.longitude)

        while (true)
        {
            let end_location = CLLocation(latitude: end_coords.latitude, longitude: end_coords.longitude)
           
            if (end_location.distance(from: start_location) >= CLLocationDistance(meters))
            {
                break
            }
            else
            {
                end_coords.latitude -= DEG_CALC_STEP
            }
        }

        return end_coords;
    }

}
