import SwiftUI
import SwiftData

struct HistoryTab: View {
    @Query(sort: \DailyAssessment.date, order: .reverse)
    private var assessments: [DailyAssessment]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceBackground
                    .ignoresSafeArea()

                Group {
                    if assessments.isEmpty {
                        emptyState
                    } else {
                        assessmentList
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.wellnessTeal.opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.wellnessTeal.opacity(0.6))
            }

            Text("No Assessments Yet")
                .font(.title3.bold())

            Text("Complete your first daily assessment\nto start tracking trends.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Assessment List

    private var assessmentList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Trends section
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ThemedSectionHeader(title: "Trends", icon: "chart.xyaxis.line")
                        .padding(.horizontal, AppSpacing.md)

                    TrendChartView(assessments: assessments)
                        .cardStyle()
                }
                .padding(.horizontal, AppSpacing.md)

                // Past assessments section
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ThemedSectionHeader(title: "Past Assessments", icon: "calendar")
                        .padding(.horizontal, AppSpacing.md)

                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(assessments) { assessment in
                            NavigationLink(destination: HistoryDetailView(assessment: assessment, allAssessments: assessments)) {
                                AssessmentRow(assessment: assessment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
    }
}

// MARK: - Assessment Row

private struct AssessmentRow: View {
    let assessment: DailyAssessment

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Date badge
            VStack(spacing: 2) {
                Text(dayLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(dayNumber)
                    .font(.title3.bold())
                    .foregroundStyle(Color.wellnessTeal)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(relativeDateLabel(for: assessment.date))
                    .font(.headline)
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .cardStyle()
    }

    private var dayLabel: String {
        assessment.date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    private var dayNumber: String {
        assessment.date.formatted(.dateTime.day())
    }

    private var summaryText: String {
        var parts: [String] = []
        if assessment.healthKitData != nil { parts.append("HealthKit") }
        if assessment.tapTestResult != nil { parts.append("Tap Test") }
        if assessment.reactionTimeResult != nil { parts.append("Reaction") }
        if assessment.subjectiveAssessment != nil { parts.append("Subjective") }
        if parts.isEmpty { return "No data recorded" }
        return "\(parts.count) dimension\(parts.count == 1 ? "" : "s"): \(parts.joined(separator: ", "))"
    }

    private func relativeDateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        }
    }
}

#Preview {
    HistoryTab()
        .modelContainer(for: DailyAssessment.self, inMemory: true)
}
