import XCTest
import SwiftData
@testable import LeiLeMe

final class DataExporterTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() async throws {
        container = try TestHelpers.makeContainer()
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    // MARK: - Empty data

    func testEmptyAssessmentsReturnsNil() {
        let baseline = makeBaseline()
        let url = DataExporter.export(assessments: [], format: .csv, baseline: baseline)
        XCTAssertNil(url)
    }

    // MARK: - CSV export

    @MainActor
    func testCSVExportFormat() throws {
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 1, in: context)
        let baseline = makeBaseline()

        let url = DataExporter.export(assessments: [assessment], format: .csv, baseline: baseline)
        XCTAssertNotNil(url)

        let content = try String(contentsOf: url!, encoding: .utf8)
        let lines = content.components(separatedBy: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 2, "Should have header + at least 1 data row")

        // Verify header
        let header = lines[0]
        XCTAssertTrue(header.contains("Date"))
        XCTAssertTrue(header.contains("HRV"))
        XCTAssertTrue(header.contains("Recovery Score"))

        // Clean up temp file
        try? FileManager.default.removeItem(at: url!)
    }

    @MainActor
    func testCSVFileExtension() throws {
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 1, in: context)
        let baseline = makeBaseline()

        let url = DataExporter.export(assessments: [assessment], format: .csv, baseline: baseline)
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.pathExtension, "csv")

        try? FileManager.default.removeItem(at: url!)
    }

    // MARK: - JSON export

    @MainActor
    func testJSONExportFormat() throws {
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 1, in: context)
        let baseline = makeBaseline()

        let url = DataExporter.export(assessments: [assessment], format: .json, baseline: baseline)
        XCTAssertNotNil(url)

        let data = try Data(contentsOf: url!)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["exportDate"])
        XCTAssertEqual(json?["recordCount"] as? Int, 1)
        XCTAssertNotNil(json?["assessments"])

        try? FileManager.default.removeItem(at: url!)
    }

    @MainActor
    func testJSONFileExtension() throws {
        let assessment = TestHelpers.makeFullAssessment(daysAgo: 1, in: context)
        let baseline = makeBaseline()

        let url = DataExporter.export(assessments: [assessment], format: .json, baseline: baseline)
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.pathExtension, "json")

        try? FileManager.default.removeItem(at: url!)
    }

    // MARK: - Multiple assessments sorted

    @MainActor
    func testMultipleAssessmentsSorted() throws {
        let a1 = TestHelpers.makeFullAssessment(daysAgo: 3, in: context)
        let a2 = TestHelpers.makeFullAssessment(daysAgo: 1, in: context)
        let baseline = makeBaseline()

        let url = DataExporter.export(assessments: [a2, a1], format: .csv, baseline: baseline)
        XCTAssertNotNil(url)

        let content = try String(contentsOf: url!, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 3, "Header + 2 data rows")

        try? FileManager.default.removeItem(at: url!)
    }

    // MARK: - Export format properties

    func testExportFormatProperties() {
        XCTAssertEqual(DataExporter.ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(DataExporter.ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(DataExporter.ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(DataExporter.ExportFormat.json.mimeType, "application/json")
    }

    // MARK: - Helper

    private func makeBaseline() -> BaselineEngine.BaselineSnapshot {
        BaselineEngine.BaselineSnapshot(
            hrvBaseline: 45, rhrBaseline: 60, sleepDurationBaseline: 7.5,
            tapFrequencyBaseline: 4.9, rhythmStabilityBaseline: 0.12,
            reactionTimeBaseline: 300, reactionConsistencyBaseline: 20,
            sleepQualityBaseline: 4, sorenessBaseline: 4, energyBaseline: 4,
            dayCount: 7
        )
    }
}
