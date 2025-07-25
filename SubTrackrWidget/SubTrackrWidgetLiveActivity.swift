//
//  SubTrackrWidgetLiveActivity.swift
//  SubTrackrWidget
//
//  Created by Tumuhirwe Iden on 25/07/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SubTrackrWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SubTrackrWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SubTrackrWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SubTrackrWidgetAttributes {
    fileprivate static var preview: SubTrackrWidgetAttributes {
        SubTrackrWidgetAttributes(name: "World")
    }
}

extension SubTrackrWidgetAttributes.ContentState {
    fileprivate static var smiley: SubTrackrWidgetAttributes.ContentState {
        SubTrackrWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SubTrackrWidgetAttributes.ContentState {
         SubTrackrWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SubTrackrWidgetAttributes.preview) {
   SubTrackrWidgetLiveActivity()
} contentStates: {
    SubTrackrWidgetAttributes.ContentState.smiley
    SubTrackrWidgetAttributes.ContentState.starEyes
}
