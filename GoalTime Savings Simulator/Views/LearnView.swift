import SwiftUI

// MARK: - Learn & Explore: Educational Financial Content

struct LearnView: View {
    @State private var expandedArticle: String? = nil
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerCard
                    
                    ForEach(articles) { article in
                        articleCard(article)
                    }
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.Colors.neonBlue)
                .glow(AppTheme.Colors.neonBlue, radius: 10)
            
            Text("Financial Concepts")
                .font(AppTheme.Typography.title(22))
            
            Text("Understanding these fundamentals will help you make better decisions about your savings.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    // MARK: - Article Card
    
    private func articleCard(_ article: EducationalArticle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if expandedArticle == article.id {
                        expandedArticle = nil
                    } else {
                        expandedArticle = article.id
                    }
                }
                HapticManager.shared.light()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: article.icon)
                        .font(.title2)
                        .foregroundStyle(article.color)
                        .frame(width: 40, height: 40)
                        .background(article.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(article.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(article.subtitle)
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(.secondary)
                            .lineLimit(expandedArticle == article.id ? nil : 1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: expandedArticle == article.id ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            
            // Expanded content
            if expandedArticle == article.id {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    ForEach(article.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            if !section.heading.isEmpty {
                                Text(section.heading)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(article.color)
                            }
                            
                            Text(section.body)
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                    }
                    
                    // Key takeaway
                    if let takeaway = article.keyTakeaway {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(AppTheme.Colors.goalGold)
                                .font(.subheadline)
                            
                            Text(takeaway)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .background(AppTheme.Colors.goalGold.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Formula if available
                    if let formula = article.formula {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Formula")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            
                            Text(formula)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(AppTheme.Colors.neonBlue)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.Colors.neonBlue.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // Example if available
                    if let example = article.example {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Example")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            
                            Text(example)
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                                .padding(12)
                                .background(AppTheme.Colors.growthGreen.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title). \(article.subtitle)")
        .accessibilityHint(expandedArticle == article.id ? "Double tap to collapse" : "Double tap to expand")
    }
    
    // MARK: - Articles Data
    
    private var articles: [EducationalArticle] {
        [
            EducationalArticle(
                id: "compound_interest",
                title: "Compound Interest",
                subtitle: "The \"eighth wonder of the world\" — how your money grows on itself",
                icon: "chart.line.uptrend.xyaxis",
                color: AppTheme.Colors.neonBlue,
                sections: [
                    ArticleSection(heading: "What Is It?", body: "Compound interest means you earn interest not only on your initial deposit, but also on all the interest you've already earned. Over time, this creates exponential growth — your money starts earning money on its own."),
                    ArticleSection(heading: "Simple vs. Compound", body: "With simple interest, $10,000 at 7% earns $700 every year — always $700. With compound interest, you earn $700 the first year, then $749 the next (7% of $10,700), then $801.43, and so on. The difference grows dramatically over decades."),
                    ArticleSection(heading: "Why Time Matters", body: "The power of compounding accelerates over time. In the first few years, the effect is modest. But after 20-30 years, compound interest can generate more growth than your actual deposits. This is why starting early is so important."),
                ],
                keyTakeaway: "The earlier you start, the more time compound interest has to work for you. Even small amounts invested consistently can grow into substantial sums over decades.",
                formula: "FV = P × ((1 + r)ⁿ - 1) / r × (1 + r)",
                example: "If you save $500/month at 7% annual return for 30 years, you'll deposit $180,000 total. But compound interest adds approximately $427,000 — more than double your deposits! Your final balance: ~$607,000."
            ),
            
            EducationalArticle(
                id: "rule_of_72",
                title: "The Rule of 72",
                subtitle: "A quick mental shortcut to estimate how fast your money doubles",
                icon: "divide.circle.fill",
                color: AppTheme.Colors.growthGreen,
                sections: [
                    ArticleSection(heading: "The Concept", body: "The Rule of 72 is a simple way to estimate how long it takes for an investment to double in value. Just divide 72 by the annual rate of return."),
                    ArticleSection(heading: "How It Works", body: "At 6% annual return, your money doubles in approximately 72 ÷ 6 = 12 years. At 8%, it doubles in about 9 years. At 12%, roughly 6 years. This works reasonably well for rates between 2% and 20%."),
                    ArticleSection(heading: "Applying It to Inflation", body: "The Rule of 72 also works in reverse for inflation. At 3% inflation, the purchasing power of your money is cut in half in 72 ÷ 3 = 24 years. This shows why keeping money in a zero-interest account is actually losing value."),
                ],
                keyTakeaway: "Use this mental shortcut: 72 ÷ rate = years to double. It works for both growth (returns) and erosion (inflation).",
                formula: "Doubling Time ≈ 72 / Annual Rate (%)",
                example: "At a 7% return, your investment doubles in ~10.3 years. So $10,000 becomes $20,000 in ~10 years, $40,000 in ~20 years, and $80,000 in ~30 years."
            ),
            
            EducationalArticle(
                id: "inflation",
                title: "Understanding Inflation",
                subtitle: "Why a dollar today isn't the same as a dollar tomorrow",
                icon: "flame.fill",
                color: AppTheme.Colors.orange,
                sections: [
                    ArticleSection(heading: "What Is Inflation?", body: "Inflation is the gradual increase in prices over time. When inflation is 3%, something that costs $100 today will cost $103 next year. Over decades, this effect compounds and can significantly reduce your purchasing power."),
                    ArticleSection(heading: "Real vs. Nominal Returns", body: "Your nominal return is the raw percentage your investment earns. Your real return is what's left after subtracting inflation. If you earn 7% but inflation is 3%, your real return is approximately 4%. This is the actual increase in your purchasing power."),
                    ArticleSection(heading: "Why It Matters for Savings Goals", body: "If you're saving for a goal 20 years away, the cost of that goal will likely be much higher due to inflation. A $100,000 goal today might cost $180,000 in 20 years at 3% inflation. Your savings plan needs to account for this."),
                ],
                keyTakeaway: "Always think in real (inflation-adjusted) terms. A savings plan that doesn't beat inflation is actually losing purchasing power, even if the balance grows.",
                formula: "Real Return ≈ Nominal Return − Inflation Rate",
                example: "At 3% inflation, $100,000 today is equivalent to just $55,368 in purchasing power after 20 years. You'd need $180,611 in future dollars to buy what $100,000 buys today."
            ),
            
            EducationalArticle(
                id: "starting_early",
                title: "The Power of Starting Early",
                subtitle: "Why time is your greatest asset in building wealth",
                icon: "clock.fill",
                color: AppTheme.Colors.purple,
                sections: [
                    ArticleSection(heading: "Time vs. Amount", body: "It's often more impactful to start saving early with a small amount than to start later with a large amount. Someone who saves $200/month from age 25 will often accumulate more than someone who saves $400/month starting at age 35."),
                    ArticleSection(heading: "The Cost of Waiting", body: "Every year you delay saving has a compounding cost. Waiting 5 years to start doesn't just cost you 5 years of deposits — it costs you 5 years of compound growth on ALL future deposits as well. The later years of compounding are the most powerful."),
                    ArticleSection(heading: "Consistency Matters", body: "Regular, consistent contributions matter more than trying to time markets or make perfect investment choices. The discipline of saving a fixed amount every month — regardless of market conditions — is one of the most reliable paths to building wealth."),
                ],
                keyTakeaway: "The best time to start saving was yesterday. The second best time is today. Even small, consistent amounts can grow into significant sums thanks to compound interest.",
                formula: nil,
                example: "Alice starts saving $300/month at age 25 and stops at 35 (10 years, $36,000 total). Bob starts at 35 and saves $300/month until 65 (30 years, $108,000 total). At 7% return, Alice ends up with more at age 65 (~$522,000 vs ~$340,000) — despite investing only 1/3 as much!"
            ),
            
            EducationalArticle(
                id: "savings_rate",
                title: "Savings Rate & Financial Independence",
                subtitle: "How the percentage you save matters more than the amount",
                icon: "percent",
                color: AppTheme.Colors.goalGold,
                sections: [
                    ArticleSection(heading: "What Is Savings Rate?", body: "Your savings rate is the percentage of your income that you save and invest. If you earn $5,000/month and save $1,000, your savings rate is 20%. This single number is one of the most important indicators of financial health."),
                    ArticleSection(heading: "Why Percentage Matters", body: "Saving a fixed dollar amount doesn't scale with your life. As income grows, keeping the same percentage ensures your savings grow proportionally. A 20% savings rate at any income level builds wealth faster than a fixed amount."),
                    ArticleSection(heading: "The Impact of Higher Savings Rates", body: "At a 10% savings rate, you'd need roughly 51 years of work to retire. At 20%, about 37 years. At 30%, about 28 years. At 50%, only 17 years. Small increases in your savings rate can shave years off your timeline."),
                ],
                keyTakeaway: "Focus on your savings rate, not just the dollar amount. Increasing your savings rate by even 5% can dramatically accelerate your timeline to financial goals.",
                formula: "Savings Rate = (Monthly Savings / Monthly Income) × 100",
                example: "If you earn $4,000/month after tax and save $800, your savings rate is 20%. Increasing it to 25% ($1,000/month) adds just $200/month but can reach your goals years sooner thanks to compound growth."
            ),
            
            EducationalArticle(
                id: "diversification",
                title: "Risk & Return Tradeoffs",
                subtitle: "Understanding the relationship between risk and potential returns",
                icon: "scale.3d",
                color: AppTheme.Colors.alertRed,
                sections: [
                    ArticleSection(heading: "Risk-Return Spectrum", body: "Generally, higher potential returns come with higher risk. Savings accounts offer safety but low returns (~1-2%). Bonds offer moderate returns (~3-5%). Stocks have historically returned ~7-10% long-term but with significant short-term volatility."),
                    ArticleSection(heading: "Time Horizon and Risk", body: "Your time horizon significantly affects how much risk you can tolerate. With 30+ years until your goal, short-term market drops are less concerning because you have time to recover. With a 5-year goal, more conservative assumptions are prudent."),
                    ArticleSection(heading: "Simulation vs. Reality", body: "This simulator uses fixed annual return rates for educational purposes. In reality, returns vary year to year and can be negative. The projections show potential outcomes based on the average rates you input, not guaranteed results."),
                ],
                keyTakeaway: "Higher return assumptions in this simulator represent higher-risk scenarios. Use conservative estimates for safer planning, and aggressive estimates to see best-case scenarios. Reality will likely fall somewhere in between.",
                formula: nil,
                example: "A conservative 3% return projection gives you a reliable baseline. A moderate 6-7% projection reflects historical stock market averages. An aggressive 10%+ projection shows what's possible but less certain."
            ),
        ]
    }
}

// MARK: - Data Models

struct EducationalArticle: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let sections: [ArticleSection]
    let keyTakeaway: String?
    let formula: String?
    let example: String?
}

struct ArticleSection: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}

#Preview {
    NavigationStack {
        LearnView()
    }
}
