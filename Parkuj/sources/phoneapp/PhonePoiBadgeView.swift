//
//  PhonePoiBadgeView.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 06/01/2021.
//

import SwiftUI

struct PhonePoiBadgeView: View
{
    @EnvironmentObject private var appState: PhoneApp

    private var targetPlace: TargetPlace?

    init(targetPlace: TargetPlace?)
    {
        self.targetPlace = targetPlace
    }

    var isData: Bool
    {
        return targetPlace != nil
    }
    
    var itemTitle: String
    {
        if let item = targetPlace
        {
            return item.title
        }
        
        return "miejsce"
    }
    
    var itemAddress: String?
    {
        if let item = targetPlace
        {
            return item.subtitleAddress
        }

        return nil
    }
    
    var itemSubtitleItems: [String]
    {
        if let item = targetPlace
        {
            return item.subtitleItems
        }

        return []
    }
    
    var itemDistanceText: String
    {
        if let item = targetPlace
        {
            return item.distanceText
        }

        return "dystans"
    }

    var itemTravelTimeText: String
    {
        if let item = targetPlace
        {
            return item.travelTimeText
        }
    
        return "czas"
    }
    
    var body: some View
    {
        VStack
        {
            VStack(alignment: .leading, spacing: 6)
            {
                //first line: title
                HStack(alignment: .top)
                {
                    Text(itemTitle)
                        .font(.title2)
                        .foregroundColor(Color(UIColor.label))
                        .bold()
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .redacted(reason: isData ? [] : .placeholder)
                        
                    Spacer()
                }
                
                //second line: address, tags
                HStack(spacing: 6.0)
                {
                    if targetPlace != nil
                    {
                        if let address = itemAddress
                        {
                            PhonePoiTagTextView(text: address, color: Color.blue)
                        }
                        
                        ForEach(itemSubtitleItems, id: \.self)
                        {
                            item in
                            PhonePoiTagTextView(text: item, color: Color.gray)
                        }
                    }

                    //invisible tag item to keep parent height fixed
                    PhonePoiTagTextView(text: "X", color: Color(UIColor.systemGray6))
                }
                
                Spacer()
                    .frame(height: 4)

                //third line: summary / distance, time
                HStack(spacing: 6.0)
                {
                    Spacer()
                    
                    //summary distance
                    Image(systemName: "car")
                        .foregroundColor(Color(UIColor.label))
                        
                    if targetPlace == nil
                    {
                        PhonePoiTagSummaryView(text: "dystans", color: Color.green)
                        .redacted(reason: .placeholder)
                    }
                    else
                    {
                        PhonePoiTagSummaryView(text: itemDistanceText, color: Color.green)
                    }

                    //summary time
                    Image(systemName: "clock")
                        .foregroundColor(Color(UIColor.label))

                    if targetPlace == nil
                    {
                        PhonePoiTagSummaryView(text: "czas", color: Color.orange)
                        .redacted(reason: .placeholder)
                    }
                    else
                    {
                        PhonePoiTagSummaryView(text: itemTravelTimeText, color: Color.orange)
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.top, 6)
            .padding(.bottom, 11)
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: 0, maxHeight: .none, alignment: .topLeading)
        }
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .clipped()
    }
}

struct PhonePoiBadgeView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group {
            PhonePoiBadgeView(targetPlace: nil)
                .previewLayout(.sizeThatFits)
            PhonePoiBadgeView(targetPlace: nil)
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
        }
    }
}
