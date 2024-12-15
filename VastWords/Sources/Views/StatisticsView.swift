import SwiftUI
import Charts

struct HourlyStatistics: Identifiable {
    let id = UUID()
    let hour: Date
    let count: Int
}

struct StatisticsView: View {
    let data: [HourlyStatistics]
    let totalCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("收集统计")
                    .font(Typography.subtitle)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("最近24小时")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("总共收集了 \(totalCount) 个单词")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, Spacing.small)
            
            Chart(data) { item in
                AreaMark(
                    x: .value("时间", item.hour),
                    y: .value("数量", item.count)
                )
                .foregroundStyle(.blue.opacity(0.1))
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("时间", item.hour),
                    y: .value("数量", item.count)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.1))
                    AxisValueLabel(format: .dateTime.hour())
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.1))
                    AxisValueLabel()
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYScale(range: .plotDimension(padding: Spacing.medium))
            .frame(height: 80)
        }
        .padding(.horizontal, Spacing.extraLarge)
        .padding(.vertical, Spacing.large)
    }
}

#Preview {
    StatisticsView(
        data: [
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -23, to: Date())!, count: 2),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -22, to: Date())!, count: 5),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -21, to: Date())!, count: 3),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -20, to: Date())!, count: 7),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -19, to: Date())!, count: 4),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -18, to: Date())!, count: 6),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -17, to: Date())!, count: 8),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -16, to: Date())!, count: 5),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -15, to: Date())!, count: 3),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -14, to: Date())!, count: 4),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -13, to: Date())!, count: 6),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!, count: 2),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -11, to: Date())!, count: 5),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -10, to: Date())!, count: 3),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -9, to: Date())!, count: 7),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!, count: 4),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -7, to: Date())!, count: 6),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!, count: 8),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!, count: 5),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!, count: 3),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!, count: 4),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, count: 6),
            HourlyStatistics(hour: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, count: 2),
            HourlyStatistics(hour: Date(), count: 3)
        ],
        totalCount: 98
    )
} 
