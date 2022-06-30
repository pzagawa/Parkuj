//
//  RoutingTravelTime.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 01/12/2020.
//

import Foundation
import CoreLocation
import MapKit
import SQLite
import os

class RoutingTravelTime
{
    typealias ProcessUpdate = (InfoItem) -> Void
    
    private let REROUTE_DISTANCE_TRESHOLD_METERS: CLLocationDistance = 300

    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "RoutingTravelTime")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.RoutingTravelTime")

    private var infoItems: [String: InfoItem] = [:]

    private var lastSourceLocation: CLLocation?

    var processUpdateCallback: ProcessUpdate?

    func infoItem(locationKey: String) -> InfoItem?
    {
        var info_item: InfoItem?
        
        self.serialQueue.sync
        {
            [weak self] in

            info_item = self?.infoItems[locationKey]
        }

        return info_item
    }

    private func itemExist(locationKey: String) -> Bool
    {
        var result: Bool = false
        
        self.serialQueue.sync
        {
            [weak self] in

            result = (self?.infoItems[locationKey] != nil)
        }

        return result
    }
    
    private func addItem(locationKey: String, infoItem: InfoItem)
    {
        self.serialQueue.sync
        {
            [weak self] in

            self?.infoItems[locationKey] = infoItem
        }
    }

    private func removeAll()
    {
        self.serialQueue.sync
        {
            [weak self] in

            self?.infoItems.removeAll()
        }
    }

    struct InfoItem: CustomStringConvertible
    {
        enum ErrorType { case None; case Unknown; case Retry; }

        let locationKey: String
        
        private let sourceLocation: CLLocation
        private let targetPlace: TargetPlace?
        private let response: MKDirections.ETAResponse?
        
        let isEmpty: Bool
        var errorType: ErrorType
        var errorText: String

        init()
        {
            self.locationKey = ""
            self.sourceLocation = CLLocation()
            self.targetPlace = nil
            self.response = nil
            self.isEmpty = true
            self.errorType = .None
            self.errorText = "no error"
        }

        init(error: Error)
        {
            self.locationKey = ""
            self.sourceLocation = CLLocation()
            self.targetPlace = nil
            self.response = nil
            
            isEmpty = true
            errorType = .Unknown
            errorText = error.localizedDescription

            if let mk_error = error as? MKError
            {
                errorType = (mk_error.code == MKError.Code.loadingThrottled) ? .Retry : .Unknown
                errorText = "code: \(mk_error.code.rawValue), \(error.localizedDescription)"
            }

            if let cl_error = error as? CLError
            {
           
                errorType = (cl_error.code == CLError.Code.network) ? .Retry : .Unknown
                errorText = "code: \(cl_error.code.rawValue), \(error.localizedDescription)"
            }
        }

        init(source: CLLocation, target: TargetPlace, value: MKDirections.ETAResponse)
        {
            self.locationKey = GeoTools.locationKey(location: source)
            self.sourceLocation = source
            self.targetPlace = target
            self.response = value
            isEmpty = false
            errorType = .None
            errorText = ""
        }

        var routedDistance: CLLocationDistance?
        {
            if let result = response
            {
                return result.distance
            }
            
            return nil
        }
        
        var routedTravelTime: TimeInterval?
        {
            if let result = response
            {
                return result.expectedTravelTime
            }
            
            return nil
        }
        
        var destinationMapItem: MKMapItem?
        {
            if let result = response
            {
                return result.destination
            }
            
            return nil
        }

        var description: String
        {
            if errorType == .None
            {
                var text = "location: \(self.locationKey). "
            
                if let target = targetPlace
                {
                    text += "target: \(target.title), \(target.locationKey). "
                }
                
                if let distance = routedDistance
                {
                    text += "distance: \(distance). "
                }
                
                if let time = routedTravelTime
                {
                    text += "time: \(time). "
                }
                
                return text
            }
            else
            {
                return "location: \(self.locationKey). error: \(errorText)"
            }
        }
    }

    private struct Task
    {
        private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "RoutingTravelTime.Task")

        let sourceLocation: CLLocation
        let targetPlace: TargetPlace
        
        init(sourceLocation: CLLocation, targetPlace: TargetPlace)
        {
            self.sourceLocation = sourceLocation
            self.targetPlace = targetPlace
        }
        
        var locationKey: String
        {
            return GeoTools.locationKey(location: self.sourceLocation)
        }
        
        var sourceMapItem: MKMapItem
        {
            let placemark = MKPlacemark(coordinate: self.sourceLocation.coordinate)
            let mapitem = MKMapItem(placemark: placemark)
            return mapitem
        }
        
        func process(completion: @escaping (InfoItem) -> Void)
        {
            let request = MKDirections.Request()
            
            request.source = self.sourceMapItem
            request.destination = self.targetPlace.mapItem
            request.transportType = .automobile

            let directions = MKDirections.init(request: request)
            
            directions.calculateETA
            {
                (response: MKDirections.ETAResponse?, error: Error?) in
                
                var info_item = InfoItem()

                if let e = error
                {
                    info_item = InfoItem(error: e)
                }
                else
                {
                    if let value = response
                    {
                        info_item = InfoItem(source: sourceLocation, target: targetPlace, value: value)
                    }
                }
                
                completion(info_item)
            }
        }
    }
    
    private func processItem(sourceLocation: CLLocation, targetPlace: TargetPlace)
    {
        if self.itemExist(locationKey: targetPlace.locationKey)
        {
            return
        }

        //get from geocoding server
        let task = Task(sourceLocation: sourceLocation, targetPlace: targetPlace)
        
        task.process
        {
            [weak self] (info_item: InfoItem) in
            
            guard let this = self else
            {
                return
            }

            if info_item.errorType == .None
            {
                this.addItem(locationKey: targetPlace.locationKey, infoItem: info_item)

                if let callback = this.processUpdateCallback
                {
                    callback(info_item)
                }
            }

            if info_item.errorType == .Retry
            {
                //try again after 6 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 6)
                {
                    [weak self] in

                    self?.processItem(sourceLocation: sourceLocation, targetPlace: targetPlace)
                }
            }

            if info_item.errorType == .Unknown
            {
                this.logger.error("- item \(info_item.locationKey) error: \(info_item.errorText)")
            }
        }
    }

    private func sourceLocationChanged(sourceLocation: CLLocation) -> Bool
    {
        if let last_location = lastSourceLocation
        {
            let distance = last_location.distance(from: sourceLocation)
            
            if (distance > REROUTE_DISTANCE_TRESHOLD_METERS)
            {
                self.lastSourceLocation = sourceLocation
                return true
            }
            else
            {
                return false
            }
        }
        else
        {
            self.lastSourceLocation = sourceLocation
            return true
        }
    }

    func process(sourceLocation: CLLocation, targetPlaces: [TargetPlace])
    {
        if targetPlaces.isEmpty
        {
            return
        }

        logger.info("Processing places: \(targetPlaces.count). Routing items in cache: \(self.infoItems.count).")

        if (sourceLocationChanged(sourceLocation: sourceLocation))
        {
            logger.debug("- location change, removing outdated route data.")
            
            removeAll()
        }

        for target_place in targetPlaces
        {
            processItem(sourceLocation: sourceLocation, targetPlace: target_place)
        }
    }
}
