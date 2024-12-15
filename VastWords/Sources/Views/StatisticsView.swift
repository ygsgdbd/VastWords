import SwiftUI
import Charts

struct HourlyStatistics: Identifiable {
    let id = UUID()
    let hour: Date
    let count: Int
}

struct StatisticsView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
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
            
            Text("总共收集了 \(viewModel.totalCount) 个单词")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, Spacing.small)
            
            Chart {
                ForEach(viewModel.hourlyStatistics) { item in
                    LineMark(
                        x: .value("时间", item.hour),
                        y: .value("数量", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("时间", item.hour),
                        y: .value("数量", item.count)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(Self.hourFormatter.string(from: date))
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
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
    StatisticsView()
        .environmentObject(WordListViewModel())
} 
