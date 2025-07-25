//
//  SubTrackrWidgetBundle.swift
//  SubTrackrWidget
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import WidgetKit
import SwiftUI

@main
struct SubTrackrWidgetBundle: WidgetBundle {
    var body: some Widget {
        SubTrackrWidget()
        SubTrackrWidgetControl()
        SubTrackrWidgetLiveActivity()
    }
}
