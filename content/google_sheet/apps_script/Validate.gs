/**
 * Validate every tab before any Supabase write.
 * Returns { ok, errors, data } where data is normalized payloads for upsert.
 */

function validateAllTabs_() {
  var errors = [];
  var warnings = [];

  var subjectsRaw = readTabObjects_(TAB.SUBJECTS);
  var topicsRaw = readTabObjects_(TAB.TOPICS);
  var questionsRaw = readTabObjects_(TAB.QUESTIONS);
  var testsRaw = sheetExists_(TAB.TESTS)
    ? readTabObjects_(TAB.TESTS)
    : { headers: [], rows: [] };
  var tqRaw = sheetExists_(TAB.TEST_QUESTIONS)
    ? readTabObjects_(TAB.TEST_QUESTIONS)
    : { headers: [], rows: [] };

  var hdr;
  hdr = requireHeaders_(TAB.SUBJECTS, subjectsRaw.headers, ['name', 'display_order']);
  if (hdr) errors.push(hdr);
  // phase_code is optional until the UG tabs are added; warn via per-row checks.
  hdr = requireHeaders_(TAB.TOPICS, topicsRaw.headers, ['subject_name', 'name', 'display_order']);
  if (hdr) errors.push(hdr);
  hdr = requireHeaders_(TAB.QUESTIONS, questionsRaw.headers, [
    'external_id',
    'topic_name',
    'question_text',
    'option_a',
    'option_b',
    'option_c',
    'option_d',
    'correct_option',
    'difficulty',
    'required_plan',
    'is_active',
  ]);
  if (hdr) errors.push(hdr);
  if (testsRaw.headers.length) {
    hdr = requireHeaders_(TAB.TESTS, testsRaw.headers, [
      'title',
      'test_type',
      'required_plan',
      'is_sectional',
      'section_count',
      'total_duration_minutes',
      'total_questions',
      'correct_marks',
      'incorrect_marks',
      'unattempted_marks',
      'is_live',
      'is_active',
    ]);
    if (hdr) errors.push(hdr);
  }
  if (tqRaw.headers.length) {
    hdr = requireHeaders_(TAB.TEST_QUESTIONS, tqRaw.headers, [
      'test_title',
      'question_external_id',
      'section_number',
      'order_index',
    ]);
    if (hdr) errors.push(hdr);
  }

  if (errors.length) {
    return { ok: false, errors: errors, data: null };
  }

  // --- Subjects ---
  var subjects = [];
  var subjectByKey = {}; // norm name → { name, display_order }
  subjectsRaw.rows.forEach(function (row) {
    var name = trimStr_(row.name);
    var key = normKey_(name);
    var displayOrder = parseIntRequired_(row.display_order, TAB.SUBJECTS, row.__row, 'display_order', errors);
    if (!name) {
      errors.push(TAB.SUBJECTS + ' row ' + row.__row + ': name is required');
      return;
    }
    if (subjectByKey[key]) {
      errors.push(TAB.SUBJECTS + ' row ' + row.__row + ': duplicate name "' + name + '" (names compared case-insensitively)');
      return;
    }
    subjectByKey[key] = { name: name, display_order: displayOrder };
    var phaseCode = optionalTrimmed_(row.phase_code)
      ? trimStr_(row.phase_code).toLowerCase()
      : null;
    if (phaseCode && !PHASE_CODES[phaseCode]) {
      errors.push(TAB.SUBJECTS + ' row ' + row.__row + ': phase_code must be phase1, phase2, phase3_part1, or phase3_part2');
    }
    subjects.push({
      name: name,
      display_order: displayOrder,
      phase_code: phaseCode,
      __row: row.__row,
    });
  });

  // --- Topics ---
  var topics = [];
  var topicByKey = {}; // norm topic name → { name, subject_name, ... }
  var topicSubjectPair = {};
  topicsRaw.rows.forEach(function (row) {
    var subjectName = trimStr_(row.subject_name);
    var name = trimStr_(row.name);
    var displayOrder = parseIntRequired_(row.display_order, TAB.TOPICS, row.__row, 'display_order', errors);
    if (!subjectName) {
      errors.push(TAB.TOPICS + ' row ' + row.__row + ': subject_name is required');
      return;
    }
    if (!name) {
      errors.push(TAB.TOPICS + ' row ' + row.__row + ': name is required');
      return;
    }
    if (!subjectByKey[normKey_(subjectName)]) {
      errors.push(
        TAB.TOPICS +
          ' row ' +
          row.__row +
          ': subject_name "' +
          subjectName +
          '" not found on Subjects tab'
      );
    }
    var pairKey = normKey_(subjectName) + '|' + normKey_(name);
    if (topicSubjectPair[pairKey]) {
      errors.push(TAB.TOPICS + ' row ' + row.__row + ': duplicate topic "' + name + '" under subject "' + subjectName + '"');
      return;
    }
    topicSubjectPair[pairKey] = true;

    // Questions look up by topic_name alone — require globally unique topic names.
    var tKey = normKey_(name);
    if (topicByKey[tKey] && normKey_(topicByKey[tKey].subject_name) !== normKey_(subjectName)) {
      errors.push(
        TAB.TOPICS +
          ' row ' +
          row.__row +
          ': topic name "' +
          name +
          '" already used under another subject; topic_name on Questions must be unique'
      );
      return;
    }
    topicByKey[tKey] = {
      name: name,
      subject_name: subjectByKey[normKey_(subjectName)]
        ? subjectByKey[normKey_(subjectName)].name
        : subjectName,
      display_order: displayOrder,
    };
    topics.push({
      name: name,
      subject_name: topicByKey[tKey].subject_name,
      display_order: displayOrder,
      __row: row.__row,
    });
  });

  // --- Questions ---
  var questions = [];
  var questionByExt = {};
  questionsRaw.rows.forEach(function (row) {
    var externalId = trimStr_(row.external_id);
    var topicName = trimStr_(row.topic_name);
    var questionText = trimStr_(row.question_text);
    var optionA = trimStr_(row.option_a);
    var optionB = trimStr_(row.option_b);
    var optionC = trimStr_(row.option_c);
    var optionD = trimStr_(row.option_d);
    var correct = trimStr_(row.correct_option).toUpperCase();
    var difficulty = trimStr_(row.difficulty).toLowerCase();
    var plan = trimStr_(row.required_plan).toLowerCase();
    var isActive = parseBool_(row.is_active, TAB.QUESTIONS, row.__row, 'is_active', errors);

    if (!externalId) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': external_id is required');
    } else if (questionByExt[normKey_(externalId)]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': duplicate external_id "' + externalId + '"');
    }

    if (!topicName) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': topic_name is required');
    } else if (!topicByKey[normKey_(topicName)]) {
      errors.push(
        TAB.QUESTIONS +
          ' row ' +
          row.__row +
          ': topic_name "' +
          topicName +
          '" not found on Topics tab (trim/case-insensitive match)'
      );
    }

    if (!questionText) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': question_text is required');
    }
    var kind = trimStr_(row.kind).toLowerCase() || 'mcq';
    if (!QUESTION_KINDS[kind]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': kind must be mcq or pyq_theory');
    }

    if (kind === 'mcq') {
      if (!optionA) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': option_a is required');
      if (!optionB) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': option_b is required');
      if (!optionC) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': option_c is required');
      if (!optionD) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': option_d is required');

      if (!CORRECT_OPTIONS[correct]) {
        errors.push(
          TAB.QUESTIONS +
            ' row ' +
            row.__row +
            ': correct_option must be exactly A, B, C, or D (got "' +
            trimStr_(row.correct_option) +
            '")'
        );
      }
    }

    var sample = optionalTrimmed_(row.sample_answer_text);
    if (sample) {
      var wordCount = sample.split(/\s+/).filter(Boolean).length;
      if (wordCount > 400) {
        warnings.push(
          TAB.QUESTIONS +
            ' row ' +
            row.__row +
            ': sample_answer_text is ~' +
            wordCount +
            ' words (target ~250; over 400 is a warning, not a reject)'
        );
      }
    }
    if (!DIFFICULTIES[difficulty]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': difficulty must be easy, medium, or hard');
    }
    if (!PLANS[plan]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': required_plan must be free, pro, or elite');
    }

    if (externalId) questionByExt[normKey_(externalId)] = true;

    questions.push({
      external_id: externalId,
      topic_name: topicByKey[normKey_(topicName)] ? topicByKey[normKey_(topicName)].name : topicName,
      question_text: questionText,
      option_a: optionA,
      option_b: optionB,
      option_c: optionC,
      option_d: optionD,
      correct_option: correct,
      explanation_text: optionalTrimmed_(row.explanation_text),
      explanation_video_url: optionalTrimmed_(row.explanation_video_url),
      image_url: optionalTrimmed_(row.image_url),
      difficulty: difficulty,
      source: optionalTrimmed_(row.source),
      required_plan: plan,
      is_active: isActive,
      kind: kind,
      lesson_external_id: optionalTrimmed_(row.lesson_external_id),
      marks: optionalTrimmed_(row.marks),
      sample_answer_text: optionalTrimmed_(row.sample_answer_text),
      __row: row.__row,
    });
  });

  // --- Tests ---
  var tests = [];
  var testByKey = {};
  testsRaw.rows.forEach(function (row) {
    var title = trimStr_(row.title);
    var testType = trimStr_(row.test_type).toLowerCase();
    var subjectName = trimStr_(row.subject_name);
    var plan = trimStr_(row.required_plan).toLowerCase();
    var isSectional = parseBool_(row.is_sectional, TAB.TESTS, row.__row, 'is_sectional', errors);
    var sectionCount = parseIntRequired_(row.section_count, TAB.TESTS, row.__row, 'section_count', errors);
    var totalDuration = parseIntRequired_(
      row.total_duration_minutes,
      TAB.TESTS,
      row.__row,
      'total_duration_minutes',
      errors
    );
    var totalQuestions = parseIntRequired_(row.total_questions, TAB.TESTS, row.__row, 'total_questions', errors);
    var correctMarks = parseNumberRequired_(row.correct_marks, TAB.TESTS, row.__row, 'correct_marks', errors);
    var incorrectMarks = parseNumberRequired_(row.incorrect_marks, TAB.TESTS, row.__row, 'incorrect_marks', errors);
    var unattemptedMarks = parseNumberRequired_(
      row.unattempted_marks,
      TAB.TESTS,
      row.__row,
      'unattempted_marks',
      errors
    );
    var isLive = parseBool_(row.is_live, TAB.TESTS, row.__row, 'is_live', errors);
    var isActive = parseBool_(row.is_active, TAB.TESTS, row.__row, 'is_active', errors);

    if (!title) {
      errors.push(TAB.TESTS + ' row ' + row.__row + ': title is required');
    } else if (testByKey[normKey_(title)]) {
      errors.push(TAB.TESTS + ' row ' + row.__row + ': duplicate title "' + title + '"');
    }

    if (!TEST_TYPES[testType]) {
      errors.push(TAB.TESTS + ' row ' + row.__row + ': test_type must be mini, subject, mock, or grand');
    }
    if (!PLANS[plan]) {
      errors.push(TAB.TESTS + ' row ' + row.__row + ': required_plan must be free, pro, or elite');
    }

    if (subjectName && !subjectByKey[normKey_(subjectName)]) {
      errors.push(TAB.TESTS + ' row ' + row.__row + ': subject_name "' + subjectName + '" not found on Subjects tab');
    }

    var qps = null;
    var sectionDuration = null;
    if (isSectional === true) {
      qps = parseIntRequired_(row.questions_per_section, TAB.TESTS, row.__row, 'questions_per_section', errors);
      sectionDuration = parseIntRequired_(
        row.section_duration_minutes,
        TAB.TESTS,
        row.__row,
        'section_duration_minutes',
        errors
      );
    } else if (trimStr_(row.questions_per_section) !== '') {
      qps = parseIntRequired_(row.questions_per_section, TAB.TESTS, row.__row, 'questions_per_section', errors);
    }
    if (!isSectional && trimStr_(row.section_duration_minutes) !== '') {
      sectionDuration = parseIntRequired_(
        row.section_duration_minutes,
        TAB.TESTS,
        row.__row,
        'section_duration_minutes',
        errors
      );
    }

    if (title) testByKey[normKey_(title)] = title;

    tests.push({
      title: title,
      description: optionalTrimmed_(row.description),
      test_type: testType,
      subject_name: subjectName
        ? subjectByKey[normKey_(subjectName)]
          ? subjectByKey[normKey_(subjectName)].name
          : subjectName
        : null,
      required_plan: plan,
      is_sectional: isSectional,
      section_count: sectionCount,
      questions_per_section: qps,
      section_duration_minutes: sectionDuration,
      total_duration_minutes: totalDuration,
      total_questions: totalQuestions,
      correct_marks: correctMarks,
      incorrect_marks: incorrectMarks,
      unattempted_marks: unattemptedMarks,
      is_live: isLive,
      live_start_at: optionalTrimmed_(row.live_start_at),
      live_end_at: optionalTrimmed_(row.live_end_at),
      is_active: isActive,
      __row: row.__row,
    });
  });

  // --- TestQuestions ---
  var testQuestions = [];
  var tqPair = {};
  var countByTest = {};
  tqRaw.rows.forEach(function (row) {
    var testTitle = trimStr_(row.test_title);
    var qExt = trimStr_(row.question_external_id);
    var sectionNumber = parseIntRequired_(row.section_number, TAB.TEST_QUESTIONS, row.__row, 'section_number', errors);
    var orderIndex = parseIntRequired_(row.order_index, TAB.TEST_QUESTIONS, row.__row, 'order_index', errors);

    if (!testTitle) {
      errors.push(TAB.TEST_QUESTIONS + ' row ' + row.__row + ': test_title is required');
    } else if (!testByKey[normKey_(testTitle)]) {
      errors.push(
        TAB.TEST_QUESTIONS +
          ' row ' +
          row.__row +
          ': test_title "' +
          testTitle +
          '" not found on Tests tab'
      );
    }

    if (!qExt) {
      errors.push(TAB.TEST_QUESTIONS + ' row ' + row.__row + ': question_external_id is required');
    } else if (!questionByExt[normKey_(qExt)]) {
      errors.push(
        TAB.TEST_QUESTIONS +
          ' row ' +
          row.__row +
          ': question_external_id "' +
          qExt +
          '" not found on Questions tab'
      );
    }

    var pair = normKey_(testTitle) + '|' + normKey_(qExt);
    if (tqPair[pair]) {
      errors.push(
        TAB.TEST_QUESTIONS +
          ' row ' +
          row.__row +
          ': duplicate link for test "' +
          testTitle +
          '" + question "' +
          qExt +
          '"'
      );
    }
    tqPair[pair] = true;

    var tk = normKey_(testTitle);
    countByTest[tk] = (countByTest[tk] || 0) + 1;

    testQuestions.push({
      test_title: testByKey[normKey_(testTitle)] || testTitle,
      question_external_id: qExt,
      section_number: sectionNumber,
      order_index: orderIndex,
      __row: row.__row,
    });
  });

  tests.forEach(function (t) {
    var linked = countByTest[normKey_(t.title)] || 0;
    if (t.total_questions != null && linked !== t.total_questions) {
      errors.push(
        TAB.TESTS +
          ' row ' +
          t.__row +
          ': total_questions is ' +
          t.total_questions +
          ' but TestQuestions has ' +
          linked +
          ' row(s) for "' +
          t.title +
          '"'
      );
    }
  });

  var theoryByExt = {};
  questions.forEach(function (q) {
    if (q.kind === 'pyq_theory' && q.external_id) {
      theoryByExt[normKey_(q.external_id)] = q.__row;
    }
  });
  var ug = validateUgCatalog_(errors, questionByExt, theoryByExt);
  if (errors.length) {
    return { ok: false, errors: errors, warnings: warnings, data: null };
  }

  return {
    ok: true,
    errors: [],
    warnings: warnings,
    data: {
      subjects: subjects,
      topics: topics,
      questions: questions,
      tests: tests,
      testQuestions: testQuestions,
      ug: ug,
    },
  };
}
