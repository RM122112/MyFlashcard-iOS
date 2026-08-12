import XCTest
@testable import MyFlashcardR

final class ImportedVocabImportTests: XCTestCase {

    func testBaseImportMapsAllFieldsCorrectly() throws {
        let data = Data(Self.normalJSON.utf8)
        let entries = try VocabJSONImportService.shared.importVocab(from: data)

        XCTAssertEqual(entries.count, 4)

        XCTAssertEqual(entries[0].english_word, "book")
        XCTAssertEqual(entries[0].feature, "booked")
        XCTAssertEqual(entries[0].german, "buchen")
        XCTAssertEqual(entries[0].persian, "رزرو کردن")
        XCTAssertEqual(entries[0].example_sentence, "I booked a table for dinner.")
        XCTAssertEqual(entries[0].persian_translation, "من یک میز برای شام رزرو کردم.")

        XCTAssertEqual(entries[1].english_word, "learn")
        XCTAssertEqual(entries[1].feature, "learned")
        XCTAssertEqual(entries[1].german, "lernen")

        XCTAssertEqual(entries[2].english_word, "buy")
        XCTAssertEqual(entries[2].feature, "bought")
        XCTAssertEqual(entries[2].german, "kaufen")

        XCTAssertEqual(entries[3].english_word, "smart")
        XCTAssertEqual(entries[3].feature, "dumb")
        XCTAssertEqual(entries[3].german, "klug")
    }

    func testAntiShiftImportWithShuffledKeysStillMapsByKey() throws {
        let data = Data(Self.shuffledJSON.utf8)
        let entries = try VocabJSONImportService.shared.importVocab(from: data)

        XCTAssertEqual(entries.count, 2)

        XCTAssertEqual(entries[0].english_word, "book")
        XCTAssertEqual(entries[0].feature, "booked")
        XCTAssertEqual(entries[0].german, "buchen")
        XCTAssertEqual(entries[0].persian, "رزرو کردن")
        XCTAssertEqual(entries[0].example_sentence, "I booked a table for dinner.")
        XCTAssertEqual(entries[0].persian_translation, "من یک میز برای شام رزرو کردم.")

        XCTAssertEqual(entries[1].english_word, "learn")
        XCTAssertEqual(entries[1].feature, "learned")
        XCTAssertEqual(entries[1].german, "lernen")
        XCTAssertEqual(entries[1].persian, "یاد گرفتن")
        XCTAssertEqual(entries[1].example_sentence, "She learned Spanish last year.")
        XCTAssertEqual(entries[1].persian_translation, "او سال گذشته اسپانیایی یاد گرفت.")
    }

    func testFeatureNullOrEmptyIsNormalizedToUnderscore() {
        let json = """
        [
          {
            "english_word":"book",
            "feature":"",
            "german":"buchen",
            "persian":"رزرو کردن",
            "example_sentence":"I booked a table for dinner.",
            "persian_translation":"من یک میز برای شام رزرو کردم."
          },
          {
            "english_word":"learn",
            "feature":null,
            "german":"lernen",
            "persian":"یاد گرفتن",
            "example_sentence":"She learned Spanish last year.",
            "persian_translation":"او سال گذشته اسپانیایی یاد گرفت."
          }
        ]
        """

        let report = VocabJSONImportService.shared.importVocabWithReport(
            from: Data(json.utf8),
            duplicateStrategy: .skip
        )

        XCTAssertEqual(report.entries.count, 2)
        XCTAssertEqual(report.entries[0].feature, "_")
        XCTAssertEqual(report.entries[1].feature, "_")
    }

    private static let normalJSON = """
    [
      {
        "english_word":"book",
        "feature":"booked",
        "german":"buchen",
        "persian":"رزرو کردن",
        "example_sentence":"I booked a table for dinner.",
        "persian_translation":"من یک میز برای شام رزرو کردم."
      },
      {
        "english_word":"learn",
        "feature":"learned",
        "german":"lernen",
        "persian":"یاد گرفتن",
        "example_sentence":"She learned Spanish last year.",
        "persian_translation":"او سال گذشته اسپانیایی یاد گرفت."
      },
      {
        "english_word":"buy",
        "feature":"bought",
        "german":"kaufen",
        "persian":"خریدن",
        "example_sentence":"He bought a new phone.",
        "persian_translation":"او یک گوشی جدید خرید."
      },
      {
        "english_word":"smart",
        "feature":"dumb",
        "german":"klug",
        "persian":"باهوش",
        "example_sentence":"My sister is very smart.",
        "persian_translation":"خواهرم خیلی باهوش است."
      }
    ]
    """

    private static let shuffledJSON = """
    [
      {
        "german":"buchen",
        "persian":"رزرو کردن",
        "feature":"booked",
        "persian_translation":"من یک میز برای شام رزرو کردم.",
        "english_word":"book",
        "example_sentence":"I booked a table for dinner."
      },
      {
        "feature":"learned",
        "german":"lernen",
        "english_word":"learn",
        "persian_translation":"او سال گذشته اسپانیایی یاد گرفت.",
        "example_sentence":"She learned Spanish last year.",
        "persian":"یاد گرفتن"
      }
    ]
    """
}
