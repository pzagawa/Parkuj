//
//  CarPlayUI.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 16/11/2020.
//

import Foundation
import CarPlay
import os

class CarPlayUI
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "CarPlayUI")

    static let MAX_LIST_ITEMS_COUNT = CPListTemplate.maximumItemCount
    static let MAX_TAB_ITEMS_COUNT = CPTabBarTemplate.maximumTabCount
    
    enum ListType
    {
        case Recent; case Favorites;
    }
  
    typealias NavigateActionCallback = (TargetPlace) -> Void

    private weak var carPlayApp: CarPlayApp?
    
    private var viewPointOfInterest: CPPointOfInterestTemplate?
    private var viewListItemsRecent: CPListTemplate?
    private var viewListItemsFavorites: CPListTemplate?
    
    var navigateActionCallback: NavigateActionCallback?

    init()
    {
        logger.info("CarPlayUI initialization")
        logger.info("- max list items: \(CarPlayUI.MAX_LIST_ITEMS_COUNT).")
        logger.info("- max tab items: \(CarPlayUI.MAX_TAB_ITEMS_COUNT).")
    }
    
    func initialize(carPlayApp: CarPlayApp)
    {
        logger.info("Initializing..")
        
        self.carPlayApp = carPlayApp
    }

    func uninitialize()
    {
        logger.info("Uninitializing..")
        
        if let view = self.viewPointOfInterest
        {
            view.pointOfInterestDelegate = nil
        }
    }

    var selectedIndexPOIsItem: Int
    {
        if let view = self.viewPointOfInterest
        {
            return view.selectedIndex
        }

        return NSNotFound
    }

    public func updateViewPointOfInterest(targetPlaces: [TargetPlace], selectedIndex: Int)
    {
        DispatchQueue.main.async
        {
            [weak self] in
            
            guard let this = self else
            {
                return
            }
            
            guard let view = this.viewPointOfInterest else
            {
                return
            }

            let poi_items = this.pointOfInterestItems(targetPlaces: targetPlaces)
                        
            view.setPointsOfInterest(poi_items, selectedIndex: selectedIndex)
        }
    }

    private func targetPlaceToPOI(targetPlace: TargetPlace) -> CPPointOfInterest
    {
        let map_item = targetPlace.mapItem

        let item = CPPointOfInterest(location: map_item, title: targetPlace.title, subtitle: targetPlace.subtitle, summary: nil, detailTitle: nil, detailSubtitle: nil, detailSummary: nil, pinImage: nil)
        
        item.summary = targetPlace.summary
        
        item.detailTitle = targetPlace.title
        item.detailSubtitle = targetPlace.subtitle
        item.detailSummary = targetPlace.summary
        item.pinImage = nil
        item.userInfo = targetPlace
        
        item.primaryButton = CPTextButton(title: "Droga", textStyle: CPTextButtonStyle.confirm)
        {
            [weak self] (button: CPTextButton) in
            
            if let callback = self?.navigateActionCallback
            {
                callback(targetPlace)
            }
        }
        
        return item;
    }

    private func pointOfInterestItems(targetPlaces: [TargetPlace]) -> [CPPointOfInterest]
    {
        var poi_items: [CPPointOfInterest] = []
            
        for target_place in targetPlaces
        {
            let poi_item = targetPlaceToPOI(targetPlace: target_place)
            poi_items.append(poi_item)
        }

        return poi_items
    }

    func createViewPointOfInterest() -> CPTemplate
    {
        let poi_items: [CPPointOfInterest] = []
        
        self.viewPointOfInterest = CPPointOfInterestTemplate(title: "Wybierz", pointsOfInterest: poi_items, selectedIndex: NSNotFound)
        
        if let view = self.viewPointOfInterest
        {
            view.pointOfInterestDelegate = self.carPlayApp
            view.tabSystemItem = .featured
            view.tabTitle = "W pobliżu"
            view.tabImage = UIImage(systemName: "map.fill")
            view.showsTabBadge = false
        }

        return self.viewPointOfInterest!
    }

    func listItems(listType: ListType, targetPlaces: [TargetPlace]) -> [CPListItem]
    {
        var list_items: [CPListItem] = []
        
        for target_place in targetPlaces
        {
            let list_item = CPListItem(text: target_place.title, detailText: target_place.subtitle)
            list_item.userInfo = target_place
            
            list_item.handler =
            {
                [weak self] (list_item: CPSelectableListItem, completion: @escaping () -> Void) in

                let target_place = list_item.userInfo as! TargetPlace
                
                self?.logger.debug("- list item: \(target_place)")

                completion()
            }

            list_items.append(list_item)
        }

        return list_items
    }

    func createViewListItemsRecent(targetPlaces: [TargetPlace]) -> CPTemplate
    {
        ///TEST PLACES
        let list_items = listItems(listType: ListType.Recent, targetPlaces: targetPlaces)

        let item_section_1 = CPListSection(items: list_items)

        self.viewListItemsRecent = CPListTemplate(title: "Ostatnie", sections: [item_section_1])
        
        if let view = self.viewListItemsRecent
        {
            view.emptyViewTitleVariants = ["Nie znaleziono parkingów", "Brak parkingów"]
            view.tabSystemItem = .recents
            view.tabTitle = "Ostatnie"
            view.tabImage = UIImage(systemName: "clock.fill")
            view.showsTabBadge = false
        }

        return self.viewListItemsRecent!
    }

    func createViewListItemsFavorites(targetPlaces: [TargetPlace]) -> CPTemplate
    {
        ///TEST PLACES
        let list_items = listItems(listType: ListType.Favorites, targetPlaces: targetPlaces)

        let item_section_1 = CPListSection(items: list_items)

        self.viewListItemsFavorites = CPListTemplate(title: "Ulubione", sections: [item_section_1])
        
        if let view = self.viewListItemsFavorites
        {
            view.emptyViewTitleVariants = ["Nie znaleziono parkingów", "Brak parkingów"]
            view.tabSystemItem = .favorites
            view.tabTitle = "Ulubione"
            view.tabImage = UIImage(systemName: "star.fill")
            view.showsTabBadge = false
        }

        return self.viewListItemsFavorites!
    }

    func createSearchPanel() -> CPTemplate
    {
        ///TEST PLACES
        let list_items = listItems(listType: ListType.Favorites, targetPlaces: [])

        let item_section_1 = CPListSection(items: list_items)

        self.viewListItemsFavorites = CPListTemplate(title: "Szukaj", sections: [item_section_1])
        
        if let view = self.viewListItemsFavorites
        {
            view.emptyViewTitleVariants = ["Nie znaleziono parkingów", "Brak parkingów"]
            view.tabSystemItem = .search
            view.tabTitle = "Szukaj"
            view.tabImage = UIImage(systemName: "magnifyingglass.circle.fill")
            view.showsTabBadge = false
        }

        return self.viewListItemsFavorites!
    }
}
