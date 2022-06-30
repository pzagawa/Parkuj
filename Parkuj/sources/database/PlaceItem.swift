//
//  PlaceItem.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 07/10/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import CryptoKit
import CoreLocation
import SQLite
import os

struct PlaceItemFields
{
    let id      = Expression<String>("id")
    let lat     = Expression<Double>("lat")
    let lon     = Expression<Double>("lon")
    let tags    = Expression<String>("tags")
}

// #MARK: PlaceItem
struct PlaceItem: CustomStringConvertible, Equatable
{
    static let fields = PlaceItemFields()
    
    enum Source: Int8
    {
        case Database
        case User
    }
    
    let id: String
    let lat: Double
    let lon: Double
    let tags: String
    
    let source: Source

    // #MARK: SQLite ROW INIT
    init(row: Row)
    {
        self.id = row[PlaceItem.fields.id]
        self.lat = row[PlaceItem.fields.lat]
        self.lon = row[PlaceItem.fields.lon]
        self.tags = row[PlaceItem.fields.tags]
        
        self.source = Source.Database
    }

    var description: String
    {
        let tagKey = PlaceTagKey(key: self.tags)
        return "id: \(id). region: \(regionKey). location: \(locationString). tags: [\(tags)]. tags list: [\(tagKey.toPlaceTagsText)]. #\(tagTextValue)"
    }

    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon))
    }

    var location: CLLocation
    {
        return CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon))
    }

    var locationString: String
    {
        return GeoTools.toString(coordinate)
    }

    var locationKey: String
    {
        return String(format: "%.5f:%.5f", lat, lon)
    }

    var regionKey: String
    {
        return String(format: "%.1fx%.1f", coordinate.latitude, coordinate.longitude)
    }
    
    var placeTags: Set<PlaceTag>
    {
        let tagKey = PlaceTagKey(key: self.tags)
        return tagKey.toPlaceTags
    }
    
    var tagTextValue: String
    {
        return PlaceTagText(place_tags: placeTags).value
    }
    
    var tagText: PlaceTagText
    {
        return PlaceTagText(place_tags: placeTags)
    }

    static func ==(lhs: PlaceItem, rhs: PlaceItem) -> Bool
    {
        if (lhs.locationKey == rhs.locationKey)
        {
            if (lhs.tags == rhs.tags)
            {
                return true
            }
        }
    
        return false
    }
}

// #MARK: PlaceTable
struct PlaceTable
{
    private let logger = Logger(subsystem: App.BUNDLE_ID, category: "PlaceTable")

    let table = Table("places")
    
    func createQueryString() -> String
    {
        let query = table.create(temporary: false, ifNotExists: true, withoutRowid: false)
        {
            (t: TableBuilder) in
            
            t.column(PlaceItem.fields.id)
            t.column(PlaceItem.fields.lat)
            t.column(PlaceItem.fields.lon)
            t.column(PlaceItem.fields.tags)
        }

        return query
    }
    
    func createTable(connection: Connection)
    {
        logger.notice("Creating table: PlaceTable.")

        do
        {
            let statement: Statement = try connection.run(createQueryString())
            logger.notice("Table created: \(statement).")
        }
        catch let error
        {
            logger.error("Table creation failed: \(error.localizedDescription)")
        }
    }
    
    func insertItem(connection: Connection, item: PlaceItem)
    {
        let values =
        [
            PlaceItem.fields.id     <- item.id,
            PlaceItem.fields.lat    <- item.lat,
            PlaceItem.fields.lon    <- item.lon,
            PlaceItem.fields.tags   <- item.tags,
        ]

        do
        {
            let query = table.insert(values)
            try connection.run(query)
        }
        catch let error
        {
            logger.error("Row insertion failed: \(error.localizedDescription)")
        }
    }

    func selectAllRows(connection: Connection) -> [PlaceItem]
    {
        var items: [PlaceItem] = []
        
        do
        {
            let rows = try connection.prepare(table)

            for row: Row in rows
            {
                let poi_item = PlaceItem(row: row)
                items.append(poi_item)
            }
        }
        catch let error
        {
            logger.error("Table select all rows ERROR: \(error.localizedDescription)")
        }
        
        return items
    }

    func selectRow(connection: Connection, item_id: String) -> PlaceItem?
    {
        do
        {
            let query = table.filter(PlaceItem.fields.id == item_id)
            
            let rows = try connection.prepare(query)

            for row: Row in rows
            {
                return PlaceItem(row: row)
            }
        }
        catch let error
        {
            logger.error("Table select row ERROR: \(error.localizedDescription)")
        }
        
        return nil
    }

    func deleteRow(connection: Connection, item_id: String) -> Bool
    {
        do
        {
            let query = table.filter(PlaceItem.fields.id == item_id)
            try connection.run(query.delete())
            return true
        }
        catch let error
        {
            logger.error("Delete row failed: \(error.localizedDescription)")
            return false
        }
    }
}
