//
//  GlimpseWidgetBundle.swift
//  GlimpseWidget
//
//  Created by LOVINPEACE on 17/05/26.
//

import WidgetKit
import SwiftUI

@main
struct GlimpseWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlimpseWidget()
        GlimpseWidgetControl()
        GlimpseWidgetLiveActivity()
    }
}
