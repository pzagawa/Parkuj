//
//  PhonePoiBadgeDragView.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 19/02/2021.
//

import SwiftUI

extension View
{
    @ViewBuilder func isVisible(_ visible: Bool) -> some View
    {
        if visible
        {
            self
        }
        else
        {
            self.hidden()
        }
    }
}

struct PhonePoiBadgeDragView: View
{
    @EnvironmentObject private var appState: PhoneApp

    //ObservedObject: REFERENCED - NOT OWNED by current view
    @ObservedObject private var extDragData: PhonePoiBadgeDragData

    //StateObject: OWNED by current view - valid only for (positionIndex == .current)
    @StateObject private var dragData = PhonePoiBadgeDragData()
    
    private var positionIndex: PhonePoiSliderView.PositionIndex

    init(positionIndex: PhonePoiSliderView.PositionIndex, extDragData: PhonePoiBadgeDragData)
    {
        self.extDragData = extDragData
        self.positionIndex = positionIndex
    }

    private init()
    {
        self.extDragData = PhonePoiBadgeDragData()
        self.positionIndex = .current
    }

    static func emptyView() -> PhonePoiBadgeDragView
    {
        return PhonePoiBadgeDragView()
    }

    private var shadowSize: CGFloat
    {
        return PhonePoiBadgeDragData.PADDING_SIZE
    }
    
    private var positionOffset: CGFloat
    {
        return extDragData.positionOffset(positionIndex: positionIndex.rawValue)
    }

    private var animationState: Animation?
    {
        return extDragData.animationState
    }
    
    private var zIndexValue: Double
    {
        return (positionIndex == .current) ? 1 : 0
    }

    private var itemsIndex: Int?
    {
        if appState.isEmpty
        {
            return nil
        }
        
        let index = positionIndex.rawValue + extDragData.indexOffsetValue
        
        if index < 0
        {
            return nil
        }
        
        let max_count = appState.itemsCount
        
        if index > (max_count - 1)
        {
            return nil
        }
        
        return index
    }
    
    private var itemVisible: Bool
    {
        return itemsIndex != nil
    }

    private var targetPlace: TargetPlace?
    {
        if let index = itemsIndex
        {
            return appState.itemByIndex(itemIndex: index)
        }

        return nil
    }

    private func resetOffset()
    {
        //use transaction to cancel and override animation for offset reset action
        var transaction = Transaction(animation: .none)
        transaction.disablesAnimations = true

        withTransaction(transaction)
        {
            //when scroll anim stopped, reset view offset
            extDragData.reset()
            
            //update data
            if extDragData.moveFinishedLeft
            {
                extDragData.indexOffsetInc()
                
                onSelectedItem(itemIndex: extDragData.indexOffsetValue)
            }
            if extDragData.moveFinishedRight
            {
                extDragData.indexOffsetDec()

                onSelectedItem(itemIndex: extDragData.indexOffsetValue)
            }
        }
    }
    
    private func onSelectedItem(itemIndex: Int)
    {
        //main loop to avoid Graph Cycle log errors
        DispatchQueue.main.async
        {
            self.appState.selectItemByIndex(itemIndex: itemIndex)
        }
    }

    var body: some View
    {
        VStack
        {
            if positionIndex == .current
            {
                PhonePoiBadgeView(targetPlace: self.targetPlace)
                .offset(x: positionOffset, y: 0)
                .animation(animationState)
                .shadow(color: Color.black.opacity(0.2), radius: shadowSize, x: 0, y: 0)
                .gesture(dragData.dragGesture)
                .isVisible(itemVisible)
            }
            else
            {
                PhonePoiBadgeView(targetPlace: self.targetPlace)
                .offset(x: positionOffset, y: 0)
                .animation(animationState)
                .shadow(color: Color.black.opacity(0.2), radius: shadowSize, x: 0, y: 0)
                .isVisible(itemVisible)
            }
        }
        .onChange(of: dragData.offset)
        {
            _ in
            dragData.setExtDragData(extDragData: extDragData)
        }
        .onChange(of: dragData.state)
        {
            _ in
            dragData.setExtDragData(extDragData: extDragData)
        }
        .onChange(of: dragData.moveDir)
        {
            _ in
            dragData.setExtDragData(extDragData: extDragData)
            
            dragData.minIndexOffset = 0
            dragData.maxIndexOffset = appState.itemsCount
            dragData.indexOffsetValue = extDragData.indexOffsetValue

            if dragData.isMoveCommited
            {
                resetOffset()
            }
        }
        .zIndex(zIndexValue)
    }
}
