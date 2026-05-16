//
//  GlimpseWidgetLiveActivity.swift
//  GlimpseWidget
//
//  Created by LOVINPEACE on 17/05/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GlimpseWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GlimpseWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GlimpseWidgetAttributes.self) { context in
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

extension GlimpseWidgetAttributes {
    fileprivate static var preview: GlimpseWidgetAttributes {
        GlimpseWidgetAttributes(name: "World")
    }
}

extension GlimpseWidgetAttributes.ContentState {
    fileprivate static var smiley: GlimpseWidgetAttributes.ContentState {
        GlimpseWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GlimpseWidgetAttributes.ContentState {
         GlimpseWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GlimpseWidgetAttributes.preview) {
   GlimpseWidgetLiveActivity()
} contentStates: {
    GlimpseWidgetAttributes.ContentState.smiley
    GlimpseWidgetAttributes.ContentState.starEyes
}
