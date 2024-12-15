import SwiftUI
import Charts

struct HourlyStatistics: Identifiable {
    let id = UUID()
    let hour: Date
    let count: Int
}

struct StatisticsView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    @State private var selectedHour: Date?
    @State private var selectedCount: Int?
    
    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }()
    
    private var totalWordsDescription: String {
        if let firstWordDate = viewModel.firstWordDate {
            return "自 \(Self.dateFormatter.string(from: firstWordDate)) 起，已收集 \(viewModel.totalCount) 个单词"
        }
        return "已收集 \(viewModel.totalCount) 个单词"
    }
    
    private var hourlyAverage: Double {
        let total = viewModel.hourlyStatistics.reduce(0) { $0 + $1.count }
        return Double(total) / Double(viewModel.hourlyStatistics.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 标题区域
            HStack {
                Text("12小时趋势")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label {
                    Text(String(format: "平均每小时 %.1f 个", hourlyAverage))
                        .font(.system(size: 11))
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            
            // 图表区域
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
                    
                    if selectedHour == item.hour {
                        PointMark(
                            x: .value("时间", item.hour),
                            y: .value("数量", item.count)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(100)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(Self.hourFormatter.string(from: date))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYScale(range: .plotDimension(padding: Spacing.medium))
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let currentX = value.location.x
                                    guard currentX >= 0,
                                          currentX <= geometry.size.width,
                                          let hour: Date = proxy.value(atX: currentX) else {
                                        return
                                    }
                                    
                                    if let statistics = viewModel.hourlyStatistics.first(where: { abs($0.hour.timeIntervalSince(hour)) < 1800 }) {
                                        selectedHour = statistics.hour
                                        selectedCount = statistics.count
                                    }
                                }
                                .onEnded { _ in
                                    selectedHour = nil
                                    selectedCount = nil
                                }
                        )
                }
            }
            .frame(height: 120)
            
            if let hour = selectedHour,
               let count = selectedCount {
                Text("\(Self.hourFormatter.string(from: hour)) 收集了 \(count) 个单词")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Spacing.extraLarge)
        .padding(.vertical, Spacing.large)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(WordListViewModel())
} 
