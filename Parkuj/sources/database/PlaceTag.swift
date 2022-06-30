//
//  PlaceTag.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 05/10/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
        
// #MARK: PlaceTag
// Raw value is text code of tag item
enum PlaceTag: String
{
    case Parking
    
    //typ
    case MOP
    case TIR
    case ParkAndRide

    //stacje paliw
    case FuelStation
    case OrlenStation
    case BPStation
    case LotosStation
    case ShellStation
    case StatoilStation
    case MoyaStation
    case LukoilStation

    //usługi
    case Lodging
    case Lunch

    //miejsce
    case Forest
    case Lake
    case Camping
    
    case Church
    case Cemetery
    
    case AirPort
    case TrainStation
    case Hospital
    
    case Housing
    case Square
    case Market
    
    case Museum
    case Castle
    case Stadium

    //zakupy
    case Store
    case Mall
    case Manufaktura

    case StoreIntermarche
    case StoreCarrefour
    case StoreTesco
    case StoreBiedronka
    case StoreLidl
    case StoreNetto

    case Ikea
    case Castorama
    case Obi
    case MediaMarkt

    //cechy
    case Garage
    
    case Guarded
    case Unguarded
    case Payable
    case FreeOfCharge
}

// #MARK: PlaceTagDefinition
struct PlaceTagDefinition
{
    enum Line
    {
        case Title
        case Subtitle
    }
        
    typealias Data = (id: String, text: String, line: Line, priority: Int)
    
    static let items: [PlaceTag: Data] =
    [
        .Parking:           (id: "a0",  text: "Parking",            line: Line.Title,       priority: 0),
        
        //typ
        .MOP:               (id: "b0",  text: "MOP",                line: Line.Title,       priority: 1),
        .TIR:               (id: "b1",  text: "TIR",                line: Line.Subtitle,    priority: 1),
        .ParkAndRide:       (id: "b2",  text: "Park & Ride",        line: Line.Subtitle,    priority: 2),

        //stacje paliw
        .FuelStation:       (id: "c0",  text: "Stacja Paliw",       line: Line.Title,       priority: 2),
        .OrlenStation:      (id: "c1",  text: "Stacja Orlen",       line: Line.Title,       priority: 2),
        .BPStation:         (id: "c2",  text: "Stacja BP",          line: Line.Title,       priority: 2),
        .LotosStation:      (id: "c3",  text: "Stacja Lotos",       line: Line.Title,       priority: 2),
        .ShellStation:      (id: "c4",  text: "Stacja Shell",       line: Line.Title,       priority: 2),
        .StatoilStation:    (id: "c5",  text: "Stacja Statoil",     line: Line.Title,       priority: 2),
        .MoyaStation:       (id: "c6",  text: "Stacja Moya",        line: Line.Title,       priority: 2),
        .LukoilStation:     (id: "c7",  text: "Stacja Lukoil",      line: Line.Title,       priority: 2),
        
        //usługi
        .Lodging:           (id: "d0",  text: "Nocleg",             line: Line.Subtitle,    priority: 101),
        .Lunch:             (id: "d1",  text: "Obiad",              line: Line.Subtitle,    priority: 100),

        //miejsce
        .Forest:            (id: "e0",  text: "Las",                line: Line.Subtitle,    priority: 10),
        .Lake:              (id: "e1",  text: "Jezioro",            line: Line.Subtitle,    priority: 11),
        .Camping:           (id: "e2",  text: "Kemping",            line: Line.Subtitle,    priority: 12),
        
        .Church:            (id: "f0",  text: "Kościół",            line: Line.Subtitle,    priority: 20),
        .Cemetery:          (id: "f1",  text: "Cmentarz",           line: Line.Subtitle,    priority: 21),
        
        .AirPort:           (id: "g0",  text: "Lotnisko",           line: Line.Subtitle,    priority: 30),
        .TrainStation:      (id: "g1",  text: "Stacja kolejowa",    line: Line.Subtitle,    priority: 31),
        .Hospital:          (id: "g2",  text: "Szpital",            line: Line.Subtitle,    priority: 32),
        
        .Housing:           (id: "h0",  text: "Osiedle",            line: Line.Subtitle,    priority: 40),
        .Square:            (id: "h1",  text: "Plac",               line: Line.Subtitle,    priority: 41),
        .Market:            (id: "h2",  text: "Rynek",              line: Line.Subtitle,    priority: 42),
        
        .Museum:            (id: "i0",  text: "Muzeum",             line: Line.Subtitle,    priority: 50),
        .Castle:            (id: "i1",  text: "Zamek",              line: Line.Subtitle,    priority: 51),
        .Stadium:           (id: "i2",  text: "Stadion",            line: Line.Subtitle,    priority: 52),

        //zakupy
        .Store:             (id: "k0", text: "Sklep",               line: Line.Subtitle,    priority: 3),
        .Mall:              (id: "k1", text: "Centrum Handlowe",    line: Line.Title,       priority: 3),
        .Manufaktura:       (id: "k2", text: "Manufaktura",         line: Line.Title,       priority: 4),
        
        .StoreIntermarche:  (id: "n0", text: "Intermarche",         line: Line.Title,       priority: 5),
        .StoreCarrefour:    (id: "n1", text: "Carrefour",           line: Line.Title,       priority: 5),
        .StoreTesco:        (id: "n2", text: "Tesco",               line: Line.Title,       priority: 5),
        .StoreBiedronka:    (id: "n3", text: "Biedronka",           line: Line.Title,       priority: 5),
        .StoreLidl:         (id: "n4", text: "Lidl",                line: Line.Title,       priority: 5),
        .StoreNetto:        (id: "n5", text: "Netto",               line: Line.Title,       priority: 5),

        .Ikea:              (id: "r0", text: "IKEA",                line: Line.Title,       priority: 8),
        .Castorama:         (id: "r1", text: "Castorama",           line: Line.Title,       priority: 8),
        .Obi:               (id: "r2", text: "OBI",                 line: Line.Title,       priority: 8),
        .MediaMarkt:        (id: "r3", text: "MediaMarkt",          line: Line.Title,       priority: 8),
        
        //cechy
        .Garage:            (id: "s0", text: "Garaż",               line: Line.Subtitle,    priority: 0),

        .Guarded:           (id: "s1", text: "Strzeżony",           line: Line.Subtitle,    priority: 200),
        .Unguarded:         (id: "s2", text: "",                    line: Line.Subtitle,    priority: 200),
        .Payable:           (id: "s3", text: "Płatny",              line: Line.Subtitle,    priority: 201),
        .FreeOfCharge:      (id: "s4", text: "",                    line: Line.Subtitle,    priority: 200),
    ]
    
    static var tagsById: [String: PlaceTag] =
    {
        var tags_by_id = [String: PlaceTag]()
        
        for item in PlaceTagDefinition.items
        {
            tags_by_id[item.value.id] = item.key
        }

        return tags_by_id
    }()
}

// #MARK: PlaceTagText
// Generates displayable text for tags
struct PlaceTagText
{
    private var itemsTitle: [PlaceTagDefinition.Data] = []
    private var itemsSubtitle: [PlaceTagDefinition.Data] = []

    init(place_tags: Set<PlaceTag>)
    {
        //collect data items
        for place_tag in place_tags
        {
            if place_tag == PlaceTag.Parking
            { continue }
            
            if let data = PlaceTagDefinition.items[place_tag]
            {
                if data.text.isEmpty
                { continue }

                if data.line == PlaceTagDefinition.Line.Title
                {
                    self.itemsTitle.append(data)
                }
                if data.line == PlaceTagDefinition.Line.Subtitle
                {
                    self.itemsSubtitle.append(data)
                }
            }
        }

        //if no tags collected, set default
        if self.itemsTitle.isEmpty
        {
            self.itemsTitle.append(PlaceTagDefinition.items[.Parking]!)
        }

        //sort title data items by priority
        self.itemsTitle.sort
        { (data1: PlaceTagDefinition.Data, data2: PlaceTagDefinition.Data) -> Bool in
            return data1.priority < data2.priority
        }

        //sort subtitle data items by priority
        self.itemsSubtitle.sort
        { (data1: PlaceTagDefinition.Data, data2: PlaceTagDefinition.Data) -> Bool in
            return data1.priority < data2.priority
        }
    }
    
    var titleCount: Int
    {
        return itemsTitle.count
    }

    var subTitleCount: Int
    {
        return itemsSubtitle.count
    }

    var title: String
    {
        let text_items = itemsTitle.map { return $0.text }
        let text = text_items.joined(separator: " ")
        return text
    }

    var subTitle: String
    {
        let text_items = itemsSubtitle.map { return $0.text }
        let text = text_items.joined(separator: ", ")
        return text
    }
    
    var value: String
    {
        if (subTitle.isEmpty)
        {
            return "\(title)"
        }
        else
        {
            return "\(title): \(subTitle)"
        }
    }
}

// #MARK: PlaceKey
// Encodes/Decodes tags key string
struct PlaceTagKey: CustomStringConvertible, Equatable
{
    private let KEY_PART_LENGTH = 2
    private var items: [PlaceTagDefinition.Data] = []

    static func split_to_parts(text: String, part_len: Int) -> [String]
    {
        let parts_count: Int = (text.count - 1) / part_len
        
        //split key text to 2 char length parts
        return (0...parts_count).map { String(text.dropFirst($0 * part_len).prefix(part_len)) }
    }

    //decode string key to place tag
    init(key: String)
    {
        let text_parts = PlaceTagKey.split_to_parts(text: key, part_len: KEY_PART_LENGTH)

        //iterate each text part of the key
        for text_part in text_parts
        {
            let place_id = String(text_part)

            if let place_tag = PlaceTagDefinition.tagsById[place_id]
            {
                if let data = PlaceTagDefinition.items[place_tag]
                {
                    self.items.append(data)
                }
            }
        }
        
        //sort data items by id text
        self.items.sort
        { (data1: PlaceTagDefinition.Data, data2: PlaceTagDefinition.Data) -> Bool in
            return data1.id < data2.id
        }
    }

    //decode place tag set
    init(place_tags: Set<PlaceTag>)
    {
        //collect data items
        for place_tag in place_tags
        {
            if let data = PlaceTagDefinition.items[place_tag]
            {
                self.items.append(data)
            }
        }

        //sort data items by id text
        self.items.sort
        { (data1: PlaceTagDefinition.Data, data2: PlaceTagDefinition.Data) -> Bool in
            return data1.id < data2.id
        }
    }
    
    static func ==(lhs: PlaceTagKey, rhs: PlaceTagKey) -> Bool
    {
        if (lhs.toString == rhs.toString)
        {
            return true
        }
    
        return false
    }

    var description: String
    {
        return toPlaceTagsText
    }

    var toString: String
    {
        let text_items = items.map { return $0.id }
        let text = text_items.joined(separator: "")
        return text
    }
    
    var toPlaceTags: Set<PlaceTag>
    {
        var set = Set<PlaceTag>()
        
        for data in items
        {
            let place_id = data.id
            
            if let place_tag = PlaceTagDefinition.tagsById[place_id]
            {
                set.insert(place_tag)
            }
        }
        
        return set
    }
    
    var toPlaceTagsText: String
    {
        let text_items = toPlaceTags.map { return $0.rawValue }
        let text = text_items.joined(separator: ", ")
        return text
    }
    
    var tagsCount: Int
    {
        return items.count
    }
}
