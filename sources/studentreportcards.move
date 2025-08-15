module studentreportcards::studentcards1;

use std::string::{String, utf8};
use sui::vec_map::{Self, VecMap};

const YEAR_ALREADY_EXISTS: u64 = 1;
const YEAR_NOT_FOUND: u64 = 2;
const ID_ALREADY_IN_USE: u64 = 3;
const COURSE_ID_NOT_FOUND: u64 = 4;
const INVALID_GRADE: u64 = 5;

public struct GradeBook has key, store {
    id: UID,
    yearGrades: VecMap<u16, StudentCardsList>,
}

public struct StudentCardsList has store, drop {
    year: u16,
    cards: VecMap<u64, ReportCard> 
}

public struct ReportCard has copy, drop, store {
    term: String, //Fall,Spring
    courseID: u64,
    courseName: String,
    midtermGrade: u8,
    finalExam: u8,
    letterGrade: String, 
}


 #[allow(lint(self_transfer))]
public fun create_grade_book(ctx: &mut TxContext) {
    let yearGrades = vec_map::empty();
    let book = GradeBook {
        id: object::new(ctx),
        yearGrades,
    };
    transfer::transfer(book, tx_context::sender(ctx));
}

public fun year_card_list(gradeBook: &mut GradeBook, year: u16) {
    assert!(!gradeBook.yearGrades.contains(&year), YEAR_ALREADY_EXISTS);
    let cardList = StudentCardsList {
        year,
        cards: vec_map::empty<u64, ReportCard>()
    };
    gradeBook.yearGrades.insert(year, cardList);
}

public fun add_card(
    gradeBook: &mut GradeBook,
    year: u16,
    term: String, 
    courseID: u64, 
    courseName: String,
    midterm: u8,
    finalExam: u8) {

    assert!(gradeBook.yearGrades.contains(&year), YEAR_NOT_FOUND);

    assert!(midterm <= 100 && finalExam <= 100, INVALID_GRADE);

    let cardList = gradeBook.yearGrades.get_mut(&year);
    
    assert!(!cardList.cards.contains(&courseID), ID_ALREADY_IN_USE);

    let letterGrade = get_letter_grade(midterm, finalExam);

    let card = ReportCard {
        term,
        courseID,
        courseName,
        midtermGrade: midterm,
        finalExam,
        letterGrade,
    };
    cardList.cards.insert(courseID, card);
}

public fun get_years(gradeBook: &GradeBook): vector<u16> {
    vec_map::keys(&gradeBook.yearGrades)
}

public fun get_report_cards(gradeBook: &GradeBook, year: u16): vector<ReportCard> {
    assert!(gradeBook.yearGrades.contains(&year), YEAR_NOT_FOUND);
    let cardList = gradeBook.yearGrades.get(&year);

    let mut result = vector::empty<ReportCard>();
    let keys = vec_map::keys(&cardList.cards);
    let len = vector::length(&keys);

    let mut i = 0;
    while (i < len) {
        let key = *vector::borrow(&keys, i);
        let card_ref = cardList.cards.get(&key);
        let card_val = *card_ref;
        vector::push_back(&mut result, card_val);
        i = i + 1;
    };

    result
}

public fun remove_card(gradeBook: &mut GradeBook, year: u16, courseID: u64) {
    
    assert!(gradeBook.yearGrades.contains(&year), YEAR_NOT_FOUND);

    let cardList = gradeBook.yearGrades.get_mut(&year);
    assert!(cardList.cards.contains(&courseID), COURSE_ID_NOT_FOUND);

    cardList.cards.remove(&courseID);
}

public fun delete_card_list(gradeBook: &mut GradeBook, year: u16) {
    assert!(gradeBook.yearGrades.contains(&year), YEAR_NOT_FOUND);
    gradeBook.yearGrades.remove(&year);
}

public fun delete_gradebook(gradeBook: GradeBook) {
    let GradeBook { id, yearGrades: _ } = gradeBook;
    id.delete(); 
}

fun get_letter_grade(midterm: u8, final: u8): String {
    let avg = (midterm + final) / 2;

    if (avg >= 90) { utf8(b"A") }
    else if (avg >= 80) { utf8(b"B") }
    else if (avg >= 70) { utf8(b"C") }
    else if (avg >= 60) { utf8(b"D") }
    else { utf8(b"F") }
}
