//
//  PhoneMapView.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 30/01/2021.
//

import SwiftUI
import MapKit

struct PhoneMapView: View
{
    @EnvironmentObject private var appState: PhoneApp

    @State private var userTrackingMode: MapUserTrackingMode = .none

    var body: some View
    {
        VStack()
        {
            //create map view
            Map(coordinateRegion: $appState.coordinateRegion,
                interactionModes: MapInteractionModes.all,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode,
                annotationItems: appState.itemsCopy, annotationContent:
                {
                    targetPlace in
                
                    MapAnnotation(coordinate: targetPlace.coordinate, anchorPoint: CGPoint(x: 0.5, y: 1.0))
                    {
                        Image("map-icon-parking")
                    }
                })

            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct PhoneMapView_Previews: PreviewProvider
{
    static var previews: some View
    {
        PhoneMapView()
    }
}
