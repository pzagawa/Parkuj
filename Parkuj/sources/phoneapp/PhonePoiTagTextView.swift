//
//  PhonePoiTagTextView.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 06/01/2021.
//

import SwiftUI

struct PhonePoiTagTextView: View
{
    var text: String = "tag"
    var color: Color = Color.gray

    var body: some View
    {
        HStack
        {
            Text(self.text)
                .font(.caption)
                .bold()
                .textCase(.uppercase)
                .lineLimit(1)
                .padding(.top, 1)
                .padding(.bottom, 1)
                .padding(.leading, 4)
                .padding(.trailing, 4)
                .background(self.color)
                .foregroundColor(Color(UIColor.systemGray6))
                .cornerRadius(4)
        }
    }
}

struct PhonePoiTagTextView_Previews: PreviewProvider
{
    static var previews: some View
    {
        PhonePoiTagTextView()
            .previewLayout(.sizeThatFits)
    }
}
