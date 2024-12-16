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
    
    private var todayStatistics: [HourlyStatistics] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return viewModel.hourlyStatistics
            .filter { calendar.isDateInToday($0.hour) }
            .sorted { $0.hour < $1.hour }
    }
    
    private var todayCount: Int {
        todayStatistics.reduce(0) { $0 + $1.count }
    }
    
    private var todayAveragePerHour: Double {
        guard !todayStatistics.isEmpty else { return 0 }
        return Double(todayCount) / Double(max(1, todayStatistics.count))
    }
    
    private var todayMaxHourlyCount: (hour: Date, count: Int)? {
        todayStatistics.max { $0.count < $1.count }
            .map { ($0.hour, $0.count) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 趋势标题
            Text("今日趋势")
                .font(.system(size: 9))
                .foregroundStyle(.secondary.opacity(0.8))
            
            if todayStatistics.isEmpty {
                Text("今天还没有收集单词")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
            } else {
                // 图表区域
                Chart {
                    ForEach(todayStatistics) { item in
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
                    AxisMarks(values: .stride(by: .hour, count: 2)) { value in
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
                                        
                                        if let statistics = todayStatistics.first(where: { abs($0.hour.timeIntervalSince(hour)) < 1800 }) {
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
                .frame(height: 80)
            }
            
            if let hour = selectedHour,
               let count = selectedCount {
                Text("\(Self.hourFormatter.string(from: hour)) 收集了 \(count) 个单词")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            
            // 起始时间统计
            if let startDate = viewModel.firstWordDate {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "calendar")
                        .frame(width: 16)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Text("开始时间")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Self.dateFormatter.string(from: startDate))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if let relativeTime = viewModel.relativeTimeDescription {
                        Text("（\(relativeTime)）")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                }
            }
            
            // 总计统计
            HStack(spacing: Spacing.small) {
                Image(systemName: "text.word.spacing")
                    .frame(width: 16)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Text("收集总数")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(viewModel.totalCount) 个单词")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            // 今日统计
            HStack(spacing: Spacing.small) {
                Image(systemName: "sun.max")
                    .frame(width: 16)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Text("今日收集")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(todayCount) 个单词")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            // 今日平均速度统计
            HStack(spacing: Spacing.small) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .frame(width: 16)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Text("今日平均")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(String(format: "每小时 %.1f 个", todayAveragePerHour))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            // 今日最高记录
            if let max = todayMaxHourlyCount {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "trophy")
                        .frame(width: 16)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Text("今日最高")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Self.hourFormatter.string(from: max.hour)) · \(max.count) 个")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
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
