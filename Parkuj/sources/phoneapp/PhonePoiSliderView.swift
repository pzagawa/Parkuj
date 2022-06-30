//
//  PhonePoiSliderView.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 27/01/2021.
//

import SwiftUI

struct PhonePoiSliderView: View
{    
    enum PositionIndex: Int
    {
        case first = -2; case prev = -1; case current = 0; case next = 1; case last = 2;
    }
    
    @EnvironmentObject private var appState: PhoneApp

    @StateObject private var extDragData: PhonePoiBadgeDragData = PhonePoiBadgeDragData()

    func offset(_ index: PositionIndex) -> PositionIndex
    {
        return index
    }
    
    var isNoData: Bool
    {
        return appState.isEmpty
    }
    
    var body: some View
    {
        HStack
        {
            ZStack
            {
                if isNoData
                {
                    ZStack()
                    {
                        //empty invisible view to hold layout dimensions
                        PhonePoiBadgeDragView.emptyView()

                        Text("Nie znaleziono parkingów")
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    }
                }
                else
                {
                    PhonePoiBadgeDragView(positionIndex: offset(.first), extDragData: extDragData)
                    PhonePoiBadgeDragView(positionIndex: offset(.prev), extDragData: extDragData)
                    PhonePoiBadgeDragView(positionIndex: offset(.current), extDragData: extDragData)
                    PhonePoiBadgeDragView(positionIndex: offset(.next), extDragData: extDragData)
                    PhonePoiBadgeDragView(positionIndex: offset(.last), extDragData: extDragData)
                }
            }
        }
    }
}

struct PhonePoiSliderView_Previews: PreviewProvider
{
    static var previews: some View
    {
        PhonePoiSliderView()
            .previewLayout(.sizeThatFits)
    }
}
