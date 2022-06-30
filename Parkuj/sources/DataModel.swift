//
//  DataModel.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 14/10/2020.
//

import Foundation
import CoreLocation
import os

class DataModel
{
    static let instance = DataModel()

    typealias InitCompleted = () -> Void

    private let logger = Logger(subsystem: App.BUNDLE_ID, category: "DataModel")

    private let serialQueue = DispatchQueue(label: "parkuj.serial.queue")
    private let embeddedDatabase = MobileDatabase()

    private var databaseOpened: Bool = false
    private var versionItems: [VersionItem] = []
    
    private var placeItems: [PlaceItem] = []
    private var targetPlaces: [TargetPlace] = []

    private init()
    {
    }

    func initialize(callback: @escaping InitCompleted)
    {
        if embeddedDatabase.openEmbeddedDatabase() == false
        {
            return
        }
        
        databaseOpened = true
     
        logger.info("Initializing..")

        DispatchQueue.global().async
        {
            [weak self] in
     
            self?.serialQueue.sync
            {
                self?.loadVersionItems()
                self?.loadPlaceItems()

                DispatchQueue.main.async
                {
                    callback()
                }
                
                self?.logger.info("Initialization completed.")
            }
        }
    }

    private func loadVersionItems()
    {
        self.versionItems = embeddedDatabase.getAllVersionItems()
        
        logger.info("Version items: \(self.versionItems.count).")
        
        for item in versionItems
        {
            logger.info("* \(item)")
        }
    }

    private func loadPlaceItems()
    {
        self.placeItems = embeddedDatabase.getAllPlaceItems()

        logger.info("Place items: \(self.placeItems.count).")
    }
    
    private func filterPlacesToRegion(location: CLLocation)
    {
        let REGION_KILOMETERS = 30
        
        let bb: BoundingBox = BoundingBox(kiloMeters: REGION_KILOMETERS)

        bb.setLocation(location: location.coordinate)

        self.serialQueue.sync
        {
            [weak self] in

            if let this = self
            {
                this.targetPlaces.removeAll()
                
                for place_item in placeItems
                {
                    if bb.isInside(place_item: place_item)
                    {
                        let target_place = TargetPlace(location: location, placeItem: place_item)
                        this.targetPlaces.append(target_place)
                    }
                }
            }
        }
    }
    
    func targetPlaces(location: CLLocation, limitedTo: Int) -> [TargetPlace]
    {
        filterPlacesToRegion(location: location)
 
        self.targetPlaces.sort
        {
            $0.distance < $1.distance
        }

        let slice = self.targetPlaces.prefix(limitedTo)

        return Array<TargetPlace>(slice)
    }
}
