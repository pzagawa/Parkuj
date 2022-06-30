//
//  TargetPlaces.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 26/11/2020.
//

import Foundation
import CoreLocation
import MapKit
import os

class TargetPlaces
{
    typealias ExtendedDataUpdate = () -> Void
    
    enum RequestExtendedData: String
    {
        case None; case Address; case Routing; case All;
    }

    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "TargetPlaces")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.TargetPlaces")

    private var addressGeocoder = AddressGeocoder()
    private var routingTravelTime = RoutingTravelTime()

    private var targetPlaces: [TargetPlace] = []
        
    private var lastSourceLocationKey: String = ""
    
    private var limitedTopItems: Int = Int.max
    
    var extendedDataUpdateCallback: ExtendedDataUpdate?

    init()
    {
        addressGeocoder.processUpdateCallback =
        {
            [weak self] (placemark: AddressPlacemark) in
            self?.callExtendedDataUpdate(extendedData: .Address)
        }
        
        routingTravelTime.processUpdateCallback =
        {
            [weak self] (placemark: RoutingTravelTime.InfoItem) in
            self?.callExtendedDataUpdate(extendedData: .Routing)
        }
    }
    
    deinit
    {
        addressGeocoder.processUpdateCallback = nil
        routingTravelTime.processUpdateCallback = nil
    }
    
    private func callExtendedDataUpdate(extendedData: RequestExtendedData)
    {
        self.serialQueue.sync
        {
            [weak self] in

            guard let this = self else
            {
                return
            }

            if let callback = this.extendedDataUpdateCallback
            {
                this.logger.debug("ExtendedDataUpdate: \(extendedData.rawValue).")
                
                DispatchQueue.main.async
                {
                    callback()
                }
            }
        }
    }

    func setMaxItems(limitedTop: Int)
    {
        self.limitedTopItems = limitedTop

        logger.info("Set max top items: \(self.limitedTopItems).")
    }

    private func reset()
    {
        logger.debug("Reset data.")
        
        self.serialQueue.sync
        {
            [weak self] in

            self?.targetPlaces.removeAll()
        }
    }

    private func filteredByRegion(sourceLocation: CLLocation, searchLocation: CLLocation, range_kilometers: Int) -> [TargetPlace]
    {
        var items: [TargetPlace] = []

        EmbeddedDataModel.instance.filterPlacesToRegion(searchLocation: searchLocation, range_kilometers: range_kilometers)
        {
            (place_item: PlaceItem) in

            let target_place = TargetPlace(sourceLocation: sourceLocation, placeItem: place_item)
            items.append(target_place)
        }
    
        return items
    }
    
    private func sortedByDistance(sourceLocation: CLLocation, searchLocation: CLLocation, rangeKilometers: Int) -> [TargetPlace]
    {
        var items = filteredByRegion(sourceLocation: sourceLocation, searchLocation: searchLocation, range_kilometers: rangeKilometers)
 
        items.sort
        {
            $0.distance < $1.distance
        }

        let slice = items.prefix(self.limitedTopItems)

        return Array<TargetPlace>(slice)
    }
    
    func resetSourceLocation()
    {
        lastSourceLocationKey = ""
    }
    
    func sourceLocationChanged(sourceLocation: CLLocation) -> Bool
    {
        let source_location_key = GeoTools.locationKey(location: sourceLocation)

        if self.lastSourceLocationKey != source_location_key
        {
            self.lastSourceLocationKey = source_location_key
            return true
        }

        return false
    }

    func search(location: CLLocation, rangeKilometers: Int, requestExtendedData: RequestExtendedData)
    {
        search(sourceLocation: location, searchLocation: location, rangeKilometers: rangeKilometers, requestExtendedData: requestExtendedData)
    }
    
    func search(sourceLocation: CLLocation, searchLocation: CLLocation, rangeKilometers: Int, requestExtendedData: RequestExtendedData)
    {
        //get data items
        let target_places = sortedByDistance(sourceLocation: sourceLocation, searchLocation: searchLocation, rangeKilometers: rangeKilometers)
        
        //update synchronized collection
        self.serialQueue.sync
        {
            [weak self] in
        
            self?.targetPlaces = target_places
        }
    
        updateExtendedData(location: sourceLocation, targetPlaces: target_places, requestExtendedData: requestExtendedData)
    }

    func updateExtendedData(location: CLLocation, targetPlaces: [TargetPlace], requestExtendedData: RequestExtendedData)
    {
        if requestExtendedData != .None
        {
            logger.debug("updateExtendedData: \(requestExtendedData.rawValue). Items: \(targetPlaces.count).")

            if targetPlaces.isEmpty
            {
                logger.debug("* no items to update")
                return
            }

            if requestExtendedData == .Address || requestExtendedData == .All
            {
                //update target places items addresses
                addressGeocoder.process(targetPlaces: targetPlaces)
            }

            if requestExtendedData == .Routing || requestExtendedData == .All
            {
                //update target places items routing travel time
                routingTravelTime.process(sourceLocation: location, targetPlaces: targetPlaces)
            }
        }
    }

    public func itemsData(sorted: Bool) -> [TargetPlace]
    {
        var result: [TargetPlace] = []

        self.serialQueue.sync
        {
            [weak self] in

            guard let this = self else
            {
                return
            }

            //update items properties
            var items_copy: [TargetPlace] = []

            for target_place in this.targetPlaces
            {
                let new_item = target_place
            
                //update address data
                if let adress_text = addressGeocoder.addressText(locationKey: new_item.locationKey)
                {
                    new_item.setAddressText(adress_text)
                }
                
                //update routing data
                if let info_item = routingTravelTime.infoItem(locationKey: new_item.locationKey)
                {
                    if let distance = info_item.routedDistance
                    {
                        new_item.setRoutedDistance(distance)
                    }
                    if let travel_time = info_item.routedTravelTime
                    {
                        new_item.setRoutedTravelTime(travel_time)
                    }
                }

                items_copy.append(new_item)
            }
            
            //sort by distance
            if sorted
            {
                items_copy.sort
                {
                    $0.distance < $1.distance
                }
            }
            
            //assign result
            this.targetPlaces = items_copy

            result = items_copy
        }

        return result
    }
    
    static func filter(targetPlaces: [TargetPlace], forSpanSize: GeoSpan.Size) -> [TargetPlace]
    {
        var result: [TargetPlace] = []
        
        for target_place in targetPlaces
        {
            if target_place.spanSize == forSpanSize
            {
                result.append(target_place)
            }
        }
        
        return result
    }

    struct SpanTargetPlaces
    {
        let size: GeoSpan.Size
        let items: [TargetPlace]

        var center: CLLocationCoordinate2D
        {
            return GeoTools.centerPoint(targetPlaces: items)
        }
        
        var centerLocation: CLLocation
        {
            return CLLocation(latitude: center.latitude, longitude: center.longitude)
        }
    }

    //groups TargetPlace items by fixed GeoSpan.Size - distance of POI from source location
    static func span(targetPlaces: [TargetPlace], minCount: Int) -> [SpanTargetPlaces]
    {
        var span_items: [SpanTargetPlaces] = []
        
        for span_size in GeoSpan.Size.allCases.reversed()
        {
            let target_places = TargetPlaces.filter(targetPlaces: targetPlaces, forSpanSize: span_size)
            span_items.append(SpanTargetPlaces(size: span_size, items: target_places))
        }
        
        var span_items_filtered = span_items.filter
        {
            $0.items.count >= minCount
        }

        span_items_filtered.sort
        {
            $0.items.count < $1.items.count
        }

        return span_items_filtered
    }
}
