import SwiftUI
import Charts

struct HourlyStatistics: Identifiable {
    let id = UUID()
    let hour: Date
    let count: Int
}

struct StatisticsView: View {
    let data: [HourlyStatistics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("收集趋势")
                    .font(Typography.subtitle)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("最近12小时")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            
            Chart(data) { item in
                AreaMark(
                    x: .value("时间", item.hour),
                    y: .value("数量", item.count)
                )
                .foregroundStyle(.blue.opacity(0.1))
                
                LineMark(
                    x: .value("时间", item.hour),
                    y: .value("数量", item.count)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour())
                        .font(Typography.caption)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(Typography.caption)
                }
            }
            .chartYScale(range: .plotDimension(padding: Spacing.small))
            .frame(height: 80)
        }
        .padding(Spacing.extraLarge)
    }
}

#Preview {
    StatisticsView(data: [
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -11, to: Date())!, count: 2),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -10, to: Date())!, count: 5),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -9, to: Date())!, count: 3),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!, count: 7),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!, count: 4),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!, count: 6),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!, count: 8),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!, count: 5),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!, count: 3),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, count: 4),
        HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, count: 6),
        HourlyStatistics(hour: Date(), count: 2)
    ])
} 
