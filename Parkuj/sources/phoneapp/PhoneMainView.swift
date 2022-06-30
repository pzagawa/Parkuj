//
//  PhoneMainView.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 10/10/2020.
//

import SwiftUI
import MapKit

struct PhoneMainView: View
{
    @EnvironmentObject private var appState: PhoneApp

    var isNoData: Bool
    {
        return appState.isEmpty
    }
    
    var headerTitleText: String
    {
        if isNoData
        {
            return ""
        }
        else
        {
            let count = appState.itemsCount
            
            if (count == 1)
            {
                return "1 PARKING W POBLIŻU"
            }
            else
            {
                return "\(count) PARKINGÓW W POBLIŻU"
            }
        }
    }

    var body: some View
    {
        TabView
        {
        
        ///TAB ITEM: MapView
        ZStack()
        {
            PhoneMapView()
            
            VStack
            {
                VStack
                {
                    Text("UPDATING MODE: \(appState.updatingMode.rawValue)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.orange)
                        .padding([.leading, .bottom, .trailing], 4.0)

                    Text("Authorized: \(appState.authorizationStatus.rawValue)")
                    .font(.subheadline)

                    Text("Full accuracy: \(String(describing: appState.fullAccuracy))")
                    .font(.subheadline)
                }

                Spacer()

                //bottom content slider
                VStack(alignment: .center)
                {
                    //centered text
                    HStack
                    {
                        Spacer()
                        Text(headerTitleText)
                        .font(.headline)
                        .bold()
                        .padding(.top, 16)
                        Spacer()
                    }

                    PhonePoiSliderView()
                    .padding(.top, 6)
                    .padding(.bottom, 40)
                    .padding(.leading, PhonePoiBadgeDragData.SCREEN_MARGIN)
                    .padding(.trailing, PhonePoiBadgeDragData.SCREEN_MARGIN)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .none, alignment: .topLeading)
                .background(Color(UIColor.secondarySystemFill))
            }
        }
        .tabItem
        {
            Image(systemName: "map")
            Text("W pobliżu")
        }
        
        ///TAB ITEM: Recent
        VStack()
        {
        }
        .tabItem
        {
            Image(systemName: "clock")
            Text("Ostatnie")
        }

        ///TAB ITEM: Favorites
        VStack()
        {
        }
        .tabItem
        {
            Image(systemName: "star")
            Text("Ulubione")
        }

        /*
        ///TAB ITEM: Search
        VStack()
        {
        }
        .tabItem
        {
            Image(systemName: "magnifyingglass.circle")
            Text("Szukaj")
        }
        */

        /*
        ///TAB ITEM: Menu
        VStack()
        {
        }
        .tabItem
        {
            Image(systemName: "gearshape")
            Text("Ustawienia")
        }
        */
        
        }
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            PhoneMainView()
        }
    }
}

#endif
