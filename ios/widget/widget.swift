//
//  FlutterWidget.swift
//  FlutterWidget
//
//  Created by Thomas Leiter on 28.10.20.
//

import WidgetKit
import SwiftUI
import Intents


struct CourseTableWidgetEntryView: View {
    var entry: CourseTimelineProvider.Entry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemMedium:
            MediumView(entry: entry)
        case .systemLarge:
            LargeView(entry: entry)
        default:
            SmallView(entry: entry)
        }
    }
}



@main
struct PeiYang_LiteWidget: Widget {
    let kind: String = "WePeiyangWidget"
    @Environment(\.widgetFamily) var family

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CourseTimelineProvider()) { entry in
            CourseTableWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("WePeiyang Widget")
        .description("快速查看当前课表信息。")
        .supportedFamilies([.systemMedium, .systemSmall, .systemLarge])
    }
}

//struct PeiYangLiteWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        MediumView(currentCourseTable: [Course()], weathers: [Weather()])
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//    }
//}
