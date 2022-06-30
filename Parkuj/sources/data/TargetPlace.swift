//
//  TargetPlace.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 19/10/2020.
//

import Foundation
import CoreLocation
import MapKit

class TargetPlace: CustomStringConvertible, Identifiable, Hashable
{
    let sourceLocation: CLLocation
    
    private let placeItem: PlaceItem
    private let tagText: PlaceTagText
    
    private var addressText: String?
    
    private var directDistance: CLLocationDistance
    private var routedDistance: CLLocationDistance?
    private var routedTravelTime: TimeInterval?
    
    let spanSize: GeoSpan.Size

    // #MARK: test item
    init(testText: String)
    {
        sourceLocation = CLLocation()
        placeItem = PlaceItem()
        tagText = PlaceTagText(place_tags: [])
        addressText = "Test Address: \(testText)"
        directDistance = 0
        routedDistance = 0
        routedTravelTime = 0
        spanSize = GeoSpan.sizeFrom(distance: 0)
    }
    
    init(sourceLocation: CLLocation, placeItem: PlaceItem)
    {
        let direct_distance = sourceLocation.distance(from: placeItem.location)

        self.sourceLocation = sourceLocation
        self.placeItem = placeItem
        self.directDistance = direct_distance
        self.tagText = placeItem.tagText

        self.spanSize = GeoSpan.sizeFrom(distance: direct_distance)
    }
    
    var id: String
    {
        return placeItem.locationKey
    }
    
    func setAddressText(_ value: String)
    {
        self.addressText = value
    }

    func setRoutedDistance(_ value: CLLocationDistance)
    {
        self.routedDistance = value
    }

    func setRoutedTravelTime(_ value: TimeInterval)
    {
        self.routedTravelTime = value
    }

    var isAddressText: Bool
    {
        return (self.addressText != nil)
    }

    var isRoutedDistance: Bool
    {
        return (self.routedDistance != nil)
    }

    var isRoutedTravelTime: Bool
    {
        return (self.routedTravelTime != nil)
    }

    var extendedDataInfo: String
    {
        var text: String = ""
        
        text += isAddressText ? "A" : ""
        text += isRoutedDistance ? "D" : ""
        text += isRoutedTravelTime ? "T" : ""

        return "[" + text + "]"
    }

    var coordinate: CLLocationCoordinate2D
    {
        return self.placeItem.coordinate
    }

    var distance: CLLocationDistance
    {
        if let value = self.routedDistance
        {
            return value
        }
        else
        {
            return directDistance
        }
    }

    var distanceText: String
    {
        if isRoutedDistance
        {
            return TargetPlace.distanceToTextKM(value: distance)
        }
        else
        {
            return "≥ " + TargetPlace.distanceToTextKM(value: distance)
        }
    }
    
    var travelTime: TimeInterval
    {
        var result: TimeInterval = 0
    
        if let value = self.routedTravelTime
        {
            result = value
        }
        else
        {
            //medium approximate speed for direct distance
            let SPEED_50_KMH = 50_000.0
            let SPEED_MetersPerSecond = SPEED_50_KMH / 3600
            result = (distance / SPEED_MetersPerSecond)
        }
        
        if result < 60
        {
            result = 60
        }
        
        return result
    }

    var travelTimeText: String
    {
        if isRoutedTravelTime
        {
            return TargetPlace.timeToTextMinutes(value: self.travelTime)
        }
        else
        {
            return "≈ " + TargetPlace.timeToTextMinutes(value: self.travelTime)
        }
    }
    
    var description: String
    {
        return "ext data: \(extendedDataInfo). distance: \(distanceText). place: \(placeItem). span size: \(spanSize)"
    }

    var placeMark: MKPlacemark
    {
        let placemark = MKPlacemark(coordinate: self.placeItem.coordinate)
        return placemark
    }
    
    var mapItem: MKMapItem
    {
        let mapitem = MKMapItem(placemark: placeMark)
        mapitem.name = tagText.title
        mapitem.pointOfInterestCategory = MKPointOfInterestCategory.parking
        return mapitem
    }
    
    var location: CLLocation
    {
        return placeItem.location
    }
    
    var locationKey: String
    {
        return placeItem.locationKey
    }
    
    var title: String
    {
        return tagText.title
    }

    var subtitle: String
    {
        let subtitle = tagText.subTitle
        
        if subtitle.isEmpty
        {
            if let address = addressText
            {
                return address
            }
            else
            {
                return "..."
            }
        }
        else
        {
            if let address = addressText
            {
                return subtitle + ", " + address
            }
            else
            {
                return subtitle
            }
        }
    }
    
    var subtitleAddress: String?
    {
        return addressText
    }
    
    var subtitleItems: [String]
    {
        return tagText.subTitleItems
    }

    var summary: String
    {
        return distanceText + " • " + travelTimeText
    }
    
    static func distanceToTextKM(value: CLLocationDistance) -> String
    {
        let value_km = (value / 1000)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if let text = formatter.string(from: NSNumber(value: value_km))
        {
            return text + " km"
        }
        else
        {
            //when failed first case, show only integers
            return String(Int(value_km)) + " km"
        }
    }

    static func timeToTextMinutes(value: TimeInterval) -> String
    {
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 2

        if let result = formatter.string(from: value)
        {
            return result
        }
        else
        {
            return "..."
        }
    }

    static func == (lhs: TargetPlace, rhs: TargetPlace) -> Bool
    {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.id)
        hasher.combine(self.title)
        hasher.combine(self.subtitle)
        hasher.combine(self.isAddressText)
        hasher.combine(self.isRoutedDistance)
        hasher.combine(self.isRoutedTravelTime)
    }
}
