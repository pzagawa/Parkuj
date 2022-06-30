//
//  GeoTools.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 09/09/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

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

extension CLLocation
{
    var isValid: Bool
    {
        if (self.coordinate.longitude != 0) && (self.coordinate.latitude != 0)
        {
            return true
        }
        
        return false
    }
}

extension CLLocationDegrees
{
    var toRadians: Double
    {
        return ((self / 180.0) * Double.pi)
    }
}

extension Double
{
    var radiansToDegrees: CLLocationDegrees
    {
        return CLLocationDegrees(self * (180.0 / Double.pi))
    }
}

struct GeoDefaults
{
    static var initRegion: MKCoordinateRegion
    {
        let coords = CLLocationCoordinate2D(latitude: 52.0, longitude: 19.2)
        let span = MKCoordinateSpan(latitudeDelta: 8.0, longitudeDelta: 8.0)
        
        return MKCoordinateRegion(center: coords, span: span)
    }
}

class GeoTools
{
    static private let EARTH_RADIUS             = 6378100.0
    static private let BEARING_WEST             = 90.0
    static private let BEARING_SOUTH            = 180.0
    static private let ROUND_PRECISION: Double  = 100000 //5 decimal places - 1 meter precision
    static private let DEG_CALC_STEP: Double    = 0.0001

    static func locationKey(location: CLLocation) -> String
    {
        return GeoTools.locationKey(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
    }

    static func locationKey(lat: CLLocationDegrees, lon: CLLocationDegrees) -> String
    {
        return String(format: "%.5f:%.5f", lat, lon)
    }

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

    static func regionSizeInMeters(region: MKCoordinateRegion) -> CLLocationDistance
    {
        let span = region.span
        let centerView = region.center

        let loc1 = CLLocation(latitude: centerView.latitude - span.latitudeDelta * 0.5, longitude: centerView.longitude)
        let loc2 = CLLocation(latitude: centerView.latitude + span.latitudeDelta * 0.5, longitude: centerView.longitude)
        let loc3 = CLLocation(latitude: centerView.latitude, longitude: centerView.longitude - span.longitudeDelta * 0.5)
        let loc4 = CLLocation(latitude: centerView.latitude, longitude: centerView.longitude + span.longitudeDelta * 0.5)

        return min(loc1.distance(from: loc2), loc3.distance(from: loc4))
    }
    
    static func centerPoint(targetPlaces: [TargetPlace]) -> CLLocationCoordinate2D
    {
        guard targetPlaces.count > 1 else
        {
            return targetPlaces.first?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }

        var x = Double(0)
        var y = Double(0)
        var z = Double(0)

        for target_place in targetPlaces
        {
            let lat = target_place.coordinate.latitude.toRadians
            let lon = target_place.coordinate.longitude.toRadians
            
            x += cos(lat) * cos(lon)
            y += cos(lat) * sin(lon)
            z += sin(lat)
        }

        x /= Double(targetPlaces.count)
        y /= Double(targetPlaces.count)
        z /= Double(targetPlaces.count)

        let lon = atan2(y, x)
        let hyp = sqrt(x * x + y * y)
        let lat = atan2(z, hyp)

        return CLLocationCoordinate2D(latitude: lat.radiansToDegrees, longitude: lon.radiansToDegrees)
    }
}

struct GeoSpan
{
    enum Size: String, CaseIterable
    {
        case Km_50; case Km_40; case Km_30; case Km_20; case Km_10; case Km_5; case Km_4; case Km_3; case Km_2; case Km_1;
        case Meters_500; case Meters_400; case Meters_300; case Meters_200; case Meters_100;
    }
    
    static func coordinate(size: Size) -> MKCoordinateSpan
    {
        var delta: CLLocationDegrees = 0
        
        switch size
        {
        case .Km_50: delta = 0.5
        case .Km_40: delta = 0.4
        case .Km_30: delta = 0.3
        case .Km_20: delta = 0.2
        case .Km_10: delta = 0.1
        case .Km_5: delta = 0.05
        case .Km_4: delta = 0.04
        case .Km_3: delta = 0.03
        case .Km_2: delta = 0.02
        case .Km_1: delta = 0.01
        case .Meters_500: delta = 0.0050
        case .Meters_400: delta = 0.0040
        case .Meters_300: delta = 0.0030
        case .Meters_200: delta = 0.0020
        case .Meters_100: delta = 0.0010
        }

        return MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
    }

    static func distance(size: Size) -> CLLocationDistance
    {
        switch size
        {
        case .Km_50: return 50_000
        case .Km_40: return 40_000
        case .Km_30: return 30_000
        case .Km_20: return 20_000
        case .Km_10: return 10_000
        case .Km_5: return 5_000
        case .Km_4: return 4_000
        case .Km_3: return 3_000
        case .Km_2: return 2_000
        case .Km_1: return 1_000
        case .Meters_500: return 500
        case .Meters_400: return 400
        case .Meters_300: return 300
        case .Meters_200: return 200
        case .Meters_100: return 100
        }
    }
    
    static func sizeFrom(distance: CLLocationDistance) -> Size
    {
        let span_distance = distance * 2

        for size in Size.allCases.reversed()
        {
            let span_size = GeoSpan.distance(size: size)
                
            if (span_distance < span_size)
            {
                return size
            }
        }

        return .Km_50
    }

    static func inc(size: Size) -> Size
    {
        var found = false
        
        for size_item in Size.allCases.reversed()
        {
            if found
            {
                return size_item
            }
            if size == size_item
            {
                found = true
            }
        }
        
        return .Km_50
    }

    static func dec(size: Size) -> Size
    {
        var found = false
        
        for size_item in Size.allCases
        {
            if found
            {
                return size_item
            }
            if size == size_item
            {
                found = true
            }
        }
        
        return .Meters_100
    }
}
