//
//  AddressPlacemark.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 30/11/2020.
//

import Foundation
import CoreLocation
import MapKit
import SQLite
import os

struct AddressPlacemarkFields
{
    let locationKey = Expression<String>("locationKey")
    let name        = Expression<String?>("name")
    let street      = Expression<String?>("street")
    let city        = Expression<String?>("city")
    let town        = Expression<String?>("town")
}

// #MARK: AddressPlacemarkTable
struct AddressPlacemark: CustomStringConvertible, Equatable
{
    static let fields = AddressPlacemarkFields()

    enum ErrorType { case None; case Unknown; case Retry; }

    let locationKey: String
    
    let name: String?
    let street: String? //street name
    let city: String? //city
    let town: String? //neighborhood
    
    let isEmpty: Bool
    let errorType: ErrorType
    let errorText: String

    init()
    {
        self.locationKey = ""

        self.name = nil
        self.street = nil
        self.city = nil
        self.town = nil

        self.isEmpty = true
        self.errorType = .None
        self.errorText = "no error"
    }

    init(error: Error)
    {
        self.locationKey = ""

        self.name = nil
        self.street = nil
        self.city = nil
        self.town = nil

        isEmpty = true

        if let cl_error = error as? CLError
        {
            errorType = (cl_error.code == CLError.Code.network) ? .Retry : .Unknown
            errorText = "retry error"
        }
        else
        {
            errorType = .Unknown
            errorText = error.localizedDescription
        }
    }

    init(locationKey: String, value: CLPlacemark)
    {
        self.locationKey = locationKey
        
        self.name = value.name
        self.street = value.thoroughfare
        self.city = value.locality
        self.town = value.subLocality

        isEmpty = false
        errorType = .None
        errorText = ""
    }
    
    // #MARK: SQLite ROW INIT
    init(row: Row)
    {
        self.locationKey = row[AddressPlacemark.fields.locationKey]
        
        self.name = row[AddressPlacemark.fields.name]
        self.street = row[AddressPlacemark.fields.street]
        self.city = row[AddressPlacemark.fields.city]
        self.town = row[AddressPlacemark.fields.town]

        isEmpty = false
        errorType = .None
        errorText = ""
    }

    var description: String
    {
        return "location: \(self.locationKey). address: \(self.addressText)"
    }

    static private func addValue(items: inout [String], value: String?)
    {
        //stop constructing if more than zero items exist
        if items.isEmpty == false
        {
            return
        }

        if let text = value
        {
            //value must not be empty
            if text.isEmpty == false
            {
                //value must not be a number
                if Int(text) == nil
                {
                    items.append(text)
                }
            }
        }
    }

    var addressText: String
    {
        var items: [String] = []

        //adding in order of importance
        AddressPlacemark.addValue(items: &items, value: self.street)
        AddressPlacemark.addValue(items: &items, value: self.name)
        AddressPlacemark.addValue(items: &items, value: self.city)
        AddressPlacemark.addValue(items: &items, value: self.town)

        return items.joined(separator: ", ")
    }
}

// #MARK: AddressPlacemarkTable
struct AddressPlacemarkTable
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "AddressPlacemarkTable")

    let table = Table("address_placemark")
    
    func createQueryString() -> String
    {
        let query = table.create(temporary: false, ifNotExists: true, withoutRowid: false)
        {
            (t: TableBuilder) in
            
            t.column(AddressPlacemark.fields.locationKey)
            t.column(AddressPlacemark.fields.name)
            t.column(AddressPlacemark.fields.street)
            t.column(AddressPlacemark.fields.city)
            t.column(AddressPlacemark.fields.town)
        }

        return query
    }
    
    func createTable(connection: Connection)
    {
        logger.notice("Creating table: AddressPlacemarkTable.")

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
    
    func insertItem(connection: Connection, item: AddressPlacemark)
    {
        let values: [SQLite.Setter] =
        [
            AddressPlacemark.fields.locationKey <- item.locationKey,
            AddressPlacemark.fields.name        <- item.name,
            AddressPlacemark.fields.street      <- item.street,
            AddressPlacemark.fields.city        <- item.city,
            AddressPlacemark.fields.town        <- item.town,
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

    func selectRow(connection: Connection, location_key: String) -> AddressPlacemark?
    {
        do
        {
            let query = table.filter(AddressPlacemark.fields.locationKey == location_key)
            
            let rows = try connection.prepare(query)

            for row: Row in rows
            {
                return AddressPlacemark(row: row)
            }
        }
        catch let error
        {
            logger.error("Table select row ERROR: \(error.localizedDescription)")
        }
        
        return nil
    }
}
