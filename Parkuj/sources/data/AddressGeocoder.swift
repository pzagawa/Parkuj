//
//  AddressGeocoder.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 28/11/2020.
//

import Foundation
import CoreLocation
import MapKit
import SQLite
import os

class AddressGeocoder
{
    typealias ProcessUpdate = (AddressPlacemark) -> Void

    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "AddressGeocoder")
    
    var processUpdateCallback: ProcessUpdate?

    func addressText(locationKey: String) -> String?
    {
        if let placemark = UserDataModel.instance.addressPlacemark(location_key: locationKey)
        {
            return placemark.addressText
        }
        
        return nil
    }

    private func itemExist(locationKey: String) -> Bool
    {
        if UserDataModel.instance.addressPlacemark(location_key: locationKey) != nil
        {
            return true
        }

        return false
    }

    private struct Task
    {
        private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "AddressGeocoder.Task")

        let location: CLLocation
        
        init(location: CLLocation)
        {
            self.location = location
        }
        
        var locationKey: String
        {
            return GeoTools.locationKey(location: self.location)
        }
        
        func process(completion: @escaping (AddressPlacemark) -> Void)
        {
            let location_key = self.locationKey

            let geocoder = CLGeocoder()

            geocoder.reverseGeocodeLocation(location)
            {
                (placemarks, error) in
                
                var placemark = AddressPlacemark()

                if let e = error
                {
                    placemark = AddressPlacemark(error: e)
                }
                else
                {
                    if let data_items = placemarks
                    {
                        if let data_item = data_items.first
                        {
                            placemark = AddressPlacemark(locationKey: location_key, value: data_item)
                        }
                    }
                }

                completion(placemark)
            }
        }
    }

    private func processItem(targetPlace: TargetPlace)
    {
        if targetPlace.isAddressText
        {
            return
        }

        if self.itemExist(locationKey: targetPlace.locationKey)
        {
            return
        }

        //get from geocoding server
        let task = Task(location: targetPlace.location)
        
        task.process
        {
            [weak self] (placemark: AddressPlacemark) in
            
            guard let this = self else
            {
                return
            }

            if placemark.errorType == .None
            {
                UserDataModel.instance.insertAddressPlacemark(placemark: placemark)

                if let callback = this.processUpdateCallback
                {
                    callback(placemark)
                }
            }

            if placemark.errorType == .Retry
            {
                //try again after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5)
                {
                    [weak self] in

                    self?.processItem(targetPlace: targetPlace)
                }
            }

            if placemark.errorType == .Unknown
            {
                this.logger.error("- item \(placemark.locationKey) error UNKNOWN: \(placemark.errorText)")
            }
        }
    }

    func process(targetPlaces: [TargetPlace])
    {
        if targetPlaces.isEmpty
        {
            return
        }

        logger.info("Processing places: \(targetPlaces.count).")

        for target_place in targetPlaces
        {
            processItem(targetPlace: target_place)
        }
    }
}
