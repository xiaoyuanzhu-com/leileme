import SwiftUI
import SwiftData

struct HistoryTab: View {
    @Query(sort: \DailyAssessment.date, order: .reverse)
    private var assessments: [DailyAssessment]

    var body: some View {
        NavigationStack {
            Group {
                if assessments.isEmpty {
                    emptyState
                } else {
                    assessmentList
                }
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Assessments Yet", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Complete your first daily assessment to start tracking trends.")
        }
    }

    // MARK: - Assessment List

    private var assessmentList: some View {
        List {
            Section {
                TrendChartView(assessments: assessments)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            } header: {
                Label("Trends", systemImage: "chart.xyaxis.line")
            }

            Section {
                ForEach(assessments) { assessment in
                    NavigationLink(destination: HistoryDetailView(assessment: assessment, allAssessments: assessments)) {
                        AssessmentRow(assessment: assessment)
                    }
                }
            } header: {
                Label("Past Assessments", systemImage: "calendar")
            }
        }
    }
}

// MARK: - Assessment Row

private struct AssessmentRow: View {
    let assessment: DailyAssessment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(relativeDateLabel(for: assessment.date))
                .font(.headline)
            Text(summaryText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
