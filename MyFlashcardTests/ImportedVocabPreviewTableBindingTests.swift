import XCTest
@testable import MyFlashcardR

final class ImportedVocabPreviewTableBindingTests: XCTestCase {

    func testPreviewRowBindsGermanColumnFromGermanProperty() {
        let entry = ImportedVocabEntry(
            english_word: "book",
            feature: "booked",
            german: "buchen",
            persian: "رزرو کردن",
            example_sentence: "I booked a table for dinner.",
            persian_translation: "من یک میز برای شام رزرو کردم."
        )

        let row = ImportedVocabPreviewRow(entry: entry)

        XCTAssertEqual(row.englishWord, "book")
        XCTAssertEqual(row.feature, "booked")
        XCTAssertEqual(row.german, "buchen")
        XCTAssertNotEqual(row.german, "booked")
        XCTAssertNotEqual(row.german, "high")
        XCTAssertEqual(row.persian, "رزرو کردن")
    }
}
