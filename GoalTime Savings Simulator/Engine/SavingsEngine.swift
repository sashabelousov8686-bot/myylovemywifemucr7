import Foundation

// MARK: - Savings Calculation Engine
// Future Value of Annuity with inflation adjustment

struct SavingsEngine {
    
    // MARK: - Core Future Value Calculation
    
    /// Future Value of Annuity Due
    /// FV = P × (((1 + r)^n - 1) / r) × (1 + r) + PV × (1 + r)^n
    /// where P = monthly payment, r = monthly rate, n = number of months, PV = present value (current savings)
    static func futureValue(
        currentSavings: Double,
        monthlyDeposit: Double,
        annualReturnRate: Double,
        years: Double
    ) -> Double {
        let months = Int(years * 12)
        let monthlyRate = annualReturnRate / 100.0 / 12.0
        
        guard monthlyRate > 0 else {
            // Simple accumulation without returns
            return currentSavings + monthlyDeposit * Double(months)
        }
        
        // FV of existing savings
        let fvExisting = currentSavings * pow(1 + monthlyRate, Double(months))
        
        // FV of annuity (monthly deposits)
        let fvAnnuity = monthlyDeposit * (((pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate) * (1 + monthlyRate))
        
        return fvExisting + fvAnnuity
    }
    
    // MARK: - Inflation-Adjusted (Real) Value
    
    /// Returns the future value adjusted for inflation (today's purchasing power)
    static func realValue(
        futureValue: Double,
        annualInflationRate: Double,
        years: Double
    ) -> Double {
        guard annualInflationRate > 0 else { return futureValue }
        return futureValue / pow(1 + annualInflationRate / 100.0, years)
    }
    
    // MARK: - Monthly Growth Curve Data Points
    
    /// Returns an array of (month, nominalValue, realValue) for charting
    static func growthCurve(
        currentSavings: Double,
        monthlyDeposit: Double,
        annualReturnRate: Double,
        annualInflationRate: Double,
        totalYears: Int
    ) -> [GrowthPoint] {
        var points: [GrowthPoint] = []
        let totalMonths = totalYears * 12
        let monthlyRate = annualReturnRate / 100.0 / 12.0
        
        var balance = currentSavings
        
        for month in 0...totalMonths {
            let years = Double(month) / 12.0
            let realVal = realValue(futureValue: balance, annualInflationRate: annualInflationRate, years: years)
            let depositsOnly = currentSavings + monthlyDeposit * Double(month)
            
            // Sample every 3 months for performance, always include year boundaries
            if month % 3 == 0 || month == totalMonths {
                points.append(GrowthPoint(
                    month: month,
                    year: years,
                    nominalValue: balance,
                    realValue: realVal,
                    totalDeposited: depositsOnly
                ))
            }
            
            if month < totalMonths {
                balance = balance * (1 + monthlyRate) + monthlyDeposit
            }
        }
        
        return points
    }
    
    // MARK: - Reverse Calculation: Required Monthly Deposit
    
    /// Calculate required monthly deposit to reach target by given date
    static func requiredMonthlyDeposit(
        currentSavings: Double,
        targetAmount: Double,
        annualReturnRate: Double,
        years: Double
    ) -> Double {
        let months = Int(years * 12)
        let monthlyRate = annualReturnRate / 100.0 / 12.0
        
        guard months > 0 else { return max(0, targetAmount - currentSavings) }
        
        guard monthlyRate > 0 else {
            return max(0, (targetAmount - currentSavings) / Double(months))
        }
        
        // FV of existing savings
        let fvExisting = currentSavings * pow(1 + monthlyRate, Double(months))
        
        // Remaining amount needed from deposits
        let remaining = targetAmount - fvExisting
        
        guard remaining > 0 else { return 0 }
        
        // Solve for P: remaining = P × (((1+r)^n - 1) / r) × (1+r)
        let annuityFactor = (((pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate) * (1 + monthlyRate))
        
        return remaining / annuityFactor
    }
    
    // MARK: - Time to Goal
    
    /// Calculate months needed to reach target amount
    static func monthsToGoal(
        currentSavings: Double,
        monthlyDeposit: Double,
        annualReturnRate: Double,
        targetAmount: Double
    ) -> Int? {
        guard monthlyDeposit > 0 || currentSavings > 0 else { return nil }
        guard targetAmount > currentSavings else { return 0 }
        
        let monthlyRate = annualReturnRate / 100.0 / 12.0
        var balance = currentSavings
        
        for month in 1...600 { // Max 50 years
            balance = balance * (1 + monthlyRate) + monthlyDeposit
            if balance >= targetAmount {
                return month
            }
        }
        
        return nil // Goal unreachable within 50 years
    }
    
    // MARK: - Incremental Impact
    
    /// Calculate the impact of additional monthly savings
    static func incrementalImpact(
        currentSavings: Double,
        baseMonthlyDeposit: Double,
        additionalMonthly: Double,
        annualReturnRate: Double,
        annualInflationRate: Double,
        years: Double
    ) -> IncrementalResult {
        let baseFV = futureValue(currentSavings: currentSavings, monthlyDeposit: baseMonthlyDeposit, annualReturnRate: annualReturnRate, years: years)
        let boostedFV = futureValue(currentSavings: currentSavings, monthlyDeposit: baseMonthlyDeposit + additionalMonthly, annualReturnRate: annualReturnRate, years: years)
        
        let extraGain = boostedFV - baseFV
        let extraGainReal = realValue(futureValue: extraGain, annualInflationRate: annualInflationRate, years: years)
        let totalExtraDeposited = additionalMonthly * years * 12
        let compoundBonus = extraGain - totalExtraDeposited
        
        return IncrementalResult(
            baseValue: baseFV,
            boostedValue: boostedFV,
            extraGain: extraGain,
            extraGainReal: extraGainReal,
            totalExtraDeposited: totalExtraDeposited,
            compoundBonus: compoundBonus
        )
    }
    
    // MARK: - Strategy Comparison
    
    /// Compare different return rate strategies
    static func compareStrategies(
        currentSavings: Double,
        monthlyDeposit: Double,
        annualInflationRate: Double,
        years: Double,
        strategies: [Strategy]
    ) -> [StrategyResult] {
        return strategies.map { strategy in
            let fv = futureValue(currentSavings: currentSavings, monthlyDeposit: monthlyDeposit, annualReturnRate: strategy.annualReturn, years: years)
            let rv = realValue(futureValue: fv, annualInflationRate: annualInflationRate, years: years)
            return StrategyResult(strategy: strategy, futureValue: fv, realValue: rv)
        }
    }
    
    // MARK: - Inflation Cost of Goal
    
    /// What will today's goal cost in future dollars?
    static func inflatedGoalCost(
        currentCost: Double,
        annualInflationRate: Double,
        years: Double
    ) -> Double {
        return currentCost * pow(1 + annualInflationRate / 100.0, years)
    }
    
    // MARK: - Year Milestones
    
    /// Generate milestone data for every year
    static func yearlyMilestones(
        currentSavings: Double,
        monthlyDeposit: Double,
        annualReturnRate: Double,
        annualInflationRate: Double,
        targetAmount: Double,
        startYear: Int,
        totalYears: Int
    ) -> [YearMilestone] {
        var milestones: [YearMilestone] = []
        let monthlyRate = annualReturnRate / 100.0 / 12.0
        var balance = currentSavings
        var goalReached = false
        
        for year in 0...totalYears {
            let rv = realValue(futureValue: balance, annualInflationRate: annualInflationRate, years: Double(year))
            let progress = targetAmount > 0 ? min(balance / targetAmount, 1.0) : 0
            
            if balance >= targetAmount && !goalReached {
                goalReached = true
            }
            
            milestones.append(YearMilestone(
                year: startYear + year,
                yearsFromNow: year,
                balance: balance,
                realBalance: rv,
                progress: progress,
                goalReached: goalReached
            ))
            
            // Advance 12 months
            if year < totalYears {
                for _ in 0..<12 {
                    balance = balance * (1 + monthlyRate) + monthlyDeposit
                }
            }
        }
        
        return milestones
    }
    // MARK: - Savings Health Score (Proprietary 0–100 Metric)
    
    /// Composite score evaluating how healthy the savings plan is.
    /// Factors: funding ratio, time buffer, inflation protection, compound leverage, consistency capacity.
    static func healthScore(
        currentSavings: Double,
        monthlyDeposit: Double,
        targetAmount: Double,
        annualReturnRate: Double,
        annualInflationRate: Double,
        yearsToTarget: Double
    ) -> SavingsHealthReport {
        guard targetAmount > 0, yearsToTarget > 0 else {
            return SavingsHealthReport(overall: 0, funding: 0, timeBuffer: 0, inflationShield: 0, compoundPower: 0, status: .critical, advice: "Set a savings goal to get your Health Score.")
        }
        
        // 1. Funding Ratio (0–30 pts): Can you reach the goal on time?
        let requiredDeposit = requiredMonthlyDeposit(
            currentSavings: currentSavings,
            targetAmount: targetAmount,
            annualReturnRate: annualReturnRate,
            years: yearsToTarget
        )
        let fundingRatio = requiredDeposit > 0 ? min(monthlyDeposit / requiredDeposit, 1.5) : 1.5
        let fundingScore = min(30.0, fundingRatio * 20.0)
        
        // 2. Time Buffer (0–25 pts): Do you have margin in your timeline?
        let monthsNeeded = monthsToGoal(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit,
            annualReturnRate: annualReturnRate,
            targetAmount: targetAmount
        )
        let monthsAvailable = Int(yearsToTarget * 12)
        let timeBufferRatio: Double
        if let needed = monthsNeeded {
            timeBufferRatio = needed > 0 ? Double(monthsAvailable) / Double(needed) : 2.0
        } else {
            timeBufferRatio = 0
        }
        let timeScore = min(25.0, timeBufferRatio * 12.5)
        
        // 3. Inflation Shield (0–20 pts): Does return outpace inflation?
        let realReturn = annualReturnRate - annualInflationRate
        let inflationScore: Double
        if realReturn >= 4 { inflationScore = 20 }
        else if realReturn >= 2 { inflationScore = 15 }
        else if realReturn >= 0 { inflationScore = 8 }
        else { inflationScore = max(0, 5 + realReturn) }
        
        // 4. Compound Power (0–25 pts): How much work is compound interest doing?
        let fv = futureValue(currentSavings: currentSavings, monthlyDeposit: monthlyDeposit, annualReturnRate: annualReturnRate, years: yearsToTarget)
        let totalDeposited = currentSavings + monthlyDeposit * yearsToTarget * 12
        let compoundRatio = totalDeposited > 0 ? (fv - totalDeposited) / totalDeposited : 0
        let compoundScore = min(25.0, max(0, compoundRatio * 25.0))
        
        let overall = min(100, fundingScore + timeScore + inflationScore + compoundScore)
        
        // Status
        let status: HealthStatus
        if overall >= 80 { status = .excellent }
        else if overall >= 60 { status = .good }
        else if overall >= 40 { status = .fair }
        else if overall >= 20 { status = .atRisk }
        else { status = .critical }
        
        // Advice
        let advice: String
        if fundingScore < 15 {
            advice = "Consider increasing your monthly deposit or extending your timeline."
        } else if timeScore < 10 {
            advice = "Your timeline is tight. A small increase in deposits could add a safety buffer."
        } else if inflationScore < 10 {
            advice = "Your expected return barely outpaces inflation. Review your assumptions."
        } else if compoundScore < 10 {
            advice = "Starting earlier or increasing deposits will unlock more compound growth."
        } else {
            advice = "Your savings plan looks well-balanced. Stay consistent!"
        }
        
        return SavingsHealthReport(
            overall: overall,
            funding: fundingScore,
            timeBuffer: timeScore,
            inflationShield: inflationScore,
            compoundPower: compoundScore,
            status: status,
            advice: advice
        )
    }
    
    // MARK: - "Your Money Never Sleeps" — Daily Passive Earnings
    
    /// How much compound interest is earned per day at current balance
    static func dailyPassiveEarnings(
        currentBalance: Double,
        annualReturnRate: Double
    ) -> Double {
        let dailyRate = annualReturnRate / 100.0 / 365.0
        return currentBalance * dailyRate
    }
    
    // MARK: - Goal Achievability Status
    
    /// Returns whether the user is on track, ahead, or behind
    static func achievabilityStatus(
        currentSavings: Double,
        monthlyDeposit: Double,
        targetAmount: Double,
        annualReturnRate: Double,
        yearsToTarget: Double
    ) -> AchievabilityResult {
        let fv = futureValue(currentSavings: currentSavings, monthlyDeposit: monthlyDeposit, annualReturnRate: annualReturnRate, years: yearsToTarget)
        let ratio = targetAmount > 0 ? fv / targetAmount : 0
        
        let status: AchievabilityStatus
        let message: String
        
        if ratio >= 1.2 {
            status = .aheadOfSchedule
            let surplus = fv - targetAmount
            message = "You're projected to exceed your goal by \(Int(surplus))!"
        } else if ratio >= 1.0 {
            status = .onTrack
            message = "You're on track to reach your goal on time."
        } else if ratio >= 0.75 {
            status = .slightlyBehind
            let deficit = targetAmount - fv
            let extraNeeded = requiredMonthlyDeposit(currentSavings: currentSavings, targetAmount: targetAmount, annualReturnRate: annualReturnRate, years: yearsToTarget) - monthlyDeposit
            message = "You're \(Int(deficit)) short. Adding \(Int(max(0, extraNeeded)))/mo would close the gap."
        } else if ratio >= 0.5 {
            status = .behind
            let extraNeeded = requiredMonthlyDeposit(currentSavings: currentSavings, targetAmount: targetAmount, annualReturnRate: annualReturnRate, years: yearsToTarget) - monthlyDeposit
            message = "You need \(Int(max(0, extraNeeded))) more per month, or extend your timeline."
        } else {
            status = .significantlyBehind
            message = "Consider a longer timeline or a higher monthly deposit."
        }
        
        return AchievabilityResult(ratio: ratio, status: status, message: message)
    }
    
    // MARK: - Personalized Savings Insights
    
    /// Generate dynamic, personalized insights based on the user's savings parameters
    static func generateInsights(
        currentSavings: Double,
        monthlyDeposit: Double,
        targetAmount: Double,
        annualReturnRate: Double,
        annualInflationRate: Double,
        yearsToTarget: Double,
        userAge: Int
    ) -> [SavingsInsight] {
        var insights: [SavingsInsight] = []
        
        let fv = futureValue(currentSavings: currentSavings, monthlyDeposit: monthlyDeposit, annualReturnRate: annualReturnRate, years: yearsToTarget)
        let totalDeposited = currentSavings + monthlyDeposit * yearsToTarget * 12
        let compoundGain = fv - totalDeposited
        let compoundRatio = totalDeposited > 0 ? compoundGain / totalDeposited : 0
        
        // Rule of 72 insight
        if annualReturnRate > 0 {
            let doublingYears = 72.0 / annualReturnRate
            insights.append(SavingsInsight(
                id: "rule72",
                icon: "divide.circle.fill",
                title: "Money Doubles in ~\(Int(doublingYears)) Years",
                message: "At \(String(format: "%.1f%%", annualReturnRate)) return, your savings double approximately every \(Int(doublingYears)) years thanks to compound interest.",
                color: "growthGreen",
                priority: 2
            ))
        }
        
        // Compound interest doing more than deposits
        if compoundRatio > 1.0 {
            insights.append(SavingsInsight(
                id: "compound_power",
                icon: "sparkles",
                title: "Compound Interest Exceeds Your Deposits!",
                message: "By year \(Int(yearsToTarget)), compound interest contributes \(CurrencyHelper.formatCompact(compoundGain, currency: "USD")) — more than the \(CurrencyHelper.formatCompact(totalDeposited, currency: "USD")) you deposit yourself.",
                color: "neonBlue",
                priority: 1
            ))
        }
        
        // Real return check
        let realReturn = annualReturnRate - annualInflationRate
        if realReturn < 1 {
            insights.append(SavingsInsight(
                id: "inflation_warning",
                icon: "exclamationmark.triangle.fill",
                title: "Inflation Is Catching Up",
                message: "Your real return is only \(String(format: "%.1f%%", realReturn)). Consider if your expected return assumption adequately outpaces inflation.",
                color: "orange",
                priority: 1
            ))
        } else if realReturn >= 4 {
            insights.append(SavingsInsight(
                id: "inflation_shield",
                icon: "shield.fill",
                title: "Strong Inflation Protection",
                message: "Your \(String(format: "%.1f%%", realReturn)) real return provides a solid buffer against inflation erosion.",
                color: "growthGreen",
                priority: 3
            ))
        }
        
        // Starting early advantage
        let retirementAge = 65
        let yearsToRetirement = max(0, retirementAge - userAge)
        if userAge < 35 {
            let fvRetirement = futureValue(currentSavings: currentSavings, monthlyDeposit: monthlyDeposit, annualReturnRate: annualReturnRate, years: Double(yearsToRetirement))
            insights.append(SavingsInsight(
                id: "early_start",
                icon: "clock.fill",
                title: "Time Is On Your Side",
                message: "With \(yearsToRetirement) years until 65, your \(CurrencyHelper.format(monthlyDeposit, currency: "USD"))/month could grow to \(CurrencyHelper.formatCompact(fvRetirement, currency: "USD")). Starting early is your biggest advantage.",
                color: "purple",
                priority: 2
            ))
        }
        
        // Small increase impact
        let extraMonthly = 50.0
        let impactResult = incrementalImpact(
            currentSavings: currentSavings,
            baseMonthlyDeposit: monthlyDeposit,
            additionalMonthly: extraMonthly,
            annualReturnRate: annualReturnRate,
            annualInflationRate: annualInflationRate,
            years: yearsToTarget
        )
        if impactResult.extraGain > extraMonthly * 12 * yearsToTarget * 1.5 {
            insights.append(SavingsInsight(
                id: "small_boost",
                icon: "plus.circle.fill",
                title: "A Little Goes a Long Way",
                message: "Adding just \(CurrencyHelper.format(extraMonthly, currency: "USD")) more per month would generate an extra \(CurrencyHelper.formatCompact(impactResult.extraGain, currency: "USD")) by your goal date.",
                color: "growthGreen",
                priority: 2
            ))
        }
        
        // Daily earnings milestone
        let dailyEarnings = dailyPassiveEarnings(currentBalance: fv, annualReturnRate: annualReturnRate)
        if dailyEarnings > 10 {
            insights.append(SavingsInsight(
                id: "daily_earnings",
                icon: "moon.stars.fill",
                title: "Earning \(CurrencyHelper.format(dailyEarnings, currency: "USD")) Per Day Passively",
                message: "At your projected balance, your money earns \(CurrencyHelper.format(dailyEarnings, currency: "USD")) per day in compound interest — even while you sleep.",
                color: "purple",
                priority: 3
            ))
        }
        
        // Savings rate insight
        if monthlyDeposit > 0 {
            let savingsRateEstimate = (monthlyDeposit / (monthlyDeposit * 3)) * 100 // rough estimate assuming 1/3 saved
            if savingsRateEstimate > 25 {
                insights.append(SavingsInsight(
                    id: "strong_saver",
                    icon: "star.fill",
                    title: "Consistent Saver",
                    message: "Your regular monthly deposit of \(CurrencyHelper.format(monthlyDeposit, currency: "USD")) shows strong savings discipline — the most important factor in building long-term wealth.",
                    color: "goalGold",
                    priority: 3
                ))
            }
        }
        
        return insights.sorted { $0.priority < $1.priority }
    }
    
    // MARK: - Compound Interest Breakdown for Year Table
    
    /// Returns detailed year-by-year breakdown
    static func yearlyBreakdown(
        currentSavings: Double,
        monthlyDeposit: Double,
        annualReturnRate: Double,
        annualInflationRate: Double,
        totalYears: Int
    ) -> [YearBreakdownRow] {
        var rows: [YearBreakdownRow] = []
        let monthlyRate = annualReturnRate / 100.0 / 12.0
        var balance = currentSavings
        var totalInterestEarned: Double = 0
        
        for year in 1...totalYears {
            let startBalance = balance
            var yearInterest: Double = 0
            
            for _ in 0..<12 {
                let interest = balance * monthlyRate
                yearInterest += interest
                balance = balance + interest + monthlyDeposit
            }
            
            totalInterestEarned += yearInterest
            let totalDeposited = currentSavings + monthlyDeposit * Double(year) * 12
            let rv = realValue(futureValue: balance, annualInflationRate: annualInflationRate, years: Double(year))
            let daily = dailyPassiveEarnings(currentBalance: balance, annualReturnRate: annualReturnRate)
            
            rows.append(YearBreakdownRow(
                year: year,
                startBalance: startBalance,
                depositsThisYear: monthlyDeposit * 12,
                interestThisYear: yearInterest,
                endBalance: balance,
                totalInterest: totalInterestEarned,
                totalDeposited: totalDeposited,
                realValue: rv,
                dailyEarnings: daily
            ))
        }
        
        return rows
    }
}

// MARK: - Data Models

struct SavingsHealthReport {
    let overall: Double // 0–100
    let funding: Double
    let timeBuffer: Double
    let inflationShield: Double
    let compoundPower: Double
    let status: HealthStatus
    let advice: String
}

enum HealthStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case atRisk = "At Risk"
    case critical = "Critical"
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.shield.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "equal.circle.fill"
        case .atRisk: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

enum AchievabilityStatus {
    case aheadOfSchedule, onTrack, slightlyBehind, behind, significantlyBehind
    
    var label: String {
        switch self {
        case .aheadOfSchedule: return "AHEAD"
        case .onTrack: return "ON TRACK"
        case .slightlyBehind: return "SLIGHTLY BEHIND"
        case .behind: return "BEHIND"
        case .significantlyBehind: return "NEEDS ATTENTION"
        }
    }
    
    var icon: String {
        switch self {
        case .aheadOfSchedule: return "arrow.up.right.circle.fill"
        case .onTrack: return "checkmark.circle.fill"
        case .slightlyBehind: return "arrow.right.circle.fill"
        case .behind: return "arrow.down.right.circle.fill"
        case .significantlyBehind: return "exclamationmark.circle.fill"
        }
    }
}

struct AchievabilityResult {
    let ratio: Double
    let status: AchievabilityStatus
    let message: String
}

struct YearBreakdownRow: Identifiable {
    let id = UUID()
    let year: Int
    let startBalance: Double
    let depositsThisYear: Double
    let interestThisYear: Double
    let endBalance: Double
    let totalInterest: Double
    let totalDeposited: Double
    let realValue: Double
    let dailyEarnings: Double
}

struct GrowthPoint: Identifiable {
    let id = UUID()
    let month: Int
    let year: Double
    let nominalValue: Double
    let realValue: Double
    let totalDeposited: Double
}

struct IncrementalResult {
    let baseValue: Double
    let boostedValue: Double
    let extraGain: Double
    let extraGainReal: Double
    let totalExtraDeposited: Double
    let compoundBonus: Double
}

struct Strategy: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let annualReturn: Double
    let icon: String
    let color: String // Will be mapped to Color in views
}

struct StrategyResult: Identifiable {
    let id = UUID()
    let strategy: Strategy
    let futureValue: Double
    let realValue: Double
}

struct YearMilestone: Identifiable {
    let id = UUID()
    let year: Int
    let yearsFromNow: Int
    let balance: Double
    let realBalance: Double
    let progress: Double
    let goalReached: Bool
}

struct SavingsInsight: Identifiable {
    let id: String
    let icon: String
    let title: String
    let message: String
    let color: String // Maps to AppTheme.Colors
    let priority: Int // 1 = highest
}
