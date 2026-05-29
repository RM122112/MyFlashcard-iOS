import Foundation

/// Grammar Database with all rules
struct GrammarDatabase {

    static let allRules: [GrammarRule] = [

        // MARK: - 1. Present Simple
        GrammarRule(
            category: .tenses,
            title: "Present Simple",
            titleGerman: "Präsens (Einfache Gegenwart)",
            titlePersian: "زمان حال ساده",
            explanation: "Used for habits, routines, repeated actions, facts and general truths.",
            explanationGerman: "Wird für Gewohnheiten, wiederholte Handlungen, Fakten und allgemeine Wahrheiten verwendet.",
            explanationPersian: "برای بیان کارهایی است که بطور تکراری انجام می شود.",
            formula: "Subject + base verb (+ s/es for he/she/it)",
            examples: [
                GrammarExample(english: "I write a letter every day.", german: "Ich schreibe jeden Tag einen Brief.", persian: "من هر روز یک نامه می‌نویسم."),
                GrammarExample(english: "She writes a letter every day.", german: "Sie schreibt jeden Tag einen Brief.", persian: "او هر روز یک نامه می‌نویسد."),
                GrammarExample(english: "They don't write a letter every day.", german: "Sie schreiben nicht jeden Tag einen Brief.", persian: "آنها هر روز یک نامه نمی‌نویسند."),
                GrammarExample(english: "Does he write a letter every day?", german: "Schreibt er jeden Tag einen Brief?", persian: "آیا او هر روز یک نامه می‌نویسد؟"),
                GrammarExample(english: "He go to school.", isCorrect: false, correction: "He goes to school.")
            ],
            tips: ["Add -s/-es for he/she/it", "Negation: do/does + not", "Question: Do/Does + subject + verb", "Time words: always, usually, often, every day"]
        ),

        // MARK: - 2. Present Continuous
        GrammarRule(
            category: .tenses,
            title: "Present Continuous",
            titleGerman: "Präsens Verlaufsform",
            titlePersian: "زمان حال استمراری",
            explanation: "Used for actions happening right now or around the present moment.",
            explanationGerman: "Wird für Handlungen verwendet, die gerade jetzt geschehen.",
            explanationPersian: "برای بیان کارهایی است که همین حالا دارد انجام می شود.",
            formula: "Subject + am/is/are + verb-ing",
            examples: [
                GrammarExample(english: "I am writing a letter now.", german: "Ich schreibe jetzt einen Brief.", persian: "من اکنون دارم یک نامه می‌نویسم."),
                GrammarExample(english: "She is writing a letter now.", german: "Sie schreibt jetzt einen Brief.", persian: "او اکنون دارد یک نامه می‌نویسد."),
                GrammarExample(english: "We are not writing a letter now.", german: "Wir schreiben jetzt keinen Brief.", persian: "ما اکنون در حال نوشتن نامه نیستیم."),
                GrammarExample(english: "Are they writing a letter now?", german: "Schreiben sie jetzt einen Brief?", persian: "آیا آنها اکنون دارند یک نامه می‌نویسند؟"),
                GrammarExample(english: "She is work now.", isCorrect: false, correction: "She is working now.")
            ],
            tips: ["Use am/is/are + ing", "Signal words: now, at the moment, currently, look!, listen!", "Not used with stative verbs (know, like, want)"]
        ),

        // MARK: - 3. Present Perfect
        GrammarRule(
            category: .tenses,
            title: "Present Perfect",
            titleGerman: "Perfekt",
            titlePersian: "زمان حال کامل",
            explanation: "Used for actions completed at an unspecified time in the past whose result still affects the present.",
            explanationGerman: "Wird für Handlungen verwendet, die in der Vergangenheit abgeschlossen wurden, deren Ergebnis aber bis in die Gegenwart wirkt.",
            explanationPersian: "برای بیان کارهایی است که در زمانی نامشخص در گذشته انجام شده و هنوز هم اثر آن وجود دارد.",
            formula: "Subject + have/has + past participle (P.P.)",
            examples: [
                GrammarExample(english: "I have written a letter.", german: "Ich habe einen Brief geschrieben.", persian: "من یک نامه نوشته‌ام."),
                GrammarExample(english: "She has written a letter.", german: "Sie hat einen Brief geschrieben.", persian: "او یک نامه نوشته است."),
                GrammarExample(english: "They have not written a letter yet.", german: "Sie haben noch keinen Brief geschrieben.", persian: "آنها هنوز نامه ننوشته‌اند."),
                GrammarExample(english: "Have you written a letter?", german: "Hast du einen Brief geschrieben?", persian: "آیا نامه نوشته‌ای؟")
            ],
            tips: ["Signal words: yet, already, just, since, for, recently, lately, ever, never", "Use 'has' for he/she/it, 'have' otherwise", "Don't use with specific past time (yesterday, last week)"]
        ),

        // MARK: - 4. Present Perfect Continuous
        GrammarRule(
            category: .tenses,
            title: "Present Perfect Continuous",
            titleGerman: "Perfekt Verlaufsform",
            titlePersian: "زمان حال کامل استمراری",
            explanation: "Used for actions that started in the past and are still continuing now.",
            explanationGerman: "Wird für Handlungen verwendet, die in der Vergangenheit begonnen haben und noch andauern.",
            explanationPersian: "برای بیان کارهایی است که در گذشته شروع شده و هنوز هم ادامه دارد.",
            formula: "Subject + have/has been + verb-ing",
            examples: [
                GrammarExample(english: "I have been writing a letter since this morning.", german: "Ich schreibe seit heute Morgen einen Brief.", persian: "من از صبح دارم نامه می‌نویسم."),
                GrammarExample(english: "She has been writing a letter for two hours.", german: "Sie schreibt seit zwei Stunden einen Brief.", persian: "او دو ساعت است که نامه می‌نویسد."),
                GrammarExample(english: "Have you been writing a letter since this morning?", german: "Schreibst du seit heute Morgen einen Brief?", persian: "آیا از صبح داشتی نامه می‌نوشتی؟")
            ],
            tips: ["Signal words: since, for, all day, all week", "Emphasizes duration of the action", "'Since' + point in time, 'for' + duration"]
        ),

        // MARK: - 5. Past Simple
        GrammarRule(
            category: .tenses,
            title: "Past Simple",
            titleGerman: "Präteritum (Einfache Vergangenheit)",
            titlePersian: "زمان گذشته ساده",
            explanation: "Used for completed actions at a specific time in the past.",
            explanationGerman: "Wird für abgeschlossene Handlungen zu einem bestimmten Zeitpunkt in der Vergangenheit verwendet.",
            explanationPersian: "برای بیان کارهایی است که در زمان مشخصی در گذشته انجام شده و کاملاً به پایان رسیده است.",
            formula: "Subject + past form of verb",
            examples: [
                GrammarExample(english: "I wrote a letter yesterday.", german: "Ich schrieb gestern einen Brief.", persian: "من دیروز یک نامه نوشتم."),
                GrammarExample(english: "She wrote a letter yesterday.", german: "Sie schrieb gestern einen Brief.", persian: "او دیروز یک نامه نوشت."),
                GrammarExample(english: "They did not write a letter yesterday.", german: "Sie schrieben gestern keinen Brief.", persian: "آنها دیروز نامه ننوشتند."),
                GrammarExample(english: "Did you write a letter yesterday?", german: "Hast du gestern einen Brief geschrieben?", persian: "آیا دیروز نامه نوشتی؟"),
                GrammarExample(english: "He goed home.", isCorrect: false, correction: "He went home.")
            ],
            tips: ["Regular verbs: add -ed", "Learn irregular forms (write→wrote, go→went)", "Signal words: yesterday, last week, ago, in 2020"]
        ),

        // MARK: - 6. Past Continuous
        GrammarRule(
            category: .tenses,
            title: "Past Continuous",
            titleGerman: "Präteritum Verlaufsform",
            titlePersian: "زمان گذشته استمراری",
            explanation: "Used for actions that were in progress at a specific time in the past, often interrupted by another action.",
            explanationGerman: "Wird für Handlungen verwendet, die zu einem bestimmten Zeitpunkt in der Vergangenheit im Gange waren.",
            explanationPersian: "برای بیان کارهایی است که در زمان گذشته در حال انجام شدن بوده و معمولاً با گذشته ساده همراه است.",
            formula: "Subject + was/were + verb-ing",
            examples: [
                GrammarExample(english: "When she came, I was writing a letter.", german: "Als sie kam, schrieb ich einen Brief.", persian: "وقتی او آمد، من داشتم نامه می‌نوشتم."),
                GrammarExample(english: "They were playing football at 5 pm.", german: "Sie spielten um 17 Uhr Fußball.", persian: "آنها ساعت ۵ بعد از ظهر داشتند فوتبال بازی می‌کردند."),
                GrammarExample(english: "Were you writing a letter when she came?", german: "Hast du einen Brief geschrieben, als sie kam?", persian: "آیا وقتی او آمد، داشتی نامه می‌نوشتی؟")
            ],
            tips: ["Use 'was' with I/he/she/it; 'were' with you/we/they", "Often combined with Past Simple (When/While)", "Used for background actions"]
        ),

        // MARK: - 7. Past Perfect
        GrammarRule(
            category: .tenses,
            title: "Past Perfect",
            titleGerman: "Plusquamperfekt",
            titlePersian: "زمان گذشته کامل",
            explanation: "Used to describe an action that was completed before another past action.",
            explanationGerman: "Wird für Handlungen verwendet, die vor einer anderen Handlung in der Vergangenheit abgeschlossen waren.",
            explanationPersian: "برای بیان کارهایی است که در زمان گذشته قبل از کار دیگری انجام شده است.",
            formula: "Subject + had + past participle (P.P.)",
            examples: [
                GrammarExample(english: "When she came, I had written a letter.", german: "Als sie kam, hatte ich einen Brief geschrieben.", persian: "وقتی او آمد، من نامه نوشته بودم."),
                GrammarExample(english: "He had left before I arrived.", german: "Er war gegangen, bevor ich ankam.", persian: "او قبل از اینکه من برسم، رفته بود."),
                GrammarExample(english: "Had they written a letter when she came?", german: "Hatten sie einen Brief geschrieben, als sie kam?", persian: "آیا وقتی او آمد، آنها نامه نوشته بودند؟")
            ],
            tips: ["The earlier action uses Past Perfect", "The later action uses Past Simple", "Signal words: before, after, by the time, when, already"]
        ),

        // MARK: - 8. Past Perfect Continuous
        GrammarRule(
            category: .tenses,
            title: "Past Perfect Continuous",
            titleGerman: "Plusquamperfekt Verlaufsform",
            titlePersian: "زمان گذشته کامل استمراری",
            explanation: "Used to describe the duration of an action that was happening before another past action.",
            explanationGerman: "Wird verwendet, um die Dauer einer Handlung zu beschreiben, die vor einer anderen vergangenen Handlung andauerte.",
            explanationPersian: "برای بیان استمرار کارهایی است که در زمان گذشته انجام شده و طول زمان را هم بیان می‌کند.",
            formula: "Subject + had been + verb-ing",
            examples: [
                GrammarExample(english: "I had been writing a letter for two hours before he came.", german: "Ich hatte zwei Stunden lang einen Brief geschrieben, bevor er kam.", persian: "قبل از اینکه او بیاید، دو ساعت داشتم نامه می‌نوشتم."),
                GrammarExample(english: "She had been studying for three hours when I called.", german: "Sie hatte drei Stunden gelernt, als ich anrief.", persian: "وقتی زنگ زدم، او سه ساعت بود که درس می‌خواند.")
            ],
            tips: ["Emphasizes duration of the past action", "Use with 'for' + duration or 'since' + point in time", "Often used with 'before', 'when', 'by the time'"]
        ),

        // MARK: - 9. Future Simple
        GrammarRule(
            category: .tenses,
            title: "Future Simple",
            titleGerman: "Futur I",
            titlePersian: "زمان آینده ساده",
            explanation: "Used for actions that will happen in the future, predictions, or spontaneous decisions.",
            explanationGerman: "Wird für Handlungen in der Zukunft, Vorhersagen oder spontane Entscheidungen verwendet.",
            explanationPersian: "برای بیان کارهایی است که در آینده انجام خواهند شد.",
            formula: "Subject + will + base verb",
            examples: [
                GrammarExample(english: "I will write a letter tomorrow.", german: "Ich werde morgen einen Brief schreiben.", persian: "من فردا یک نامه خواهم نوشت."),
                GrammarExample(english: "She will write a letter tomorrow.", german: "Sie wird morgen einen Brief schreiben.", persian: "او فردا یک نامه خواهد نوشت."),
                GrammarExample(english: "They won't write a letter tomorrow.", german: "Sie werden morgen keinen Brief schreiben.", persian: "آنها فردا نامه نخواهند نوشت."),
                GrammarExample(english: "Will you write a letter tomorrow?", german: "Wirst du morgen einen Brief schreiben?", persian: "آیا فردا نامه خواهی نوشت؟")
            ],
            tips: ["Use will for predictions and promises", "Use 'be going to' for plans", "Signal words: tomorrow, next week, soon, in the future"]
        ),

        // MARK: - 10. Future Continuous
        GrammarRule(
            category: .tenses,
            title: "Future Continuous",
            titleGerman: "Futur I Verlaufsform",
            titlePersian: "زمان آینده استمراری",
            explanation: "Used for actions that will be in progress at a specific time in the future.",
            explanationGerman: "Wird für Handlungen verwendet, die zu einem bestimmten Zeitpunkt in der Zukunft im Gange sein werden.",
            explanationPersian: "برای بیان کارهایی است که در آینده انجام خواهند شد و از زمان دیگری در آینده خبر می‌دهد.",
            formula: "Subject + will be + verb-ing",
            examples: [
                GrammarExample(english: "I will be writing a letter tomorrow at this time.", german: "Ich werde morgen um diese Zeit einen Brief schreiben.", persian: "من فردا این ساعت دارم نامه می‌نویسم."),
                GrammarExample(english: "They will be travelling this time next week.", german: "Sie werden nächste Woche um diese Zeit reisen.", persian: "آنها هفته آینده این ساعت در سفر خواهند بود."),
                GrammarExample(english: "Will you be working tomorrow at 8?", german: "Wirst du morgen um 8 Uhr arbeiten?", persian: "آیا فردا ساعت ۸ مشغول کار خواهی بود؟")
            ],
            tips: ["Use for specific time in the future", "Often used with 'at + time tomorrow'", "Emphasizes ongoing action"]
        ),

        // MARK: - 11. Future Perfect
        GrammarRule(
            category: .tenses,
            title: "Future Perfect",
            titleGerman: "Futur II",
            titlePersian: "زمان آینده کامل",
            explanation: "Used for actions that will be completed before a specific time in the future.",
            explanationGerman: "Wird für Handlungen verwendet, die vor einem bestimmten Zeitpunkt in der Zukunft abgeschlossen sein werden.",
            explanationPersian: "برای بیان کارهایی است که در زمان آینده قبل از کار دیگری انجام شده است.",
            formula: "Subject + will have + past participle (P.P.)",
            examples: [
                GrammarExample(english: "I will have written a letter by the time Peter comes back.", german: "Ich werde einen Brief geschrieben haben, bis Peter zurückkommt.", persian: "من تا وقتی پیتر برگردد نامه نوشته‌ام."),
                GrammarExample(english: "She will have finished her work by 8 pm.", german: "Sie wird ihre Arbeit bis 20 Uhr beendet haben.", persian: "او تا ساعت ۸ شب کارش را تمام کرده خواهد بود."),
                GrammarExample(english: "Will you have written the letter by then?", german: "Wirst du den Brief bis dahin geschrieben haben?", persian: "آیا تا آن موقع نامه را نوشته‌ای؟")
            ],
            tips: ["Signal words: by, by then, by tomorrow, by the time", "Action will be completed before another future moment"]
        ),

        // MARK: - 12. Future Perfect Continuous
        GrammarRule(
            category: .tenses,
            title: "Future Perfect Continuous",
            titleGerman: "Futur II Verlaufsform",
            titlePersian: "زمان آینده کامل استمراری",
            explanation: "Used for actions that will have been continuing for a specific duration up to a point in the future.",
            explanationGerman: "Wird verwendet, um die Dauer einer Handlung anzugeben, die zu einem zukünftigen Zeitpunkt schon eine Weile andauert.",
            explanationPersian: "برای بیان کارهایی است که در زمان مشخصی در آینده قرار است کامل شود.",
            formula: "Subject + will have been + verb-ing",
            examples: [
                GrammarExample(english: "By the time we get home, I will have been writing this letter for three hours.", german: "Wenn wir nach Hause kommen, werde ich drei Stunden lang an diesem Brief geschrieben haben.", persian: "تا برسیم خانه، من سه ساعت است که دارم این نامه را می‌نویسم."),
                GrammarExample(english: "By next year, she will have been working here for ten years.", german: "Bis nächstes Jahr wird sie zehn Jahre lang hier gearbeitet haben.", persian: "تا سال آینده، او ده سال است که اینجا کار می‌کند.")
            ],
            tips: ["Emphasizes duration up to a future point", "Signal words: by, by the time, for + duration"]
        ),

        // MARK: - Passive Voice
        GrammarRule(
            category: .passiveVoice,
            title: "Passive Voice",
            titleGerman: "Passiv",
            titlePersian: "جمله مجهول",
            explanation: "Used when we want to emphasize the action or the receiver rather than the doer. Object becomes subject.",
            explanationGerman: "Wird verwendet, wenn der Empfänger der Handlung wichtiger ist als der Handelnde.",
            explanationPersian: "وقتی استفاده می‌شود که فاعل عمل مهم نیست یا مفعول مهمتر است.",
            formula: "Object + be (in the right tense) + past participle (+ by + agent)",
            examples: [
                GrammarExample(english: "She sees me every day. → I am seen every day.", german: "Sie sieht mich jeden Tag. → Ich werde jeden Tag gesehen.", persian: "او هر روز مرا می‌بیند. → من هر روز دیده می‌شوم."),
                GrammarExample(english: "Sona wrote a letter. → A letter was written.", german: "Sona schrieb einen Brief. → Ein Brief wurde geschrieben.", persian: "سونا یک نامه نوشت. → یک نامه نوشته شد."),
                GrammarExample(english: "They are painting the wall. → The wall is being painted.", german: "Sie streichen die Wand. → Die Wand wird gestrichen.", persian: "آنها دارند دیوار را رنگ می‌کنند. → دیوار دارد رنگ می‌شود."),
                GrammarExample(english: "He has broken the glass. → The glass has been broken.", german: "Er hat das Glas zerbrochen. → Das Glas ist zerbrochen worden.", persian: "او لیوان را شکسته است. → لیوان شکسته شده است."),
                GrammarExample(english: "We had bought books. → Books had been bought.", german: "Wir hatten Bücher gekauft. → Bücher waren gekauft worden.", persian: "ما کتاب خریده بودیم. → کتاب‌ها خریده شده بود.")
            ],
            tips: ["Form: be + past participle", "Tense changes: am/is/are → was/were → have been → had been → will be", "Use 'by' to mention the doer if needed"]
        ),

        // MARK: - Articles A vs An
        GrammarRule(
            category: .articles,
            title: "A vs An",
            titleGerman: "A und An (Unbestimmter Artikel)",
            titlePersian: "حرف تعریف نامعین",
            explanation: "Use 'a' before consonant sounds and 'an' before vowel sounds. It's about the SOUND, not the letter.",
            explanationGerman: "Verwende 'a' vor Konsonantenlauten und 'an' vor Vokallauten.",
            explanationPersian: "از 'a' قبل از صداهای بی‌صدا و از 'an' قبل از صداهای صدادار استفاده می‌شود.",
            formula: "a + consonant sound | an + vowel sound",
            examples: [
                GrammarExample(english: "a book, a car, a dog", german: "ein Buch, ein Auto, ein Hund", persian: "یک کتاب، یک ماشین، یک سگ"),
                GrammarExample(english: "an apple, an hour, an umbrella", german: "ein Apfel, eine Stunde, ein Regenschirm", persian: "یک سیب، یک ساعت، یک چتر"),
                GrammarExample(english: "a university (sounds like 'you')", german: "eine Universität"),
                GrammarExample(english: "a apple", isCorrect: false, correction: "an apple")
            ],
            tips: ["'Hour' uses 'an' (silent h)", "'University' uses 'a' (sounds like 'you-')", "Always listen to the SOUND"]
        ),

        // MARK: - The (Definite Article)
        GrammarRule(
            category: .articles,
            title: "The (Definite Article)",
            titleGerman: "The (Bestimmter Artikel)",
            titlePersian: "حرف تعریف معین",
            explanation: "Use 'the' for specific nouns, unique things, second mention, oceans/rivers/mountains, and superlatives.",
            explanationGerman: "Verwende 'the' für bestimmte Substantive, einzigartige Dinge und Superlative.",
            explanationPersian: "از 'the' قبل از اسامی مشخص، یکتا، در ذکر دوم، اقیانوس‌ها، رودها، کوه‌ها و صفت‌های عالی استفاده می‌شود.",
            formula: "the + specific noun",
            examples: [
                GrammarExample(english: "I bought a book. The book is about war.", german: "Ich kaufte ein Buch. Das Buch handelt vom Krieg.", persian: "یک کتاب خریدم. کتاب در باره جنگ است."),
                GrammarExample(english: "The Atlantic Ocean, The Caspian Sea, The Alps", german: "Der Atlantik, das Kaspische Meer, die Alpen", persian: "اقیانوس اطلس، دریای خزر، کوه‌های آلپ"),
                GrammarExample(english: "The sun rises every day.", german: "Die Sonne geht jeden Tag auf.", persian: "خورشید هر روز طلوع می‌کند."),
                GrammarExample(english: "The bigger the box, the heavier it is.", german: "Je größer die Box, desto schwerer ist sie.", persian: "هرچه جعبه بزرگ‌تر، سنگین‌تر.")
            ],
            tips: ["No 'the' before countries (Iran, Germany)", "Use 'the' before plural country names (the USA, the Netherlands)", "Use 'the' with superlatives (the best, the most beautiful)", "Use 'the' with oceans, rivers, mountains"]
        ),

        // MARK: - Prepositions of Time
        GrammarRule(
            category: .prepositions,
            title: "Prepositions of Time: In, On, At",
            titleGerman: "Zeitpräpositionen: In, On, At",
            titlePersian: "حروف اضافه زمان",
            explanation: "AT for specific times, ON for days/dates, IN for longer periods.",
            explanationGerman: "AT für genaue Zeiten, ON für Tage/Daten, IN für längere Zeiträume.",
            explanationPersian: "AT برای زمان‌های دقیق، ON برای روزها/تاریخ‌ها، IN برای دوره‌های بلندتر.",
            formula: "AT (time) | ON (day/date) | IN (period)",
            examples: [
                GrammarExample(english: "at 3 o'clock, at noon, at night, at sunset", german: "um 3 Uhr, mittags, nachts, bei Sonnenuntergang", persian: "ساعت ۳، ظهر، شب، هنگام غروب"),
                GrammarExample(english: "on Monday, on December 25th, on my birthday", german: "am Montag, am 25. Dezember, an meinem Geburtstag", persian: "روز دوشنبه، ۲۵ دسامبر، تولدم"),
                GrammarExample(english: "in January, in 2024, in the morning, in summer", german: "im Januar, in 2024, am Morgen, im Sommer", persian: "ژانویه، ۲۰۲۴، صبح، تابستان"),
                GrammarExample(english: "I arrived in Monday.", isCorrect: false, correction: "I arrived on Monday.")
            ],
            tips: ["AT: specific times", "ON: days and dates", "IN: months, years, seasons", "Exception: at night, in the morning"]
        ),

        // MARK: - Prepositions of Place
        GrammarRule(
            category: .prepositions,
            title: "Prepositions of Place: In, On, At",
            titleGerman: "Ortspräpositionen: In, On, At",
            titlePersian: "حروف اضافه مکان",
            explanation: "IN for enclosed spaces, ON for surfaces, AT for specific points/locations.",
            explanationGerman: "IN für geschlossene Räume, ON für Oberflächen, AT für bestimmte Punkte.",
            explanationPersian: "IN برای فضای بسته، ON برای سطوح، AT برای نقطه‌های مشخص.",
            formula: "IN (enclosed) | ON (surface) | AT (point)",
            examples: [
                GrammarExample(english: "in the room, in the box, in the car", german: "im Zimmer, in der Box, im Auto", persian: "در اتاق، در جعبه، در ماشین"),
                GrammarExample(english: "on the table, on the wall, on the floor", german: "auf dem Tisch, an der Wand, auf dem Boden", persian: "روی میز، روی دیوار، روی زمین"),
                GrammarExample(english: "at the door, at the bus stop, at home", german: "an der Tür, an der Bushaltestelle, zu Hause", persian: "دم در، ایستگاه اتوبوس، در خانه")
            ],
            tips: ["IN: surrounded space", "ON: touching a surface", "AT: specific point"]
        ),

        // MARK: - Preposition BY
        GrammarRule(
            category: .prepositions,
            title: "Preposition: BY",
            titleGerman: "Präposition: BY",
            titlePersian: "حرف اضافه BY",
            explanation: "Used mainly for transportation, manner, and time deadlines.",
            explanationGerman: "Wird hauptsächlich für Transportmittel, Art und Weise sowie Fristen verwendet.",
            explanationPersian: "بیشتر برای وسایل حمل‌ونقل، روش و مهلت زمانی استفاده می‌شود.",
            formula: "by + means / time / manner",
            examples: [
                GrammarExample(english: "by bus, by car, by plane, by train", german: "mit dem Bus, mit dem Auto, mit dem Flugzeug, mit dem Zug", persian: "با اتوبوس، با ماشین، با هواپیما، با قطار"),
                GrammarExample(english: "by mistake, by chance, by heart", german: "aus Versehen, zufällig, auswendig", persian: "اشتباها، تصادفا، از حفظ"),
                GrammarExample(english: "by tomorrow, by the way", german: "bis morgen, übrigens", persian: "تا فردا، در ضمن")
            ],
            tips: ["by + transportation (no article)", "Exception: on foot, NOT by foot", "by heart = memorized"]
        ),

        // MARK: - Preposition WITH
        GrammarRule(
            category: .prepositions,
            title: "Preposition: WITH",
            titleGerman: "Präposition: WITH",
            titlePersian: "حرف اضافه WITH",
            explanation: "Used mainly for tools, accompaniment, and characteristics.",
            explanationGerman: "Wird hauptsächlich für Werkzeuge, Begleitung und Eigenschaften verwendet.",
            explanationPersian: "بیشتر برای ابزار، همراهی و ویژگی‌ها استفاده می‌شود.",
            formula: "with + tool / person / feature",
            examples: [
                GrammarExample(english: "I eat with a spoon.", german: "Ich esse mit einem Löffel.", persian: "من با قاشق غذا می‌خورم."),
                GrammarExample(english: "She came with her friend.", german: "Sie kam mit ihrer Freundin.", persian: "او با دوستش آمد."),
                GrammarExample(english: "A girl with blue eyes", german: "Ein Mädchen mit blauen Augen", persian: "دختری با چشمان آبی"),
                GrammarExample(english: "satisfied with, angry with, happy with", german: "zufrieden mit, wütend auf, glücklich mit", persian: "راضی از، عصبانی از، خوشحال از")
            ],
            tips: ["with + tool (with a knife)", "with + accompaniment (with a friend)", "satisfied/happy/angry + with"]
        ),

        // MARK: - Comparatives (Equal)
        GrammarRule(
            category: .comparatives,
            title: "Equal Comparison (as...as)",
            titleGerman: "Vergleich (as...as)",
            titlePersian: "صفت متساوی",
            explanation: "Used to compare two things that are equal in quality.",
            explanationGerman: "Wird verwendet, um zwei gleiche Dinge zu vergleichen.",
            explanationPersian: "برای بیان خصوصیات دو چیز که دارای کیفیت مساوی هستند.",
            formula: "as + adjective + as",
            examples: [
                GrammarExample(english: "This table is as big as that table.", german: "Dieser Tisch ist so groß wie jener Tisch.", persian: "این میز به اندازه آن میز بزرگ است."),
                GrammarExample(english: "Today is not so warm as yesterday.", german: "Heute ist nicht so warm wie gestern.", persian: "امروز به گرمی دیروز نیست."),
                GrammarExample(english: "Mary is the same age as her friend.", german: "Mary ist genauso alt wie ihre Freundin.", persian: "ماری هم‌سن دوستش است.")
            ],
            tips: ["Equal: as + adj + as", "Negative: not so/as + adj + as", "Same: the same + noun + as"]
        ),

        // MARK: - Comparatives
        GrammarRule(
            category: .comparatives,
            title: "Comparatives (-er / more)",
            titleGerman: "Komparativ",
            titlePersian: "صفت تفضیلی",
            explanation: "Short adjectives add -er. Long adjectives use 'more'. Used to compare two things.",
            explanationGerman: "Kurze Adjektive fügen -er hinzu. Lange Adjektive verwenden 'more'.",
            explanationPersian: "صفت‌های کوتاه -er می‌گیرند. صفت‌های بلند با more می‌آیند.",
            formula: "Short: adj + er + than | Long: more + adj + than",
            examples: [
                GrammarExample(english: "This tree is taller than that tree.", german: "Dieser Baum ist höher als jener Baum.", persian: "این درخت از آن درخت بلندتر است."),
                GrammarExample(english: "This house is more beautiful than that one.", german: "Dieses Haus ist schöner als jenes.", persian: "این خانه از آن یکی زیباتر است."),
                GrammarExample(english: "He is more tall than me.", isCorrect: false, correction: "He is taller than me."),
                GrammarExample(english: "good → better, bad → worse, far → farther/further", german: "gut → besser, schlecht → schlechter, weit → weiter", persian: "خوب → بهتر، بد → بدتر، دور → دورتر")
            ],
            tips: ["1-2 syllables: add -er", "3+ syllables: use 'more'", "Irregular: good→better, bad→worse, little→less, much→more"]
        ),

        // MARK: - Superlatives
        GrammarRule(
            category: .comparatives,
            title: "Superlatives (-est / most)",
            titleGerman: "Superlativ",
            titlePersian: "صفت عالی",
            explanation: "Used to express the highest degree among three or more things.",
            explanationGerman: "Wird verwendet, um den höchsten Grad bei drei oder mehr Dingen auszudrücken.",
            explanationPersian: "برای بیان برتری بیش از دو چیز که دارای کیفیت متفاوت هستند.",
            formula: "the + adj + est | the most + long adj",
            examples: [
                GrammarExample(english: "He is the fattest student in the class.", german: "Er ist der dickste Schüler in der Klasse.", persian: "او چاق‌ترین دانش‌آموز کلاس است."),
                GrammarExample(english: "This is the most expensive car here.", german: "Das ist das teuerste Auto hier.", persian: "این گران‌ترین ماشین اینجاست."),
                GrammarExample(english: "good → the best, bad → the worst", german: "gut → der beste, schlecht → der schlechteste", persian: "خوب → بهترین، بد → بدترین")
            ],
            tips: ["Always use 'the' before superlatives", "Short adj + est", "Long adj: the most + adj", "Irregular: best, worst, least, most"]
        ),

        // MARK: - First Conditional
        GrammarRule(
            category: .conditionals,
            title: "First Conditional (Real Future)",
            titleGerman: "Erster Konditional (Reale Zukunft)",
            titlePersian: "جمله شرطی نوع اول",
            explanation: "Used for real or possible future situations.",
            explanationGerman: "Verwendet für reale oder mögliche zukünftige Situationen.",
            explanationPersian: "برای موقعیت‌های واقعی یا ممکن در آینده.",
            formula: "If + present simple, will/can/may + base verb",
            examples: [
                GrammarExample(english: "If Mary studies hard, she will pass the exam.", german: "Wenn Mary fleißig lernt, wird sie die Prüfung bestehen.", persian: "اگر ماری سخت درس بخواند، امتحان را قبول می‌شود."),
                GrammarExample(english: "If you go to the station, you will see your friend.", german: "Wenn du zum Bahnhof gehst, wirst du deinen Freund sehen.", persian: "اگر به ایستگاه بروی، دوستت را خواهی دید."),
                GrammarExample(english: "If we heat water, it will change into steam.", german: "Wenn wir Wasser erhitzen, verwandelt es sich in Dampf.", persian: "اگر آب را گرم کنیم، به بخار تبدیل می‌شود."),
                GrammarExample(english: "If it will rain...", isCorrect: false, correction: "If it rains...")
            ],
            tips: ["No 'will' in the if-clause", "Result clause: will/can/may", "For likely future situations"]
        ),

        // MARK: - Second Conditional
        GrammarRule(
            category: .conditionals,
            title: "Second Conditional (Unreal Present)",
            titleGerman: "Zweiter Konditional (Irreale Gegenwart)",
            titlePersian: "جمله شرطی نوع دوم",
            explanation: "Used for hypothetical or imaginary situations in the present or future.",
            explanationGerman: "Verwendet für hypothetische oder imaginäre Situationen.",
            explanationPersian: "برای موقعیت‌های فرضی یا غیرواقعی در حال یا آینده.",
            formula: "If + past simple, would/could/might + base verb",
            examples: [
                GrammarExample(english: "If Mary studied hard, she would pass the exam.", german: "Wenn Mary fleißig lernen würde, würde sie die Prüfung bestehen.", persian: "اگر ماری سخت درس می‌خواند، امتحان را قبول می‌شد."),
                GrammarExample(english: "If I had money, I would buy a car.", german: "Wenn ich Geld hätte, würde ich ein Auto kaufen.", persian: "اگر پول داشتم، ماشین می‌خریدم."),
                GrammarExample(english: "If I were you, I would accept.", german: "Wenn ich du wäre, würde ich annehmen.", persian: "اگر جای تو بودم، قبول می‌کردم."),
                GrammarExample(english: "If I would have...", isCorrect: false, correction: "If I had...")
            ],
            tips: ["Use 'were' for all persons (If I were)", "No 'would' in the if-clause", "Used for unlikely/imaginary situations"]
        ),

        // MARK: - Third Conditional
        GrammarRule(
            category: .conditionals,
            title: "Third Conditional (Unreal Past)",
            titleGerman: "Dritter Konditional (Irreale Vergangenheit)",
            titlePersian: "جمله شرطی نوع سوم",
            explanation: "Used for hypothetical situations in the past that did not happen.",
            explanationGerman: "Verwendet für hypothetische Vergangenheitssituationen, die nicht eingetreten sind.",
            explanationPersian: "برای موقعیت‌های فرضی در گذشته که اتفاق نیفتاده‌اند.",
            formula: "If + past perfect, would have + past participle",
            examples: [
                GrammarExample(english: "If I had studied, I would have passed the exam.", german: "Wenn ich gelernt hätte, hätte ich die Prüfung bestanden.", persian: "اگر درس خوانده بودم، در امتحان قبول می‌شدم."),
                GrammarExample(english: "If she had called, I would have come.", german: "Wenn sie angerufen hätte, wäre ich gekommen.", persian: "اگر زنگ زده بود، آمده بودم.")
            ],
            tips: ["Used for past regrets", "If-clause: had + past participle", "Result: would have + past participle"]
        ),

        // MARK: - Relative Pronouns
        GrammarRule(
            category: .pronouns,
            title: "Relative Pronouns (who/which/whose/where)",
            titleGerman: "Relativpronomen",
            titlePersian: "ضمایر موصولی",
            explanation: "Used to give more information about a noun. WHO for people, WHICH for things, WHOSE for possession, WHERE for places.",
            explanationGerman: "Wird verwendet, um mehr Informationen über ein Nomen zu geben.",
            explanationPersian: "برای دادن اطلاعات بیشتر درباره یک اسم استفاده می‌شود.",
            formula: "Noun + who/which/whose/where + clause",
            examples: [
                GrammarExample(english: "The boy who is coming is my friend.", german: "Der Junge, der kommt, ist mein Freund.", persian: "پسری که دارد می‌آید دوست من است."),
                GrammarExample(english: "The man whom you saw is my brother.", german: "Der Mann, den du gesehen hast, ist mein Bruder.", persian: "مردی که دیدی برادر من است."),
                GrammarExample(english: "The dog which is running is mine.", german: "Der Hund, der rennt, gehört mir.", persian: "سگی که دارد می‌دود مال من است."),
                GrammarExample(english: "The girl whose bag is red is my friend.", german: "Das Mädchen, dessen Tasche rot ist, ist meine Freundin.", persian: "دختری که کیفش قرمز است دوست من است."),
                GrammarExample(english: "The school where we study is big.", german: "Die Schule, in der wir lernen, ist groß.", persian: "مدرسه‌ای که در آن درس می‌خوانیم بزرگ است.")
            ],
            tips: ["WHO/WHOM = people", "WHICH = things/animals", "WHOSE = possession", "WHERE = places", "THAT = can replace who/which (in defining clauses)"]
        ),

        // MARK: - Reported Speech (Statements)
        GrammarRule(
            category: .reportedSpeech,
            title: "Reported Speech - Statements",
            titleGerman: "Indirekte Rede - Aussagen",
            titlePersian: "نقل قول غیرمستقیم - جملات خبری",
            explanation: "Used to report what someone said without quoting them directly. Tense usually shifts back one step.",
            explanationGerman: "Wird verwendet, um wiederzugeben, was jemand gesagt hat. Die Zeitform wird meist um eine Stufe verschoben.",
            explanationPersian: "برای بیان آنچه کسی گفته، بدون نقل عین جملات او. زمان معمولاً یک پله به عقب می‌رود.",
            formula: "Subject + said (that) + reported clause",
            examples: [
                GrammarExample(english: "He said, \"Elham goes to school.\" → He said that Elham went to school.", german: "Er sagte: \"Elham geht zur Schule.\" → Er sagte, dass Elham zur Schule ging.", persian: "او گفت: \"الهام به مدرسه می‌رود.\" → او گفت که الهام به مدرسه می‌رفت."),
                GrammarExample(english: "She said, \"I can drive.\" → She said she could drive.", german: "Sie sagte: \"Ich kann fahren.\" → Sie sagte, sie könne fahren.", persian: "او گفت: \"من می‌توانم رانندگی کنم.\" → او گفت که می‌توانست رانندگی کند.")
            ],
            tips: ["present → past", "past → past perfect", "will → would, can → could, may → might", "this → that, now → then, tomorrow → the next day"]
        ),

        // MARK: - Reported Speech (Questions)
        GrammarRule(
            category: .reportedSpeech,
            title: "Reported Speech - Questions",
            titleGerman: "Indirekte Rede - Fragen",
            titlePersian: "نقل قول غیرمستقیم - جملات پرسشی",
            explanation: "For Wh-questions use the question word. For Yes/No questions use 'if' or 'whether'.",
            explanationGerman: "Bei W-Fragen verwendet man das Fragewort. Bei Ja/Nein-Fragen 'if' oder 'whether'.",
            explanationPersian: "برای سوالات با کلمه پرسشی، همان کلمه را به کار می‌بریم. برای سوال بله/خیر از if یا whether استفاده می‌شود.",
            formula: "Wh-Q: asked + wh-word + subject + verb | Y/N: asked + if/whether + subject + verb",
            examples: [
                GrammarExample(english: "He asked, \"What time will you come?\" → He asked what time she would come.", german: "Er fragte: \"Wann kommst du?\" → Er fragte, wann sie kommen würde.", persian: "پرسید: \"چه ساعتی می‌آیی؟\" → پرسید چه ساعتی می‌آید."),
                GrammarExample(english: "She asked, \"Can you swim?\" → She asked if I could swim.", german: "Sie fragte: \"Kannst du schwimmen?\" → Sie fragte, ob ich schwimmen könne.", persian: "پرسید: \"شنا بلدی؟\" → پرسید که آیا شنا بلدم.")
            ],
            tips: ["No question mark in indirect questions", "Subject comes BEFORE the verb (not inverted)", "Use 'if'/'whether' for yes/no questions"]
        ),

        // MARK: - Reported Speech (Commands)
        GrammarRule(
            category: .reportedSpeech,
            title: "Reported Speech - Commands/Requests",
            titleGerman: "Indirekte Rede - Aufforderungen",
            titlePersian: "نقل قول غیرمستقیم - جملات امری",
            explanation: "Used for reporting orders or requests. Use 'told/asked' + object + (not) to + verb.",
            explanationGerman: "Wird verwendet für Anweisungen und Bitten.",
            explanationPersian: "برای نقل دستورات و درخواست‌ها استفاده می‌شود.",
            formula: "told/asked + object + (not) + to + base verb",
            examples: [
                GrammarExample(english: "The teacher said, \"Write your name.\" → The teacher told me to write my name.", german: "Der Lehrer sagte: \"Schreib deinen Namen.\" → Der Lehrer sagte mir, ich solle meinen Namen schreiben.", persian: "معلم گفت: \"اسمت را بنویس.\" → معلم به من گفت اسمم را بنویسم."),
                GrammarExample(english: "He said, \"Don't park here.\" → He told them not to park there.", german: "Er sagte: \"Parkt hier nicht.\" → Er sagte ihnen, sie sollten dort nicht parken.", persian: "گفت: \"اینجا پارک نکنید.\" → گفت آنجا پارک نکنند.")
            ],
            tips: ["Negative: not + to + verb", "'here' → 'there', 'this' → 'that'", "Verbs: tell, ask, order, command"]
        ),

        // MARK: - Question Tags
        GrammarRule(
            category: .questions,
            title: "Question Tags (Tag Endings)",
            titleGerman: "Question Tags (Frageanhängsel)",
            titlePersian: "سوال‌های ضمیمه",
            explanation: "Short questions added to the end of statements. Positive statement → negative tag, negative statement → positive tag.",
            explanationGerman: "Kurze Fragen am Ende eines Satzes. Positiver Satz → negativer Tag, negativer Satz → positiver Tag.",
            explanationPersian: "سوال‌های کوتاهی که در پایان جمله می‌آیند. جمله مثبت → سوال منفی، جمله منفی → سوال مثبت.",
            formula: "Statement, auxiliary verb + (not) + pronoun?",
            examples: [
                GrammarExample(english: "Parisa can speak English, can't she?", german: "Parisa kann Englisch sprechen, oder?", persian: "پریسا انگلیسی صحبت می‌کند، مگر نه؟"),
                GrammarExample(english: "Elham isn't absent today, is she?", german: "Elham ist heute nicht abwesend, oder?", persian: "الهام امروز غایب نیست، مگر نه؟"),
                GrammarExample(english: "I am teaching English, aren't I?", german: "Ich unterrichte Englisch, oder?", persian: "من انگلیسی درس می‌دهم، مگر نه؟"),
                GrammarExample(english: "Open the door, will you?", german: "Mach die Tür auf, ja?", persian: "در را باز کن، باشه؟"),
                GrammarExample(english: "Let's go, shall we?", german: "Gehen wir, ja?", persian: "برویم، باشه؟")
            ],
            tips: ["Positive → negative tag", "Negative → positive tag", "I am → aren't I?", "Imperative → will you?", "Let's → shall we?"]
        ),

        // MARK: - Modal Verbs Can/Could
        GrammarRule(
            category: .modals,
            title: "Can / Could",
            titleGerman: "Können (Can/Could)",
            titlePersian: "می‌توانم (Can/Could)",
            explanation: "CAN expresses ability or permission in the present. COULD is the past form or polite request.",
            explanationGerman: "CAN drückt Fähigkeit oder Erlaubnis aus. COULD ist die Vergangenheitsform oder höfliche Bitte.",
            explanationPersian: "Can برای توانایی یا اجازه در حال است. Could گذشته‌ آن یا برای درخواست مودبانه است.",
            formula: "Subject + can/could + base verb",
            examples: [
                GrammarExample(english: "I can swim.", german: "Ich kann schwimmen.", persian: "من می‌توانم شنا کنم."),
                GrammarExample(english: "She could read when she was 4.", german: "Sie konnte mit 4 lesen.", persian: "او در ۴ سالگی می‌توانست بخواند."),
                GrammarExample(english: "Could you help me, please?", german: "Könnten Sie mir bitte helfen?", persian: "می‌شود لطفاً کمکم کنید؟"),
                GrammarExample(english: "I can to swim.", isCorrect: false, correction: "I can swim.")
            ],
            tips: ["Never use 'to' after can/could", "Could is more polite for requests", "Use 'be able to' for other tenses"]
        ),

        // MARK: - Modal Verbs May/Might
        GrammarRule(
            category: .modals,
            title: "May / Might",
            titleGerman: "Dürfen / Vielleicht (May/Might)",
            titlePersian: "May / Might (اجازه/احتمال)",
            explanation: "MAY for permission and possibility. MIGHT for less certain possibility.",
            explanationGerman: "MAY für Erlaubnis und Möglichkeit. MIGHT für weniger sichere Möglichkeit.",
            explanationPersian: "May برای اجازه و احتمال. Might برای احتمال کمتر.",
            formula: "Subject + may/might + base verb",
            examples: [
                GrammarExample(english: "May I use your phone?", german: "Darf ich Ihr Telefon benutzen?", persian: "می‌توانم از تلفن شما استفاده کنم؟"),
                GrammarExample(english: "John may receive a letter today.", german: "John bekommt vielleicht heute einen Brief.", persian: "جان ممکن است امروز نامه‌ای دریافت کند."),
                GrammarExample(english: "It might rain tomorrow.", german: "Es könnte morgen regnen.", persian: "ممکن است فردا باران ببارد.")
            ],
            tips: ["MAY = ~50% probability", "MIGHT = ~35% probability", "MAY is more polite for permission"]
        ),

        // MARK: - Modal Verbs Must
        GrammarRule(
            category: .modals,
            title: "Must / Have to",
            titleGerman: "Müssen (Must/Have to)",
            titlePersian: "بایست (Must/Have to)",
            explanation: "MUST expresses strong obligation from the speaker. HAVE TO expresses external obligation. MUST can also mean strong inference.",
            explanationGerman: "MUST drückt starke Verpflichtung des Sprechers aus. HAVE TO drückt externe Verpflichtung aus.",
            explanationPersian: "Must برای اجبار از سوی گوینده. Have to برای اجبار از سوی دیگران.",
            formula: "Subject + must/have to + base verb",
            examples: [
                GrammarExample(english: "You must clean your boots.", german: "Du musst deine Schuhe putzen.", persian: "تو باید کفش‌هایت را تمیز کنی."),
                GrammarExample(english: "You will have to clean your boots in the army.", german: "Im Militär wirst du deine Stiefel putzen müssen.", persian: "در ارتش مجبور خواهی بود کفش‌هایت را تمیز کنی."),
                GrammarExample(english: "He must be about 40. (inference)", german: "Er muss etwa 40 sein.", persian: "او باید حدود ۴۰ ساله باشد. (نتیجه‌گیری)")
            ],
            tips: ["MUST = speaker's obligation", "HAVE TO = external obligation", "MUST also expresses strong inference (~95% certain)"]
        ),

        // MARK: - Modal Verb Need
        GrammarRule(
            category: .modals,
            title: "Need (Modal & Main Verb)",
            titleGerman: "Brauchen (Need)",
            titlePersian: "نیاز داشتن (Need)",
            explanation: "NEED can be a modal or a main verb. As main verb it follows do/does/did pattern.",
            explanationGerman: "NEED kann ein Modalverb oder Hauptverb sein.",
            explanationPersian: "Need هم می‌تواند فعل کمکی باشد و هم فعل اصلی.",
            formula: "Modal: need not + verb | Main: do/does/did + need",
            examples: [
                GrammarExample(english: "He needs to go.", german: "Er muss gehen.", persian: "او باید برود."),
                GrammarExample(english: "He doesn't need to go.", german: "Er muss nicht gehen.", persian: "او نباید برود."),
                GrammarExample(english: "I need a book.", german: "Ich brauche ein Buch.", persian: "من یک کتاب لازم دارم."),
                GrammarExample(english: "I don't need a book.", german: "Ich brauche kein Buch.", persian: "من کتاب لازم ندارم.")
            ],
            tips: ["Modal NEED: needn't + verb", "Main NEED: don't/doesn't need + to + verb", "NEED + noun = require"]
        ),

        // MARK: - Past Modals
        GrammarRule(
            category: .modals,
            title: "Past Modals (Must/Might/Should/Could have)",
            titleGerman: "Modalverben in der Vergangenheit",
            titlePersian: "افعال کمکی در گذشته",
            explanation: "MUST HAVE for inference about past. MIGHT HAVE for past possibility. SHOULD HAVE for missed obligation. COULD HAVE for unused ability.",
            explanationGerman: "MUST HAVE für Vergangenheitsinferenz. SHOULD HAVE für verpasste Pflicht.",
            explanationPersian: "Must have برای نتیجه‌گیری در گذشته. Should have برای کاری که باید انجام می‌شد.",
            formula: "Modal + have + past participle",
            examples: [
                GrammarExample(english: "They must have known him.", german: "Sie müssen ihn gekannt haben.", persian: "آنها باید او را شناخته باشند."),
                GrammarExample(english: "They might have heard us.", german: "Sie haben uns vielleicht gehört.", persian: "آنها احتمالا صدای ما را شنیده‌اند."),
                GrammarExample(english: "They should have studied. (but didn't)", german: "Sie hätten lernen sollen. (aber haben es nicht)", persian: "آنها باید درس می‌خواندند. (اما نخواندند)"),
                GrammarExample(english: "They could have played tennis. (but didn't)", german: "Sie hätten Tennis spielen können.", persian: "آنها می‌توانستند تنیس بازی کنند. (اما نکردند)")
            ],
            tips: ["must have = strong inference", "might have = past possibility", "should have = past advice/regret", "could have = unused past ability"]
        ),

        // MARK: - Be Supposed To
        GrammarRule(
            category: .modals,
            title: "Be Supposed To",
            titleGerman: "Sollen / Erwartet werden",
            titlePersian: "قرار است",
            explanation: "Used to express expectation or arrangement - something that is expected to happen.",
            explanationGerman: "Drückt aus, was erwartet oder vereinbart ist.",
            explanationPersian: "برای بیان انتظار یا توافق - چیزی که قرار است انجام شود.",
            formula: "Subject + am/is/are/was/were + supposed to + base verb",
            examples: [
                GrammarExample(english: "Jack is supposed to return any moment.", german: "Jack soll jeden Moment zurückkommen.", persian: "جک قرار است هر لحظه برگردد."),
                GrammarExample(english: "You are supposed to be at home now.", german: "Du solltest jetzt zu Hause sein.", persian: "تو قرار است الان در خانه باشی."),
                GrammarExample(english: "The ship was supposed to arrive last night.", german: "Das Schiff sollte gestern Abend ankommen.", persian: "کشتی قرار بود شب قبل برسد.")
            ],
            tips: ["Present: am/is/are supposed to", "Past: was/were supposed to (didn't happen)", "Expresses expectation"]
        ),

        // MARK: - I Wish / If only
        GrammarRule(
            category: .conditionals,
            title: "I Wish / If Only",
            titleGerman: "I Wish / If Only (Wünsche)",
            titlePersian: "ای کاش (I Wish / If Only)",
            explanation: "Used to express wishes or regrets. Verb tenses shift back: present → past, past → past perfect, future → would.",
            explanationGerman: "Drückt Wünsche oder Bedauern aus. Zeitformen werden zurückverschoben.",
            explanationPersian: "برای بیان آرزو یا تأسف. زمان‌ها یک پله به عقب می‌روند.",
            formula: "I wish + past simple/past perfect/would",
            examples: [
                GrammarExample(english: "I wish I had her phone number now. (present wish)", german: "Ich wünschte, ich hätte jetzt ihre Nummer.", persian: "کاش الان شماره تلفنش را داشتم."),
                GrammarExample(english: "I wish we had left earlier yesterday. (past wish)", german: "Ich wünschte, wir wären gestern früher gegangen.", persian: "کاش دیروز زودتر رفته بودیم."),
                GrammarExample(english: "I wish it would rain. (future wish)", german: "Ich wünschte, es würde regnen.", persian: "کاش باران ببارد."),
                GrammarExample(english: "I wish I were a doctor. (always 'were')", german: "Ich wünschte, ich wäre Arzt.", persian: "کاش یک پزشک بودم."),
                GrammarExample(english: "If only the rain would stop.", german: "Wenn nur der Regen aufhören würde.", persian: "کاش باران قطع شود.")
            ],
            tips: ["Always use 'were' (not was) with I/he/she/it", "Present wish: past simple", "Past wish: past perfect", "Future wish: would + verb", "'If only' = 'I wish' but stronger"]
        ),

        // MARK: - Negation
        GrammarRule(
            category: .negation,
            title: "Negation Rules",
            titleGerman: "Verneinung",
            titlePersian: "منفی‌سازی",
            explanation: "How to make negative sentences with auxiliary verbs do/does/did, modals, and 'be'.",
            explanationGerman: "Wie man verneinte Sätze mit do/does/did und Modalverben bildet.",
            explanationPersian: "روش منفی کردن جملات با افعال کمکی و افعال اصلی.",
            formula: "Auxiliary + not / don't/doesn't/didn't + verb",
            examples: [
                GrammarExample(english: "It is a book. → It is not a book.", german: "Es ist ein Buch. → Es ist kein Buch.", persian: "این یک کتاب است. → این یک کتاب نیست."),
                GrammarExample(english: "He has a book. → He does not have a book.", german: "Er hat ein Buch. → Er hat kein Buch.", persian: "او یک کتاب دارد. → او کتابی ندارد."),
                GrammarExample(english: "She bought something. → She did not buy anything.", german: "Sie hat etwas gekauft. → Sie hat nichts gekauft.", persian: "او چیزی خرید. → او چیزی نخرید."),
                GrammarExample(english: "Open the door. → Don't open the door.", german: "Mach die Tür auf. → Mach die Tür nicht auf.", persian: "در را باز کن. → در را باز نکن."),
                GrammarExample(english: "Let's go. → Let's not go.", german: "Lass uns gehen. → Lass uns nicht gehen.", persian: "برویم. → نرویم.")
            ],
            tips: ["something → anything in negatives", "already → yet (negative)", "still → anymore (negative)", "Imperative: Don't + verb"]
        ),

        // MARK: - No vs Not
        GrammarRule(
            category: .negation,
            title: "No vs Not",
            titleGerman: "No vs Not",
            titlePersian: "تفاوت No و Not",
            explanation: "NO comes before a noun. NOT is used with verbs and quantifiers (much, many, any, enough).",
            explanationGerman: "NO steht vor einem Nomen. NOT wird mit Verben verwendet.",
            explanationPersian: "No قبل از اسم می‌آید. Not با افعال و کمیت‌سنج‌ها استفاده می‌شود.",
            formula: "no + noun | not + verb/much/many/any/enough",
            examples: [
                GrammarExample(english: "He has no money.", german: "Er hat kein Geld.", persian: "او پولی ندارد."),
                GrammarExample(english: "Peter has no black car.", german: "Peter hat kein schwarzes Auto.", persian: "پیتر ماشین مشکی ندارد."),
                GrammarExample(english: "There is not any paper on the desk.", german: "Auf dem Tisch ist kein Papier.", persian: "روی میز کاغذی نیست."),
                GrammarExample(english: "Not many girls were there.", german: "Nicht viele Mädchen waren dort.", persian: "دختر زیادی آنجا نبود.")
            ],
            tips: ["NO + noun (no money, no friends)", "NOT + much/many/any/enough", "NO is stronger than 'not any'"]
        ),

        // MARK: - Causative
        GrammarRule(
            category: .tenses,
            title: "Causative (Have/Get/Make something done)",
            titleGerman: "Kausativ (etwas machen lassen)",
            titlePersian: "ساختار سببی (وادار کردن)",
            explanation: "Used to express that someone else does the action for the subject. Three structures: have/get + object + past participle, make/have + object + base verb, get + object + to + verb.",
            explanationGerman: "Wird verwendet, wenn jemand anders die Handlung für das Subjekt ausführt.",
            explanationPersian: "برای بیان اینکه شخص دیگری کاری را برای فاعل انجام می‌دهد.",
            formula: "have/get + object + P.P. | make/have + object + verb | get + object + to + verb",
            examples: [
                GrammarExample(english: "I had my car repaired last week.", german: "Ich ließ letzte Woche mein Auto reparieren.", persian: "هفته پیش ماشینم را دادم تعمیر کنند."),
                GrammarExample(english: "She had her hair dyed.", german: "Sie ließ sich die Haare färben.", persian: "او موهایش را رنگ کرد."),
                GrammarExample(english: "I made the mechanic repair my car.", german: "Ich ließ den Mechaniker mein Auto reparieren.", persian: "من از مکانیک خواستم ماشینم را تعمیر کند."),
                GrammarExample(english: "I got the mechanic to repair the car.", german: "Ich brachte den Mechaniker dazu, das Auto zu reparieren.", persian: "من از مکانیک خواستم ماشین را تعمیر کند.")
            ],
            tips: ["have/get + obj + P.P. = service done", "make/have + obj + verb (no 'to')", "get + obj + to + verb (with 'to')"]
        ),

        // MARK: - Neither/Either/So/Too
        GrammarRule(
            category: .conjunctions,
            title: "Neither / Either / So / Too",
            titleGerman: "Neither / Either / So / Too",
            titlePersian: "Neither / Either / So / Too",
            explanation: "Used to express agreement. SO/TOO in positive sentences. NEITHER/EITHER in negative sentences.",
            explanationGerman: "Drückt Übereinstimmung aus. SO/TOO bei positiven, NEITHER/EITHER bei negativen Sätzen.",
            explanationPersian: "برای بیان موافقت. So/Too در جملات مثبت، Neither/Either در جملات منفی.",
            formula: "Positive: ..., and so + aux + S | ..., and S + aux + too\nNegative: ..., and neither + aux + S | ..., and S + aux + not + either",
            examples: [
                GrammarExample(english: "Alex can drive, and so can I.", german: "Alex kann fahren, und ich auch.", persian: "آلکس می‌تواند رانندگی کند، من هم همین‌طور."),
                GrammarExample(english: "Alex can drive, and I can too.", german: "Alex kann fahren, und ich auch.", persian: "آلکس می‌تواند رانندگی کند، من هم همین‌طور."),
                GrammarExample(english: "Alex can't drive, and neither can I.", german: "Alex kann nicht fahren, und ich auch nicht.", persian: "آلکس نمی‌تواند رانندگی کند، من هم همین‌طور."),
                GrammarExample(english: "Alex can't drive, and I can't either.", german: "Alex kann nicht fahren, und ich auch nicht.", persian: "آلکس نمی‌تواند رانندگی کند، من هم همین‌طور.")
            ],
            tips: ["SO + auxiliary + subject (positive)", "NEITHER + auxiliary + subject (negative)", "Subject + auxiliary + TOO (positive)", "Subject + negative auxiliary + EITHER (negative)"]
        ),

        // MARK: - Too / So / Such / Enough / Very
        GrammarRule(
            category: .adverbs,
            title: "Too / So / Such / Enough / Very",
            titleGerman: "Too / So / Such / Enough / Very",
            titlePersian: "Too / So / Such / Enough / Very",
            explanation: "TOO = excessive (negative). SO = degree + that-clause. SUCH = a/an + adj + noun. ENOUGH = sufficient. VERY = simple emphasis.",
            explanationGerman: "TOO = zu viel. SO = so + Adjektiv. SUCH = so ein. ENOUGH = genug.",
            explanationPersian: "Too = خیلی زیاد (منفی). So = آنقدر + that. Such = چنان. Enough = به اندازه کافی.",
            formula: "too + adj + to + verb | so + adj + that | such (a/an) + adj + N | adj + enough | very + adj",
            examples: [
                GrammarExample(english: "This tea is too hot to drink.", german: "Dieser Tee ist zu heiß zum Trinken.", persian: "این چای برای نوشیدن خیلی داغ است."),
                GrammarExample(english: "This problem is so difficult that I can't solve it.", german: "Dieses Problem ist so schwierig, dass ich es nicht lösen kann.", persian: "این مسئله آنقدر سخت است که نمی‌توانم حل کنم."),
                GrammarExample(english: "She is such a polite girl that everyone likes her.", german: "Sie ist so ein höfliches Mädchen, dass jeder sie mag.", persian: "او چنان دختر مودبی است که همه دوستش دارند."),
                GrammarExample(english: "He is strong enough to lift this box.", german: "Er ist stark genug, um diese Kiste zu heben.", persian: "او به اندازه کافی قوی است که این جعبه را بلند کند."),
                GrammarExample(english: "He is very clever.", german: "Er ist sehr klug.", persian: "او خیلی باهوش است.")
            ],
            tips: ["TOO = excessive (negative)", "SO + adj + THAT", "SUCH (a/an) + adj + noun + THAT", "ENOUGH after adj, before noun", "VERY = simple emphasis"]
        ),

        // MARK: - Used to / Be used to
        GrammarRule(
            category: .tenses,
            title: "Used to / Be used to",
            titleGerman: "Used to / Be used to",
            titlePersian: "Used to / Be used to",
            explanation: "USED TO + base verb = past habit that stopped. BE USED TO + verb-ing = be accustomed to.",
            explanationGerman: "USED TO + Verb = frühere Gewohnheit. BE USED TO + ing = gewohnt sein.",
            explanationPersian: "Used to + فعل = عادت ترک شده در گذشته. Be used to + ing = عادت داشتن کنونی.",
            formula: "used to + base verb | am/is/are used to + verb-ing",
            examples: [
                GrammarExample(english: "He used to smoke when he was young. (no longer)", german: "Er rauchte früher, als er jung war.", persian: "او وقتی جوان بود سیگار می‌کشید (دیگر نمی‌کشد)."),
                GrammarExample(english: "He is used to smoking cigarettes. (habit now)", german: "Er ist es gewohnt zu rauchen.", persian: "او عادت دارد سیگار بکشد."),
                GrammarExample(english: "I am used to reading newspaper before bed.", german: "Ich bin es gewohnt, vor dem Schlafen Zeitung zu lesen.", persian: "من عادت دارم قبل از خواب روزنامه بخوانم.")
            ],
            tips: ["used to + base = past habit (stopped)", "be used to + ing = current habit/accustomed", "get used to + ing = become accustomed"]
        ),

        // MARK: - Much/Many/Few/Little
        GrammarRule(
            category: .adjectives,
            title: "Much / Many / Few / Little / A lot of",
            titleGerman: "Much / Many / Few / Little / A lot of",
            titlePersian: "Much / Many / Few / Little / A lot of",
            explanation: "MANY/FEW for countable nouns. MUCH/LITTLE for uncountable nouns. A LOT OF for both.",
            explanationGerman: "MANY/FEW für zählbare Nomen. MUCH/LITTLE für unzählbare Nomen.",
            explanationPersian: "Many/Few برای اسامی قابل شمارش. Much/Little برای غیرقابل شمارش.",
            formula: "many/few + countable | much/little + uncountable | a lot of + both",
            examples: [
                GrammarExample(english: "I have a few friends.", german: "Ich habe ein paar Freunde.", persian: "من چند دوست دارم."),
                GrammarExample(english: "There is a little milk in the bottle.", german: "Es ist ein wenig Milch in der Flasche.", persian: "کمی شیر در بطری است."),
                GrammarExample(english: "There are a lot of cars in the street.", german: "Es sind viele Autos auf der Straße.", persian: "ماشین‌های زیادی در خیابان است."),
                GrammarExample(english: "He didn't eat much fruit.", german: "Er aß nicht viel Obst.", persian: "او میوه زیادی نخورد."),
                GrammarExample(english: "I don't have many friends here.", german: "Ich habe hier nicht viele Freunde.", persian: "من اینجا دوستان زیادی ندارم.")
            ],
            tips: ["FEW = countable, almost none", "A FEW = countable, some", "LITTLE = uncountable, almost none", "A LITTLE = uncountable, some", "MUCH/MANY mainly in negative/question"]
        ),

        // MARK: - Adjective Clauses
        GrammarRule(
            category: .pronouns,
            title: "Adjective Clauses",
            titleGerman: "Relativsätze",
            titlePersian: "جمله وصفی",
            explanation: "A clause that describes a noun. Begins with who, whom, which, whose, that, where.",
            explanationGerman: "Ein Satz, der ein Nomen beschreibt.",
            explanationPersian: "جمله‌ای که اسم قبل از خود را توصیف می‌کند.",
            formula: "Noun + who/whom/which/whose/that/where + clause",
            examples: [
                GrammarExample(english: "The man who is standing over there is from Iran.", german: "Der Mann, der dort drüben steht, kommt aus dem Iran.", persian: "مردی که آنجا ایستاده ایرانی است."),
                GrammarExample(english: "Did you know the man to whom you were speaking is Italian?", german: "Wusstest du, dass der Mann, mit dem du gesprochen hast, Italiener ist?", persian: "آیا می‌دانی مردی که با او صحبت می‌کردی ایتالیایی است؟"),
                GrammarExample(english: "I saw the man who helped you.", german: "Ich sah den Mann, der dir half.", persian: "من مردی که به تو کمک کرد را دیدم.")
            ],
            tips: ["WHO/THAT for people (subject)", "WHOM for people (object)", "WHICH/THAT for things", "WHOSE for possession", "WHERE for places"]
        ),

        // MARK: - Adjective Phrases
        GrammarRule(
            category: .pronouns,
            title: "Adjective Phrases (Reduced Clauses)",
            titleGerman: "Partizipialkonstruktionen",
            titlePersian: "عبارت وصفی",
            explanation: "A shortened adjective clause. Remove who/which + be, use -ing (active) or -ed (passive).",
            explanationGerman: "Eine verkürzte Relativklausel mit Partizip.",
            explanationPersian: "صورت کوتاه شده جمله وصفی. Who/which + be حذف می‌شود.",
            formula: "Noun + -ing (active) | Noun + -ed (passive)",
            examples: [
                GrammarExample(english: "The man who is talking to me → The man talking to me", german: "Der Mann, der mit mir spricht → Der mit mir sprechende Mann", persian: "مردی که با من صحبت می‌کند → مردِ در حال صحبت با من"),
                GrammarExample(english: "The pictures which are presented → The pictures presented", german: "Die gezeigten Bilder", persian: "تصاویر نمایش داده شده"),
                GrammarExample(english: "The man who works in this office → The man working in this office", german: "Der in diesem Büro arbeitende Mann", persian: "مردی که در این اداره کار می‌کند → مرد کارکنندۀ این اداره")
            ],
            tips: ["Active: use -ing", "Passive: use -ed/past participle", "Remove who/which + be", "If no 'be', change verb to -ing"]
        ),

        // MARK: - Noun Clauses
        GrammarRule(
            category: .conjunctions,
            title: "Noun Clauses",
            titleGerman: "Nominalsätze",
            titlePersian: "جمله اسمی",
            explanation: "A clause that functions as a noun. Begins with that, what, when, where, why, how, if, whether.",
            explanationGerman: "Ein Satz, der wie ein Nomen funktioniert.",
            explanationPersian: "جمله‌ای که نقش اسم را در جمله ایفا می‌کند.",
            formula: "subordinator + subject + verb",
            examples: [
                GrammarExample(english: "I don't know where Bob went last night.", german: "Ich weiß nicht, wohin Bob letzte Nacht ging.", persian: "نمی‌دانم باب دیشب کجا رفت."),
                GrammarExample(english: "I don't believe what they said.", german: "Ich glaube nicht, was sie gesagt haben.", persian: "آنچه آنها گفتند را باور نمی‌کنم."),
                GrammarExample(english: "That he had lied to us was unbelievable.", german: "Dass er uns angelogen hat, war unglaublich.", persian: "اینکه او به ما دروغ گفته بود، باور نکردنی بود.")
            ],
            tips: ["Begin with: that, what, when, where, why, how, if/whether", "Subject of sentence: That + clause...", "Object of verb: I know + that + clause"]
        ),

        // MARK: - Subject-Verb Agreement
        GrammarRule(
            category: .pronouns,
            title: "Subject-Verb Agreement",
            titleGerman: "Subjekt-Verb-Kongruenz",
            titlePersian: "تطابق فاعل و فعل",
            explanation: "The verb must agree with the subject in number. Special rules apply to certain pronouns and collective nouns.",
            explanationGerman: "Das Verb muss in der Zahl mit dem Subjekt übereinstimmen.",
            explanationPersian: "فعل باید با فاعل از نظر تعداد مطابقت کند.",
            formula: "Singular subject + singular verb | Plural subject + plural verb",
            examples: [
                GrammarExample(english: "Somebody is knocking at the door.", german: "Jemand klopft an die Tür.", persian: "یکی دارد در می‌زند."),
                GrammarExample(english: "Everybody is OK.", german: "Allen geht es gut.", persian: "همه حالشان خوب است."),
                GrammarExample(english: "One of my friends is a teacher.", german: "Einer meiner Freunde ist Lehrer.", persian: "یکی از دوستان من معلم است."),
                GrammarExample(english: "Both of them are here.", german: "Beide sind hier.", persian: "هر دوی آنها اینجا هستند."),
                GrammarExample(english: "The number of students is large.", german: "Die Anzahl der Schüler ist groß.", persian: "تعداد دانش‌آموزان زیاد است."),
                GrammarExample(english: "A number of students are playing.", german: "Einige Schüler spielen.", persian: "تعدادی از دانش‌آموزان دارند بازی می‌کنند.")
            ],
            tips: ["everybody/somebody/nobody = singular", "one of + plural noun + singular verb", "both/few/several = plural", "THE number of = singular, A number of = plural"]
        ),

        // MARK: - Verbs followed by -ing or to
        GrammarRule(
            category: .tenses,
            title: "Verbs + Gerund or Infinitive",
            titleGerman: "Verben mit Gerundium oder Infinitiv",
            titlePersian: "افعالی که با ing یا to می‌آیند",
            explanation: "Some verbs are followed by -ing (gerund), others by to + verb (infinitive). Each verb has its pattern.",
            explanationGerman: "Manche Verben werden mit -ing, andere mit 'to + Verb' verwendet.",
            explanationPersian: "برخی افعال با ing و برخی با to + فعل می‌آیند.",
            formula: "verb + verb-ing | verb + to + verb",
            examples: [
                GrammarExample(english: "I enjoy watching TV.", german: "Ich sehe gerne fern.", persian: "من از تماشای تلویزیون لذت می‌برم."),
                GrammarExample(english: "I want to buy a new bag.", german: "Ich möchte eine neue Tasche kaufen.", persian: "می‌خواهم کیف جدیدی بخرم."),
                GrammarExample(english: "Would you mind closing the door?", german: "Würde es Ihnen etwas ausmachen, die Tür zu schließen?", persian: "اشکالی ندارد در را ببندید؟"),
                GrammarExample(english: "They decided to change their house.", german: "Sie beschlossen, ihr Haus zu wechseln.", persian: "آنها تصمیم گرفتند خانه‌شان را عوض کنند.")
            ],
            tips: ["+ing: enjoy, finish, avoid, mind, keep, stop, consider, suggest", "+to: want, decide, hope, plan, promise, agree, learn", "After prepositions: always -ing"]
        ),

        // MARK: - Phrasal Verbs
        GrammarRule(
            category: .phrasalVerbs,
            title: "Phrasal Verbs (Two-word Verbs)",
            titleGerman: "Phrasal Verbs (Mehrteilige Verben)",
            titlePersian: "افعال دو کلمه‌ای",
            explanation: "Verb + particle (preposition/adverb). Some are separable, others are not. With pronouns, the pronoun goes between.",
            explanationGerman: "Verb + Partikel. Manche sind trennbar, andere nicht.",
            explanationPersian: "فعل + قید/حرف اضافه. برخی جدا شدنی هستند، برخی نه.",
            formula: "Separable: verb + particle + noun | verb + noun + particle | verb + pronoun + particle",
            examples: [
                GrammarExample(english: "I took off my coat. / I took my coat off.", german: "Ich zog meinen Mantel aus.", persian: "من کتم را در آوردم."),
                GrammarExample(english: "I took it off.", german: "Ich zog ihn aus.", persian: "من آن را در آوردم."),
                GrammarExample(english: "Please turn off the lights.", german: "Bitte mach das Licht aus.", persian: "لطفا چراغ‌ها را خاموش کن."),
                GrammarExample(english: "I took my coat it off.", isCorrect: false, correction: "I took it off. (pronoun between)")
            ],
            tips: ["Separable: take off, turn on, write down, put on, give back", "Pronoun MUST go between", "Inseparable: look after, listen to, look for"]
        ),

        // MARK: - In order to / so that
        GrammarRule(
            category: .conjunctions,
            title: "In order to / So that (Purpose)",
            titleGerman: "In order to / So that (Zweck)",
            titlePersian: "بیان هدف (In order to / So that)",
            explanation: "Used to express purpose. TO/IN ORDER TO/SO AS TO + verb. SO THAT/IN ORDER THAT + clause.",
            explanationGerman: "Drückt einen Zweck aus. TO + Verb oder SO THAT + Satz.",
            explanationPersian: "برای بیان هدف. To/In order to + فعل. So that + جمله.",
            formula: "to/in order to/so as to + verb | so that/in order that + clause",
            examples: [
                GrammarExample(english: "To get there in time, we have to take a taxi.", german: "Um rechtzeitig dort zu sein, müssen wir ein Taxi nehmen.", persian: "برای اینکه به موقع آنجا برسیم باید تاکسی بگیریم."),
                GrammarExample(english: "I wrote the address so as not to forget it.", german: "Ich schrieb die Adresse auf, um sie nicht zu vergessen.", persian: "آدرس را یادداشت کردم تا فراموش نکنم."),
                GrammarExample(english: "Be quiet so that the baby can sleep.", german: "Sei leise, damit das Baby schlafen kann.", persian: "ساکت باش تا بچه بتواند بخوابد.")
            ],
            tips: ["TO + verb (simple)", "IN ORDER TO + verb (formal)", "SO AS TO + verb (formal)", "SO THAT + subject + verb (with clause)", "Negative: so as NOT to / in order NOT to"]
        ),

        // MARK: - Commonly Confused Words
        GrammarRule(
            category: .adjectives,
            title: "Commonly Confused Words",
            titleGerman: "Häufig verwechselte Wörter",
            titlePersian: "کلمات اشتباه گرفته شده",
            explanation: "Words that look similar but have different meanings or uses.",
            explanationGerman: "Wörter, die ähnlich aussehen, aber unterschiedliche Bedeutungen haben.",
            explanationPersian: "کلماتی که شبیه به نظر می‌رسند اما معانی متفاوتی دارند.",
            formula: "—",
            examples: [
                GrammarExample(english: "affect (verb) / effect (noun)", german: "beeinflussen / die Wirkung", persian: "تأثیر گذاشتن / تأثیر"),
                GrammarExample(english: "advise (verb) / advice (noun)", german: "beraten / der Rat", persian: "نصیحت کردن / نصیحت"),
                GrammarExample(english: "beside (next to) / besides (in addition)", german: "neben / außerdem", persian: "کنار / به علاوه"),
                GrammarExample(english: "leave (forget somewhere) / forget (in mind)", german: "liegen lassen / vergessen", persian: "جا گذاشتن / فراموش کردن"),
                GrammarExample(english: "lie (down) / lay (place something)", german: "liegen / legen", persian: "دراز کشیدن / گذاشتن"),
                GrammarExample(english: "rise (go up) / raise (lift something)", german: "aufgehen / heben", persian: "طلوع کردن / بلند کردن"),
                GrammarExample(english: "sit (down) / set (place something)", german: "sitzen / setzen", persian: "نشستن / قرار دادن")
            ],
            tips: ["affect = verb, effect = noun", "lie/rise/sit = intransitive (no object)", "lay/raise/set = transitive (need object)", "beside = next to, besides = also"]
        ),

        // MARK: - Adverbs
        GrammarRule(
            category: .adverbs,
            title: "Adverbs (Formation & Position)",
            titleGerman: "Adverbien (Bildung & Stellung)",
            titlePersian: "قید (ساخت و جایگاه)",
            explanation: "Most adverbs are formed by adding -ly to adjectives. They describe verbs. Some adjectives also work as adverbs.",
            explanationGerman: "Die meisten Adverbien werden durch Anhängen von -ly an Adjektive gebildet.",
            explanationPersian: "بیشتر قیدها با اضافه کردن -ly به صفت ساخته می‌شوند.",
            formula: "Adjective + ly = Adverb | Order: manner + place + time",
            examples: [
                GrammarExample(english: "He drives carefully.", german: "Er fährt vorsichtig.", persian: "او با احتیاط رانندگی می‌کند."),
                GrammarExample(english: "She dances beautifully.", german: "Sie tanzt schön.", persian: "او زیبا می‌رقصد."),
                GrammarExample(english: "He speaks English well.", german: "Er spricht gut Englisch.", persian: "او خوب انگلیسی صحبت می‌کند."),
                GrammarExample(english: "She works hard.", german: "Sie arbeitet hart.", persian: "او سخت کار می‌کند."),
                GrammarExample(english: "She hardly works. (almost never)", german: "Sie arbeitet kaum.", persian: "او به ندرت کار می‌کند.")
            ],
            tips: ["good → well (irregular)", "Same form: fast, hard, late, early", "hard = sehr / hardly = kaum", "Order: subject + verb + object + manner + place + time", "After feel/look/taste/smell/sound: use adjective"]
        ),

        // MARK: - Among / Between
        GrammarRule(
            category: .prepositions,
            title: "Among vs Between",
            titleGerman: "Among vs Between",
            titlePersian: "Among و Between",
            explanation: "BETWEEN = two things or persons. AMONG = three or more things or persons.",
            explanationGerman: "BETWEEN = zwei Dinge. AMONG = drei oder mehr.",
            explanationPersian: "Between برای دو چیز/نفر. Among برای سه یا بیشتر.",
            formula: "between + 2 items | among + 3 or more items",
            examples: [
                GrammarExample(english: "His car is between two trees.", german: "Sein Auto steht zwischen zwei Bäumen.", persian: "ماشین او بین دو درخت است."),
                GrammarExample(english: "The soldiers divided the food among themselves.", german: "Die Soldaten teilten das Essen untereinander auf.", persian: "سربازان غذا را بین خودشان تقسیم کردند.")
            ],
            tips: ["BETWEEN = 2 items", "AMONG = 3+ items"]
        ),

        // MARK: - Each other / One another
        GrammarRule(
            category: .pronouns,
            title: "Each other vs One another",
            titleGerman: "Each other vs One another",
            titlePersian: "Each other و One another",
            explanation: "EACH OTHER = between two people. ONE ANOTHER = between three or more people.",
            explanationGerman: "EACH OTHER = zwischen zwei Personen. ONE ANOTHER = zwischen drei oder mehr.",
            explanationPersian: "Each other بین دو نفر. One another بین سه نفر یا بیشتر.",
            formula: "each other (2 people) | one another (3+ people)",
            examples: [
                GrammarExample(english: "These two students help each other.", german: "Diese zwei Schüler helfen einander.", persian: "این دو دانش‌آموز به یکدیگر کمک می‌کنند."),
                GrammarExample(english: "Those three students help one another.", german: "Diese drei Schüler helfen einander.", persian: "آن سه دانش‌آموز به همدیگر کمک می‌کنند.")
            ],
            tips: ["EACH OTHER = 2 people", "ONE ANOTHER = 3+ people", "In modern English they are often used interchangeably"]
        ),

        // MARK: - Exclamations
        GrammarRule(
            category: .questions,
            title: "Exclamations (How / What)",
            titleGerman: "Ausrufesätze (How / What)",
            titlePersian: "جملات تعجبی",
            explanation: "HOW + adjective/adverb. WHAT (a/an) + (adjective) + noun.",
            explanationGerman: "HOW + Adjektiv/Adverb. WHAT + Nomen.",
            explanationPersian: "How با صفت/قید. What با اسم.",
            formula: "How + adj/adv + S + V! | What (a/an) + (adj) + N!",
            examples: [
                GrammarExample(english: "How well she swims!", german: "Wie gut sie schwimmt!", persian: "چقدر خوب شنا می‌کند!"),
                GrammarExample(english: "How tall he is!", german: "Wie groß er ist!", persian: "او چقدر قد بلند است!"),
                GrammarExample(english: "What beautiful eyes she has!", german: "Was für schöne Augen sie hat!", persian: "او چه چشمان زیبایی دارد!"),
                GrammarExample(english: "What a beautiful girl!", german: "Was für ein schönes Mädchen!", persian: "چه دختر زیبایی!")
            ],
            tips: ["HOW + adjective/adverb", "WHAT + noun (with or without adjective)", "Use 'a/an' with singular countable nouns"]
        ),

        // MARK: - Plural Forms
        GrammarRule(
            category: .pronouns,
            title: "Plural Noun Formation",
            titleGerman: "Pluralbildung",
            titlePersian: "جمع‌بستن اسم‌ها",
            explanation: "Most nouns add -s. Some have special plural forms (regular endings & irregular plurals).",
            explanationGerman: "Die meisten Substantive bekommen -s. Manche haben unregelmäßige Pluralformen.",
            explanationPersian: "بیشتر اسم‌ها با -s جمع بسته می‌شوند. برخی شکل نامنظم دارند.",
            formula: "Regular: +s/+es | Irregular: special form",
            examples: [
                GrammarExample(english: "book → books, watch → watches", german: "Buch → Bücher, Uhr → Uhren", persian: "کتاب → کتاب‌ها"),
                GrammarExample(english: "city → cities (y → ies)", german: "Stadt → Städte", persian: "شهر → شهرها"),
                GrammarExample(english: "shelf → shelves, wife → wives (f/fe → ves)", german: "Regal → Regale", persian: "قفسه → قفسه‌ها"),
                GrammarExample(english: "man → men, child → children, tooth → teeth", german: "Mann → Männer, Kind → Kinder, Zahn → Zähne", persian: "مرد → مردان، بچه → بچه‌ها، دندان → دندان‌ها"),
                GrammarExample(english: "mouse → mice, foot → feet, sheep → sheep", german: "Maus → Mäuse, Fuß → Füße, Schaf → Schafe", persian: "موش → موش‌ها، پا → پاها، گوسفند → گوسفندان")
            ],
            tips: ["sh/ch/s/x/z/o → add -es", "consonant + y → ies", "f/fe → ves", "Irregular: man/men, child/children, tooth/teeth, mouse/mice"]
        ),

        // MARK: - Countable vs Uncountable
        GrammarRule(
            category: .pronouns,
            title: "Countable vs Uncountable Nouns",
            titleGerman: "Zählbare und unzählbare Nomen",
            titlePersian: "اسامی قابل و غیر قابل شمارش",
            explanation: "Countable nouns can be counted (one car, two cars). Uncountable nouns cannot be counted directly (water, information).",
            explanationGerman: "Zählbare Nomen können gezählt werden. Unzählbare Nomen können nicht direkt gezählt werden.",
            explanationPersian: "اسامی قابل شمارش شمارش می‌شوند. اسامی غیرقابل شمارش نه.",
            formula: "Countable: a/an, plural form | Uncountable: no a/an, no plural",
            examples: [
                GrammarExample(english: "Uncountable: water, milk, bread, rice, sugar, money, information, advice", german: "Wasser, Milch, Brot, Reis, Zucker, Geld, Information, Rat", persian: "آب، شیر، نان، برنج، شکر، پول، اطلاعات، نصیحت"),
                GrammarExample(english: "Some words can be both: glass (material/cup), time (period/instance)", german: "Manche können beides sein: glass = Glas/Trinkglas", persian: "برخی کلمات هر دو می‌شوند: glass (شیشه/لیوان)"),
                GrammarExample(english: "Languages: English, Arabic (uncountable)", german: "Sprachen sind unzählbar", persian: "زبان‌ها غیرقابل شمارش هستند")
            ],
            tips: ["Uncountable: liquids, materials, abstract nouns, languages", "Use a glass OF water, a piece OF bread", "Words ending in -ness, -ty, -nce are usually uncountable"]
        ),

        // MARK: - Personal Pronouns
        GrammarRule(
            category: .pronouns,
            title: "Personal Pronouns",
            titleGerman: "Personalpronomen",
            titlePersian: "ضمایر شخصی",
            explanation: "Subject pronouns (I, you, he), object pronouns (me, you, him), possessive adjectives (my, your, his), possessive pronouns (mine, yours, his), reflexive pronouns (myself, yourself).",
            explanationGerman: "Subjekt-, Objekt-, Possessivpronomen und Reflexivpronomen.",
            explanationPersian: "ضمایر فاعلی، مفعولی، صفات و ضمایر ملکی، ضمایر انعکاسی.",
            formula: "Subject + verb + object | possessive adj + noun | possessive pronoun (alone)",
            examples: [
                GrammarExample(english: "I see him every day.", german: "Ich sehe ihn jeden Tag.", persian: "من هر روز او را می‌بینم."),
                GrammarExample(english: "This is my book. This book is mine.", german: "Das ist mein Buch. Dieses Buch gehört mir.", persian: "این کتاب من است. این کتاب مال من است."),
                GrammarExample(english: "She did it herself.", german: "Sie hat es selbst gemacht.", persian: "او خودش این کار را کرد."),
                GrammarExample(english: "I, we, you, he, she, it, they (subject)", german: "Ich, wir, du, er, sie, es, sie", persian: "من، ما، تو، او، آنها"),
                GrammarExample(english: "me, us, you, him, her, it, them (object)", german: "mich, uns, dich, ihn, sie, es, sie", persian: "مرا، ما را، تو را..."),
                GrammarExample(english: "my, our, your, his, her, its, their (possessive adj)", german: "mein, unser, dein...", persian: "من، مال من، مال ما...")
            ],
            tips: ["Subject: I, you, he, she, it, we, they", "Object: me, you, him, her, it, us, them", "Possessive adj + noun: my book", "Possessive pronoun alone: mine", "Reflexive: myself, yourself, himself, herself..."]
        )
    ]
}
