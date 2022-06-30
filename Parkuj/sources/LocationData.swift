//
//  LocationData.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 09/11/2020.
//

import Foundation
import CoreLocation
import MapKit
import os

class LocationData
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "LocationData")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.LocationData")

#if DEBUG
    //minimum initialization accuracy to accept
    private let MIN_INIT_ACCURACY: CLLocationAccuracy = 80
    //minimum update accuracy to accept
    private let MIN_UPD8_ACCURACY: CLLocationAccuracy = 50
#else
    //minimum initialization accuracy to accept
    private let MIN_INIT_ACCURACY: CLLocationAccuracy = 50
    //minimum update accuracy to accept
    private let MIN_UPD8_ACCURACY: CLLocationAccuracy = 20
#endif
    
    init()
    {
        logger.debug("Location filter accuracy: \(self.MIN_INIT_ACCURACY), for update: \(self.MIN_UPD8_ACCURACY).")
    }
    
    private var locationsItems: [CLLocation] = []

    public func reset()
    {
        self.serialQueue.sync
        {
            [weak self] in

            self?.locationsItems.removeAll()
        }
    }

    public var lastLocation: CLLocation?
    {
        var location: CLLocation?
    
        self.serialQueue.sync
        {
            [weak self] in

            if self?.locationsItems.isEmpty == false
            {
                location = self?.locationsItems.last
            }
        }

        return location
    }
    
    public var lastMapItem: MKMapItem?
    {
        if let location = lastLocation
        {
            let placemark = MKPlacemark(coordinate: location.coordinate)
            let map_item = MKMapItem(placemark: placemark)
            return map_item
        }

        return nil
    }
    
    var lastUpdateSeconds: TimeInterval?
    {
        if let location = lastLocation
        {
            let now = Date()
            return now.timeIntervalSince(location.timestamp)
        }
        
        return nil
    }

    public func update(locations: [CLLocation]) -> Int
    {
        let is_init_update: Bool = locationsItems.isEmpty

        var added_count = 0
        
        for location in locations
        {
            //filter by accuracy
            if is_init_update
            {
                if location.horizontalAccuracy > MIN_INIT_ACCURACY
                {
                    continue
                }
            }
            else
            {
                if location.horizontalAccuracy > MIN_UPD8_ACCURACY
                {
                    continue
                }
            }
            
            //get last location to check distance change
            if let last_location = lastLocation
            {
                let distance_to_last_location = location.distance(from: last_location)

                //check if distance to last location changed significantly
                if distance_to_last_location < MIN_UPD8_ACCURACY
                {
                    //location not changed much
                    continue
                }
                else
                {
                    logger.debug("update: location distance changed a lot: \(distance_to_last_location).")
                }
            }

            //add item
            self.serialQueue.sync
            {
                [weak self] in

                self?.locationsItems.append(location)
            }
            
            added_count += 1
        }
        
        return added_count
    }
}
