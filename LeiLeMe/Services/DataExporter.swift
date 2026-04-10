import Foundation

/// Exports DailyAssessment data to CSV or JSON format.
struct DataExporter {

    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"

        var id: String { rawValue }

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }

        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            }
        }
    }

    // MARK: - Public

    /// Export assessments in the given format. Returns a temporary file URL.
    /// Returns nil if assessments is empty.
    static func export(
        assessments: [DailyAssessment],
        format: ExportFormat,
        baseline: BaselineEngine.BaselineSnapshot
    ) -> URL? {
        guard !assessments.isEmpty else { return nil }

        let sorted = assessments.sorted { $0.date < $1.date }

        let content: String
        switch format {
        case .csv:
            content = generateCSV(from: sorted, baseline: baseline)
        case .json:
            content = generateJSON(from: sorted, baseline: baseline)
        }

        return writeToTempFile(content: content, format: format)
    }

    // MARK: - CSV

    private static func generateCSV(
        from assessments: [DailyAssessment],
        baseline: BaselineEngine.BaselineSnapshot
    ) -> String {
        let headers = [
            "Date",
            "HRV (SDNN) [ms]",
            "Resting Heart Rate [bpm]",
            "Sleep Duration [hrs]",
            "Tap Frequency [taps/s]",
            "Tap Stability [cv]",
            "Reaction Time [ms]",
            "Sleep Quality [1-5]",
            "Muscle Soreness [1-5]",
            "Energy Level [1-5]",
            "Recovery Score [0-120]"
        ]

        var lines: [String] = []
        lines.append(headers.joined(separator: ","))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for assessment in assessments {
            let recovery = RecoveryScoreEngine.evaluate(
                assessment: assessment,
                baseline: baseline
            )

            var row: [String] = []
            row.append(dateFormatter.string(from: assessment.date))

            for measure in Measure.allCases {
                if let value = assessment.value(for: measure) {
                    row.append(formatValue(value, for: measure))
                } else {
                    row.append("")
                }
            }

            // Recovery score (only if available dimensions > 0)
            if recovery.availableDimensions > 0 {
                row.append(String(format: "%.1f", recovery.score))
            } else {
                row.append("")
            }

            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - JSON

    private static func generateJSON(
        from assessments: [DailyAssessment],
        baseline: BaselineEngine.BaselineSnapshot
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let records: [[String: Any]] = assessments.map { assessment in
            let recovery = RecoveryScoreEngine.evaluate(
                assessment: assessment,
                baseline: baseline
            )

            var record: [String: Any] = [
                "date": dateFormatter.string(from: assessment.date)
            ]

            var measures: [String: Any] = [:]
            for measure in Measure.allCases {
                if let value = assessment.value(for: measure) {
                    measures[measure.rawValue] = Double(formatValue(value, for: measure))
                }
            }
            record["measures"] = measures

            if recovery.availableDimensions > 0 {
                record["recoveryScore"] = Double(String(format: "%.1f", recovery.score))
            }

            return record
        }

        let wrapper: [String: Any] = [
            "exportDate": dateFormatter.string(from: Date()),
            "recordCount": assessments.count,
            "assessments": records
        ]

        guard let data = try? JSONSerialization.data(
            withJSONObject: wrapper,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return "{}"
        }

        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Helpers

    private static func formatValue(_ value: Double, for measure: Measure) -> String {
        String(format: measure.formatString, value)
    }

    private static func writeToTempFile(content: String, format: ExportFormat) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let fileName = "LeiLeMe-export-\(dateString).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
}
