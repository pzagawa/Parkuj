//
//  CarPlaySceneDelegate.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 11/10/2020.
//

import Foundation
import CarPlay
import os

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate
{
    private let logger = Logger(subsystem: App.BUNDLE_ID, category: "CarPlaySceneDelegate")

    var interfaceControllers: Set<CPInterfaceController?> = []
    //var interfaceController: CPInterfaceController?

    // CarPlay connected
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController)
    {
        logger.debug("Template app scene connect: \(interfaceController)")

        self.interfaceControllers.insert(interfaceController)


        let max_list_items_count = CPListTemplate.maximumItemCount


        let location = CLLocation(latitude: 51, longitude: 17)


        ////POI TEMPLATE
        let target_places = DataModel.instance.targetPlaces(location: location, limitedTo: max_list_items_count)
        
        var poi_items: [CPPointOfInterest] = []
        
        for target_place in target_places
        {
            let map_item = target_place.mapItem
            let tag_text = target_place.tagText

            let poi_item = CPPointOfInterest(location: map_item, title: tag_text.title, subtitle: tag_text.subTitle, summary: nil, detailTitle: nil, detailSubtitle: nil, detailSummary: nil, pinImage: nil)
            
            poi_items.append(poi_item)
        }

        let poi_template = CPPointOfInterestTemplate(title: "Parkingi", pointsOfInterest: poi_items, selectedIndex: NSNotFound)
        
        
        ///LIST TEMPLATE
        logger.debug("max list items count: \(max_list_items_count)")
        
        let list_item_1 = CPListItem(text: "Text", detailText: "detail")
        
                
        //list_item_1.handler
//        {
//            (list_item: CPSelectableListItem, @escaping () -> Void) -> Void)
//
//        }


        let list_item_2 = CPListItem(text: "Text", detailText: "detail")
        let list_item_3 = CPListItem(text: "Text", detailText: "detail")
        let item_section_1 = CPListSection(items: [list_item_1, list_item_2, list_item_3])

        let list_item_11 = CPListItem(text: "Text", detailText: "detail")
        let list_item_12 = CPListItem(text: "Text", detailText: "detail")
        let list_item_13 = CPListItem(text: "Text", detailText: "detail")
        let item_section_2 = CPListSection(items: [list_item_11, list_item_12, list_item_13])
        
    
        let list_template = CPListTemplate(title: "Lista3", sections: [item_section_1, item_section_2])
        list_template.tabTitle = "Lista1"

        //tab bar template
        let max_tab_bar_count = CPTabBarTemplate.maximumTabCount

        logger.debug("max tab bar count: \(max_tab_bar_count)")
        
        let tab_bar = CPTabBarTemplate(templates: [poi_template, list_template])



        
        interfaceController.setRootTemplate(tab_bar, animated: true)
        {
            (success: Bool, error: Error?) in

        }
        
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController)
    {
        logger.debug("Template app scene disconnect: \(interfaceController)")
        
        self.interfaceControllers.remove(interfaceController)
    }
    
    // CarPlay disconnected
//    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController)
//    {
//        self.interfaceController = nil
//    }

}
