import SwiftUI
import Charts

// MARK: - Animated Growth Chart with Glow Effect

struct GrowthChartView: View {
    let data: [GrowthPoint]
    let currency: String
    let showRealValue: Bool
    let showDeposits: Bool
    let animateOnAppear: Bool
    
    @State private var chartProgress: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    init(
        data: [GrowthPoint],
        currency: String = "USD",
        showRealValue: Bool = true,
        showDeposits: Bool = true,
        animateOnAppear: Bool = true
    ) {
        self.data = data
        self.currency = currency
        self.showRealValue = showRealValue
        self.showDeposits = showDeposits
        self.animateOnAppear = animateOnAppear
    }
    
    private var visibleData: [GrowthPoint] {
        guard animateOnAppear else { return data }
        let visibleCount = Int(CGFloat(data.count) * chartProgress)
        return Array(data.prefix(max(1, visibleCount)))
    }
    
    var body: some View {
        Chart {
            if showDeposits {
                ForEach(visibleData) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Deposited", point.totalDeposited)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [AppTheme.Colors.chartDeposits.opacity(0.3), AppTheme.Colors.chartDeposits.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Deposited", point.totalDeposited)
                    )
                    .foregroundStyle(AppTheme.Colors.chartDeposits.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .interpolationMethod(.catmullRom)
                }
            }
            
            if showRealValue {
                ForEach(visibleData) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Real", point.realValue)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [AppTheme.Colors.chartReal.opacity(0.25), AppTheme.Colors.chartReal.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Real", point.realValue)
                    )
                    .foregroundStyle(AppTheme.Colors.chartReal)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            
            ForEach(visibleData) { point in
                AreaMark(
                    x: .value("Year", point.year),
                    y: .value("Nominal", point.nominalValue)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [AppTheme.Colors.chartNominal.opacity(0.3), AppTheme.Colors.chartNominal.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Year", point.year),
                    y: .value("Nominal", point.nominalValue)
                )
                .foregroundStyle(AppTheme.Colors.chartNominal)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxisLabel("Years", position: .bottom)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(CurrencyHelper.formatCompact(doubleValue, currency: currency))
                            .font(.caption2)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisValueLabel {
                    if let year = value.as(Double.self) {
                        Text("\(Int(year))y")
                            .font(.caption2)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .chartLegend(position: .bottom, spacing: 12) {
            HStack(spacing: 16) {
                LegendItem(color: AppTheme.Colors.chartNominal, label: "Nominal")
                if showRealValue {
                    LegendItem(color: AppTheme.Colors.chartReal, label: "Real Value")
                }
                if showDeposits {
                    LegendItem(color: AppTheme.Colors.chartDeposits, label: "Deposits")
                }
            }
            .font(.caption2)
        }
        .frame(height: 260)
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    chartProgress = 1.0
                }
            } else {
                chartProgress = 1.0
            }
        }
    }
}

// MARK: - Comparison Chart (Two Scenarios)

struct ComparisonChartView: View {
    let dataA: [GrowthPoint]
    let dataB: [GrowthPoint]
    let labelA: String
    let labelB: String
    let currency: String
    
    @State private var chartProgress: CGFloat = 0
    
    var body: some View {
        let visibleCountA = Int(CGFloat(dataA.count) * chartProgress)
        let visibleCountB = Int(CGFloat(dataB.count) * chartProgress)
        let visA = Array(dataA.prefix(max(1, visibleCountA)))
        let visB = Array(dataB.prefix(max(1, visibleCountB)))
        
        Chart {
            ForEach(visA) { point in
                AreaMark(
                    x: .value("Year", point.year),
                    y: .value(labelA, point.nominalValue)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [AppTheme.Colors.neonBlue.opacity(0.2), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Year", point.year),
                    y: .value(labelA, point.nominalValue)
                )
                .foregroundStyle(AppTheme.Colors.neonBlue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }
            
            ForEach(visB) { point in
                AreaMark(
                    x: .value("Year", point.year),
                    y: .value(labelB, point.nominalValue)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [AppTheme.Colors.purple.opacity(0.2), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Year", point.year),
                    y: .value(labelB, point.nominalValue)
                )
                .foregroundStyle(AppTheme.Colors.purple)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(CurrencyHelper.formatCompact(doubleValue, currency: currency))
                            .font(.caption2)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisValueLabel {
                    if let year = value.as(Double.self) {
                        Text("\(Int(year))y")
                            .font(.caption2)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .chartLegend(position: .bottom, spacing: 12) {
            HStack(spacing: 16) {
                LegendItem(color: AppTheme.Colors.neonBlue, label: labelA)
                LegendItem(color: AppTheme.Colors.purple, label: labelB)
            }
            .font(.caption2)
        }
        .frame(height: 260)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                chartProgress = 1.0
            }
        }
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}
