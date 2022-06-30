//
//  CarPlayApp.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 05/12/2020.
//

import Foundation
import CarPlay
import os

class CarPlayApp: NSObject, CPPointOfInterestTemplateDelegate
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "CarPlayApp")

    private static let RANGE_KILOMETERS = 10
  
    enum ListType
    {
        case Recent; case Favorites;
    }
    
    enum UpdatePOIsOn: String
    {
        case IncomingLocation; case ExtendedData; case MapViewChange
    }
  
    private var scene: CPTemplateApplicationScene?
    
    private var ui: CarPlayUI = CarPlayUI()
    private var viewTabBar: CPTabBarTemplate?
    
    private var targetPlaces = TargetPlaces()
    private let updatePOIsDelayTimer = DelayTimer(timeInterval: .milliseconds(100))
    
    private var itemsDataHashValue: Int = 0

    override init()
    {
        logger.info("CarPlayApp initialization")
        
        targetPlaces.setMaxItems(limitedTop: CarPlayUI.MAX_LIST_ITEMS_COUNT)
    }
    
    func initialize(scene: CPTemplateApplicationScene)
    {
        logger.info("Initializing..")
        
        self.scene = scene

        self.ui.initialize(carPlayApp: self)

        //UI navigate action callback
        self.ui.navigateActionCallback =
        {
            [weak self] (targetPlace: TargetPlace) in

            guard let this = self else
            {
                return
            }

            let navigator = Navigator()

            if navigator.openMap(scene: scene, targetPlace: targetPlace)
            {
                this.logger.debug("opened map for navigation to: \(targetPlace).")
            }
            else
            {
                this.logger.error("failed to open map for navigation to: \(targetPlace).")
            }
        }

        //update POIs delay timer
        updatePOIsDelayTimer.callback =
        {
            [weak self] (userData: Any?) in

            let updatePOIsOn: UpdatePOIsOn = userData as! UpdatePOIsOn

            self?.updateViewPointOfInterestInternal(updatePOIsOn: updatePOIsOn)
        }

        //callback for address/routing data update
        targetPlaces.extendedDataUpdateCallback =
        {
            [weak self] in

            self?.updateViewPointOfInterest(updatePOIsOn: UpdatePOIsOn.ExtendedData)
        }

        //observe location change
        LocationManager.instance.incomingLocation.add(parent: self)
        {
            [weak self] (value: CLLocation) in
            
            guard let this = self else
            {
                return
            }

            if LocationManager.instance.isUpdating
            {
                this.logger.debug("- new location: \(value)")
            
                if this.searchTargetPlaces(location: value)
                {
                    this.updateViewPointOfInterest(updatePOIsOn: UpdatePOIsOn.IncomingLocation)
                }
            }
        }
    }

    func uninitialize()
    {
        logger.info("Uninitializing..")

        LocationManager.instance.incomingLocation.remove(parent: self)
        
        self.ui.uninitialize()
        
        self.scene = nil
    }

    var appScene: CPTemplateApplicationScene?
    {
        return self.scene
    }
    
    private func updateViewPointOfInterest(updatePOIsOn: UpdatePOIsOn)
    {
        let userData: Any? = updatePOIsOn
        
        self.updatePOIsDelayTimer.execute(userData: userData)
    }

    private func updateViewPointOfInterestInternal(updatePOIsOn: UpdatePOIsOn)
    {
        //get updated/sorted target places collection
        let target_places = self.targetPlaces.itemsData(sorted: true)

        logger.notice("updateViewPointOfInterestInternal: \(updatePOIsOn.rawValue), items: \(target_places.count).")
        
        //check dataset change
        if target_places.hashValue != itemsDataHashValue
        {
            //store last hash value
            itemsDataHashValue = target_places.hashValue
            
            //update items
            let new_item_index: Int = NSNotFound

            self.ui.updateViewPointOfInterest(targetPlaces: target_places, selectedIndex: new_item_index)
            return
        }
        
        ///SKIPPING, no dataset change
        logger.notice("* skipping, no dataset change: \(self.itemsDataHashValue)")
    }

    private func searchTargetPlaces(location: CLLocation) -> Bool
    {
        logger.notice("searchTargetPlaces: in location: \(location).")
        
        if location.isValid
        {
            //check location change
            if targetPlaces.sourceLocationChanged(sourceLocation: location)
            {
                //filter target places for source location..
                let range = CarPlayApp.RANGE_KILOMETERS

                targetPlaces.search(location: location, rangeKilometers: range, requestExtendedData: TargetPlaces.RequestExtendedData.All)
                return true
            }
            else
            {
                ///SKIPPING, no location change, coordinate region change
                logger.notice("searchTargetPlaces: skipping, no source location change")
                return false
            }
        }

        return false
    }

    func createTabBarView() -> CPTemplate
    {
        let target_places = self.targetPlaces.itemsData(sorted: true)

        var tab_list: [CPTemplate] = []
        
        ///TABS
        //W pobliżu
        //Ostatnie
        //Ulubione
        //Szukaj

        tab_list.append(ui.createViewPointOfInterest())
        tab_list.append(ui.createViewListItemsRecent(targetPlaces: target_places))
        tab_list.append(ui.createViewListItemsFavorites(targetPlaces: target_places))
        //tab_list.append(ui.createSearchPanel())

        self.viewTabBar = CPTabBarTemplate(templates: tab_list)

        //if let view = self.viewTabBar
        //{
        //}

        return self.viewTabBar!
    }
            
    //CPPointOfInterestTemplateDelegate: user has changed the map region, update POIs
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion)
    {
        let search_location = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        
        let center_text = GeoTools.toString(search_location)
        let size_meters = GeoTools.regionSizeInMeters(region: region)

        logger.debug("POI: didChangeMapRegion: \(center_text), region size meters: \(size_meters).")
        
        if LocationManager.instance.updatingMode.value == .Once
        {
            logger.debug("- skipping, location manager in progress..")
            return
        }
        
        //searchTargetPlaces(location: search_location)

        //updateViewPointOfInterest(updatePOIsOn: UpdatePOIsOn.MapViewChange)
    }
    
    //CPPointOfInterestTemplateDelegate: user has selected POI
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didSelectPointOfInterest pointOfInterest: CPPointOfInterest)
    {
        logger.debug("POI: didSelectPointOfInterest: \(pointOfInterest.debugDescription).")
        
    }
}
