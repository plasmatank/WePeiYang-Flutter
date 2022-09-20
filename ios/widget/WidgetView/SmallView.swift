//
//  smallView.swift
//  Runner
//
//  Created by 李佳林 on 2022/9/18.
//

import SwiftUI
import WidgetKit

struct SmallView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var store = SwiftStorage.courseTable
    private var courseTable: CourseTable { store.object }
    let entry: DataEntry
    @State var currentCourses: [Course] = []
    var hour: Int {
        Calendar.current.dateComponents(in: TimeZone.current, from: Date()).hour ?? 0
    }
    var time: Int {
        let t = Calendar.current.dateComponents(in: TimeZone.current, from: Date().addingTimeInterval(-7 * 60 * 60))
        return t.hour! * 60 + t.minute!
    }
    var weekday: String {
        Date().format(with: "EEEE")
    }
    
    @State var preCourse = WidgetCourse()
    @State var nextCourse = WidgetCourse()
    
    
    var body: some View {
        VStack {
            HStack {
                Text(weekday)
                    .morningStar(style: .largeTitle, weight: .bold)
                    .foregroundColor(colorScheme == .dark ? Color(#colorLiteral(red: 0.2358871102, green: 0.5033512712, blue: 0.9931854606, alpha: 1)) : Color(#colorLiteral(red: 0.6872389913, green: 0.7085373998, blue: 0.8254910111, alpha: 1)))
                    .padding(.leading, -3)
                
                Spacer()
                
            }
//            Text(entry.date.format(with: "HH:mm:ss") + "T \(courseTable.customCourseArray.count)个 \(courseTable.courseArray.count)个\n" + "\(courseTable.currentWeek) \(courseTable.currentDay)\n" + "\(StorageKey.termStartDate.getGroupData())")
//                .foregroundColor(colorScheme == .dark ? Color(#colorLiteral(red: 0.2358871102, green: 0.5033512712, blue: 0.9931854606, alpha: 1)) : Color(#colorLiteral(red: 0.6872389913, green: 0.7085373998, blue: 0.8254910111, alpha: 1)))
            
            
            GeometryReader { geo in
                VStack(alignment: .leading) {
                    if !currentCourses.isEmpty {
                        HStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(colorScheme == .dark ? Color(#colorLiteral(red: 0.2358871102, green: 0.5033512712, blue: 0.9931854606, alpha: 1)) : Color(#colorLiteral(red: 0.3056178987, green: 0.3728546202, blue: 0.4670386314, alpha: 1)))
                                    .frame(width: 3, height: 28)
                                    .padding(.leading, 6)
                                
                                if !preCourse.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("\(preCourse.course.name)")
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                            .lineLimit(1)
                                        HStack {
                                            Text("\(preCourse.course.activeArrange(courseTable.currentDay).location)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                            
                                            Text("\(preCourse.course.activeArrange(courseTable.currentDay).startTimeString)-\(preCourse.course.activeArrange(courseTable.currentDay).endTimeString)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                else {
                                    Text("当前没有课:)")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                        }
                        
                        
                        HStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colorScheme == .dark ? Color(#colorLiteral(red: 0.2358871102, green: 0.5033512712, blue: 0.9931854606, alpha: 1)) : Color(#colorLiteral(red: 0.3056178987, green: 0.3728546202, blue: 0.4670386314, alpha: 1)))
                                .frame(width: 3, height: 28)
                                .padding(.leading, 6)
                                if !nextCourse.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("\(nextCourse.course.name)")
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                            .lineLimit(1)
                                        HStack {
                                            Text("\(nextCourse.course.activeArrange(courseTable.currentDay).location)")
                                                .font(.system(size: 10))
                                                .foregroundColor(colorScheme == .dark ? .white : .gray)
                                            
                                            Text("\(nextCourse.course.activeArrange(courseTable.currentDay).startTimeString)-\(nextCourse.course.activeArrange(courseTable.currentDay).endTimeString)")
                                                .font(.system(size: 10))
                                                .foregroundColor(colorScheme == .dark ? .white : .gray)
                                        }
                                    }
                                } else {
                                    Text("接下来没有课:)")
                                        .font(.footnote)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                        }
                        
                    } else {
                        Text(hour>21 ? "夜深了\n做个早睡的人吧" : "今日无课:)\n做点有意义的事情吧")
                            .font(.footnote)
                            .bold()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding([.leading, .top])
                    }
                    
                }
            }
        }
        .padding(.top, 15)
        .onAppear {
            (preCourse, nextCourse) = WidgetCourseManager.getPresentAndNextCourse(courseArray: currentCourses, weekday: courseTable.currentDay, time: time)
        }
    }

}
