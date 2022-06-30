//
//  EmbeddedDataModel.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 14/10/2020.
//

import Foundation
import CoreLocation
import os

class EmbeddedDataModel
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "EmbeddedDataModel")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.EmbeddedDataModel")
 
    static let instance = EmbeddedDataModel()

    typealias InitCompleted = () -> Void
    typealias FilterItem = (PlaceItem) -> Void

    private let embeddedDatabase = EmbeddedDatabase()
    
    private var versionItems: [VersionItem] = []
    private var placeItems: [PlaceItem] = []

    private init()
    {
    }

    func initialize(callback: @escaping InitCompleted)
    {
        if embeddedDatabase.openEmbeddedDatabase() == false
        {
            return
        }

        serialQueue.sync
        {
            ///Loading all static tables items
            loadVersionItems()
            loadPlaceItems()

            callback()
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

    func filterPlacesToRegion(searchLocation: CLLocation, range_kilometers: Int, callback: FilterItem)
    {
        let bb: BoundingBox = BoundingBox(kiloMeters: range_kilometers)

        bb.setLocation(location: searchLocation.coordinate)

        self.serialQueue.sync
        {
            [weak self] in

            if let this = self
            {
                for place_item in this.placeItems
                {
                    if bb.isInside(place_item: place_item)
                    {
                        callback(place_item)
                    }
                }
            }
        }
    }
}
