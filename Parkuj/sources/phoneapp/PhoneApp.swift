//
//  PhoneApp.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 01/11/2020.
//

import Foundation
import MapKit
import os

// #MARK: PhoneApp class

class PhoneApp: ObservableObject
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "PhoneApp")
 
    private static let RANGE_KILOMETERS = 10

    @Published var updatingMode: LocationManager.UpdatingMode = LocationManager.UpdatingMode.Disabled
    @Published var servicesState: LocationManager.ServicesState = LocationManager.ServicesState.NotDetermined
    @Published var authorizationStatus: LocationManager.AuthorizationStatus = LocationManager.AuthorizationStatus.NotDetermined
    @Published var fullAccuracy: Bool = false
    
    @Published var coordinateRegion: MKCoordinateRegion = GeoDefaults.initRegion
    @Published var selectedTargetPlace: TargetPlace?

    private var targetPlaces = TargetPlaces()
    private var itemsData = PhoneAppItemsData()
    private var itemsDataHashValue: Int = 0

    private let updateExtDataTimer = DelayTimer(timeInterval: .milliseconds(500))
    struct ExtDataParam { let targetPlace: TargetPlace }

    init()
    {
        targetPlaces.setMaxItems(limitedTop: 50)
        
        //callback for starting ext data update after delay
        updateExtDataTimer.callback =
        {
            [weak self] (userData: Any?) in

            guard let this = self else
            {
                return
            }
            
            let param: ExtDataParam = userData as! ExtDataParam

            //update extended target place data
            let location = param.targetPlace.sourceLocation
            let targetPlace = param.targetPlace

            this.targetPlaces.updateExtendedData(location: location, targetPlaces: [targetPlace], requestExtendedData: TargetPlaces.RequestExtendedData.All)
        }
        
        //callback for address/routing data update
        targetPlaces.extendedDataUpdateCallback =
        {
            [weak self] in

            guard let this = self else
            {
                return
            }

            //do not sort to avoid change order when route distance updates
            if this.updateTargetPlaces(sorted: false)
            {
                this.objectWillChange.send()
            }
        }
    }

    public func uninitialize()
    {
        logger.info("Uninitializing..")

        LocationManager.instance.updatingMode.remove(parent: self)
        LocationManager.instance.servicesState.remove(parent: self)
        LocationManager.instance.authorizationStatus.remove(parent: self)
        LocationManager.instance.fullAccuracy.remove(parent: self)
        LocationManager.instance.userAuthorization.remove(parent: self)
        LocationManager.instance.incomingLocation.remove(parent: self)
    }

    public func initialize()
    {
        logger.info("Initializing..")
        
        //add callbacks
        LocationManager.instance.updatingMode.add(parent: self)
        {
            [weak self] (value: LocationManager.UpdatingMode) in
            self?.updatingMode = value
        }

        LocationManager.instance.servicesState.add(parent: self)
        {
            [weak self] (value: LocationManager.ServicesState) in
            self?.servicesState = value
            
            if (value == .NotDetermined)
            {
                self?.logger.warning("[UI] Ask user to enable location services (not set)")
            }

            if (value == .Disabled)
            {
                self?.logger.warning("[UI] Ask user to enable location services (disabled)")
            }
        }
        
        LocationManager.instance.authorizationStatus.add(parent: self)
        {
            [weak self] (value: LocationManager.AuthorizationStatus) in
            self?.authorizationStatus = value
        }

        LocationManager.instance.fullAccuracy.add(parent: self)
        {
            [weak self] (value: Bool) in
            self?.fullAccuracy = value
        }

        LocationManager.instance.userAuthorization.add(parent: self)
        {
            [weak self] (value: LocationManager.AuthorizationStatus) in
            
            if (value == .NotDetermined)
            {
                self?.logger.warning("[UI] Ask user to authorize location sharing")
            }

            if (value == .Denied)
            {
                self?.logger.warning("[UI] Ask user to allow location sharing")
            }
        }

        LocationManager.instance.incomingLocation.add(parent: self)
        {
            [weak self] (value: CLLocation) in
            
            guard let this = self else
            {
                return
            }

            DispatchQueue.main.async
            {
                this.onIncomingLocation(location: value)
            }
        }

        //notify observers
        LocationManager.instance.updatingMode.notify()
        LocationManager.instance.servicesState.notify()
        LocationManager.instance.authorizationStatus.notify()
        LocationManager.instance.fullAccuracy.notify()
        LocationManager.instance.userAuthorization.notify()
        LocationManager.instance.incomingLocation.notify()
    }

    private func regionSpanByAccuracy(location: CLLocation) -> MKCoordinateSpan
    {
        //calculate region span by accuracy
        var span = GeoSpan.coordinate(size: GeoSpan.Size.Km_50)
        
        if fullAccuracy
        {
            span = GeoSpan.coordinate(size: GeoSpan.Size.Km_10)
        }
        
        if (location.horizontalAccuracy < 2000)
        {
            span = GeoSpan.coordinate(size: GeoSpan.Size.Km_1)
        }

        if (location.horizontalAccuracy < 1000)
        {
            span = GeoSpan.coordinate(size: GeoSpan.Size.Meters_500)
        }

        if (location.horizontalAccuracy < 500)
        {
            span = GeoSpan.coordinate(size: GeoSpan.Size.Meters_400)
        }

        if (location.horizontalAccuracy < 300)
        {
            span = GeoSpan.coordinate(size: GeoSpan.Size.Meters_200)
        }

        return span
    }

    // #MARK: Update on incoming location

    private func onIncomingLocation(location: CLLocation)
    {
        if searchTargetPlaces(location: location)
        {
            selectFirstItem()

            updateCoordinateRegion(location: location)
        }
    }

    private func selectFirstItem()
    {
        if isEmpty == false
        {
            if let selected_item = selectedTargetPlace
            {
                if let first_item = itemsData.itemByIndex(itemIndex: 0)
                {
                    if selected_item.id == first_item.id
                    {
                        logger.notice("selectFirstItem: already selected: \(selected_item.id)")
                        return
                    }
                }
            }

            logger.notice("selectFirstItem: selecting..")
            
            selectItemByIndex(itemIndex: 0)
        }
    }

    private func searchTargetPlaces(location: CLLocation) -> Bool
    {
        if servicesState == .Enabled
        {
            if authorizationStatus == .Authorized
            {
                if location.isValid
                {
                    //check location change
                    if targetPlaces.sourceLocationChanged(sourceLocation: location)
                    {
                        //filter target places for source location..
                        let range = PhoneApp.RANGE_KILOMETERS

                        //search target places
                        targetPlaces.search(location: location, rangeKilometers: range, requestExtendedData: TargetPlaces.RequestExtendedData.None)

                        //full update data collection with sort
                        if updateTargetPlaces(sorted: true)
                        {
                            //reset target place selection
                            selectedTargetPlace = nil
                            return true
                        }

                        ///SKIPPING, no dataset change
                        return false
                    }
                    else
                    {
                        ///SKIPPING, no location change, coordinate region change
                        logger.notice("searchTargetPlaces: skipping, no source location change")
                        return false
                    }
                }
            }
        }
        
        resetCoordinateRegion()
        return false
    }

    private func updateTargetPlaces(sorted: Bool) -> Bool
    {
        let target_places = targetPlaces.itemsData(sorted: sorted)

        //check dataset change
        if target_places.hashValue != itemsDataHashValue
        {
            //store last hash value
            itemsDataHashValue = target_places.hashValue

            //update published items
            itemsData.set(targetPlaces: target_places)
        
            //dataset changed
            logger.debug("updateTargetPlaces: dataset CHANGED: \(target_places.count). \(self.itemsDataHashValue)")
            return true
        }

        //no dataset change
        logger.debug("updateTargetPlaces: skipping, no dataset change: \(target_places.count). \(self.itemsDataHashValue)")
        return false
    }

    // #MARK: Update Coordinate Region

    private func resetCoordinateRegion()
    {
        ///SET REGION to DEFAULT
        self.coordinateRegion = GeoDefaults.initRegion
    }

    private func updateCoordinateRegion(location: CLLocation)
    {
        //default region span by accuracy
        var region_span: MKCoordinateSpan = regionSpanByAccuracy(location: location)

        //update coordinate region
        var source_location: CLLocation = location

        if let selected_target_place = selectedTargetPlace
        {
            source_location = selected_target_place.location
        }
        else
        {
            //get span items by size with places count for each span
            let span_items = itemsData.spanItems

            //get top found target places span
            if let top_span_item = span_items.first
            {
                if (top_span_item.items.isEmpty == false)
                {
                    source_location = top_span_item.centerLocation

                    region_span = GeoSpan.coordinate(size: top_span_item.size)
                }
            }
        }

        ///SET REGION to PLACES SPAN SIZE
        self.coordinateRegion = MKCoordinateRegion(center: source_location.coordinate, span: region_span)
    }
    
    func selectItemByIndex(itemIndex: Int)
    {
        if let item = itemsData.itemByIndex(itemIndex: itemIndex)
        {
            selectedTargetPlace = item

            logger.notice("selectItemByIndex: \(itemIndex), item: \(item).")
            
            //update extended data with timer delay
            let userData: ExtDataParam = ExtDataParam(targetPlace: item)

            updateExtDataTimer.execute(userData: userData)
        }
        else
        {
            selectedTargetPlace = nil

            logger.notice("selectItemByIndex: \(itemIndex), item is null.")
        }
        
        if let location = LocationManager.instance.lastLocation
        {
            updateCoordinateRegion(location: location)
        }
        else
        {
            logger.warning("selectItemByIndex: no location")
        }
    }
    
    var itemsCopy: [TargetPlace]
    {
        return itemsData.itemsCopy
    }
    
    var isEmpty: Bool
    {
        return itemsData.isEmpty
    }
    
    var itemsCount: Int
    {
        return itemsData.itemsCount
    }
    
    func itemByIndex(itemIndex: Int) -> TargetPlace?
    {
        return itemsData.itemByIndex(itemIndex: itemIndex)
    }
}
