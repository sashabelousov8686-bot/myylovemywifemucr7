import SwiftUI
import PDFKit

// MARK: - PDF Export Service

@MainActor
struct PDFExportService {
    
    /// Generate a PDF report for a savings goal
    static func generateReport(
        goalName: String,
        targetAmount: Double,
        currentSavings: Double,
        monthlyDeposit: Double,
        expectedReturn: Double,
        inflationRate: Double,
        currency: String,
        years: Int,
        chartData: [GrowthPoint]
    ) -> Data? {
        let pageWidth: CGFloat = 612 // Letter size
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yOffset: CGFloat = margin
            
            // ===== HEADER =====
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor(red: 0, green: 0.83, blue: 1, alpha: 1) // neon blue
            ]
            let title = "GoalTime: Savings Simulator"
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttr)
            yOffset += 40
            
            // Subtitle
            let subtitleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let subtitle = "Savings Projection Report — \(dateFormatter.string(from: Date()))"
            subtitle.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: subtitleAttr)
            yOffset += 30
            
            // Separator line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: yOffset))
            linePath.addLine(to: CGPoint(x: pageWidth - margin, y: yOffset))
            UIColor(red: 0, green: 0.83, blue: 1, alpha: 0.5).setStroke()
            linePath.lineWidth = 1.5
            linePath.stroke()
            yOffset += 20
            
            // ===== GOAL DETAILS =====
            let headerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let bodyAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let valueAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            
            "Goal Details".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: headerAttr)
            yOffset += 28
            
            let details: [(String, String)] = [
                ("Goal Name:", goalName),
                ("Target Amount:", CurrencyHelper.format(targetAmount, currency: currency)),
                ("Current Savings:", CurrencyHelper.format(currentSavings, currency: currency)),
                ("Monthly Deposit:", CurrencyHelper.format(monthlyDeposit, currency: currency)),
                ("Expected Return:", String(format: "%.1f%%", expectedReturn)),
                ("Inflation Rate:", String(format: "%.1f%%", inflationRate)),
                ("Time Horizon:", "\(years) years"),
            ]
            
            for (label, value) in details {
                label.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: bodyAttr)
                value.draw(at: CGPoint(x: margin + 160, y: yOffset), withAttributes: valueAttr)
                yOffset += 20
            }
            
            yOffset += 10
            
            // ===== PROJECTION RESULTS =====
            "Projection Summary".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: headerAttr)
            yOffset += 28
            
            let lastPoint = chartData.last
            let fv = lastPoint?.nominalValue ?? 0
            let rv = lastPoint?.realValue ?? 0
            let deposited = lastPoint?.totalDeposited ?? 0
            let compoundGain = fv - deposited
            
            let results: [(String, String)] = [
                ("Future Value (Nominal):", CurrencyHelper.format(fv, currency: currency)),
                ("Future Value (Real, Today's $):", CurrencyHelper.format(rv, currency: currency)),
                ("Total Deposited:", CurrencyHelper.format(deposited, currency: currency)),
                ("Compound Interest Earned:", CurrencyHelper.format(compoundGain, currency: currency)),
            ]
            
            for (label, value) in results {
                label.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: bodyAttr)
                value.draw(at: CGPoint(x: margin + 220, y: yOffset), withAttributes: valueAttr)
                yOffset += 20
            }
            
            yOffset += 20
            
            // ===== CHART (simplified table-based) =====
            "Year-by-Year Breakdown".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: headerAttr)
            yOffset += 28
            
            // Table header
            let tableHeaderAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            // Header background
            let headerRect = CGRect(x: margin, y: yOffset - 2, width: contentWidth, height: 22)
            UIColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1).setFill()
            UIBezierPath(roundedRect: headerRect, cornerRadius: 4).fill()
            
            let colWidths: [CGFloat] = [60, 130, 130, 130]
            let headers = ["Year", "Nominal Value", "Real Value", "Deposited"]
            var xPos = margin + 8
            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPos, y: yOffset), withAttributes: tableHeaderAttr)
                xPos += colWidths[i]
            }
            yOffset += 24
            
            // Table rows - sample every year from chartData
            let tableRowAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            
            let yearlyPoints = chartData.filter { Int($0.year) == Int($0.year) && $0.month % 12 == 0 }
            for point in yearlyPoints {
                guard yOffset < pageHeight - 80 else { break }
                
                let yearStr = "\(Int(point.year))"
                let nomStr = CurrencyHelper.format(point.nominalValue, currency: currency)
                let realStr = CurrencyHelper.format(point.realValue, currency: currency)
                let depStr = CurrencyHelper.format(point.totalDeposited, currency: currency)
                
                // Alternating row background
                if Int(point.year) % 2 == 0 {
                    let rowRect = CGRect(x: margin, y: yOffset - 2, width: contentWidth, height: 18)
                    UIColor(white: 0.95, alpha: 1).setFill()
                    UIBezierPath(rect: rowRect).fill()
                }
                
                xPos = margin + 8
                yearStr.draw(at: CGPoint(x: xPos, y: yOffset), withAttributes: tableRowAttr)
                xPos += colWidths[0]
                nomStr.draw(at: CGPoint(x: xPos, y: yOffset), withAttributes: tableRowAttr)
                xPos += colWidths[1]
                realStr.draw(at: CGPoint(x: xPos, y: yOffset), withAttributes: tableRowAttr)
                xPos += colWidths[2]
                depStr.draw(at: CGPoint(x: xPos, y: yOffset), withAttributes: tableRowAttr)
                yOffset += 18
            }
            
            // ===== FOOTER =====
            let footerY = pageHeight - margin - 30
            let disclaimerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                .foregroundColor: UIColor.lightGray
            ]
            
            let disclaimer = "This is a private personal savings simulation tool for educational purposes. Not financial advice or investment recommendation.\nGenerated by GoalTime: Savings Simulator"
            let disclaimerRect = CGRect(x: margin, y: footerY, width: contentWidth, height: 30)
            (disclaimer as NSString).draw(in: disclaimerRect, withAttributes: disclaimerAttr)
        }
        
        return data
    }
    
    /// Save PDF to temporary file and return URL for sharing
    static func savePDFToTemp(data: Data) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("GoalTime_Report_\(Int(Date().timeIntervalSince1970)).pdf")
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("PDF save error: \(error)")
            return nil
        }
    }
    
    /// Share PDF via system share sheet — finds the topmost view controller reliably
    static func sharePDF(data: Data) {
        guard let tempURL = savePDFToTemp(data: data) else { return }
        
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        guard let topVC = Self.topViewController() else {
            print("PDF export error: could not find top view controller")
            return
        }
        
        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        topVC.present(activityVC, animated: true)
    }
    
    /// Traverse the view controller hierarchy to find the topmost presented controller
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first
        else { return nil }
        
        guard var topController = windowScene.windows
            .first(where: { $0.isKeyWindow })?.rootViewController
                ?? windowScene.windows.first?.rootViewController
        else { return nil }
        
        // Walk up the presentation chain to the topmost controller
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        return topController
    }
}
