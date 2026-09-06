/**
 * Wide Questions tab: one row = one appearance / textbook citation.
 * Sync still writes normalized Supabase tables.
 */

function validateWideSheet_(errors, warnings, questionsRaw) {
  ensureUgGlobals_();
  var hdr = requireHeaders_(TAB.QUESTIONS, questionsRaw.headers, [
    'external_id',
    'university_code',
    'phase_code',
    'subject_name',
    'topic_name',
    'lesson_name',
    'kind',
    'question_text',
    'difficulty',
    'required_plan',
    'is_active',
  ]);
  if (hdr) errors.push(hdr);

  var uniRaw = readTabObjects_(TAB.UNIVERSITIES);
  var colRaw = readTabObjects_(TAB.COLLEGES);
  var tbRaw = sheetExists_(TAB.TEXTBOOKS)
    ? readTabObjects_(TAB.TEXTBOOKS)
    : { headers: [], rows: [] };
  var lrRaw = sheetExists_(TAB.LESSON_RESOURCES)
    ? readTabObjects_(TAB.LESSON_RESOURCES)
    : { headers: [], rows: [] };

  hdr = requireHeaders_(TAB.UNIVERSITIES, uniRaw.headers, [
    'code',
    'name',
    'state',
    'slug',
  ]);
  if (hdr) errors.push(hdr);
  hdr = requireHeaders_(TAB.COLLEGES, colRaw.headers, ['university_code', 'name']);
  if (hdr) errors.push(hdr);

  var universities = [];
  var uniByCode = {};
  uniRaw.rows.forEach(function (row) {
    var code = trimStr_(row.code).toUpperCase();
    var name = trimStr_(row.name);
    var state = trimStr_(row.state);
    var slug = trimStr_(row.slug).toLowerCase();
    var isFallback = parseOptionalBool_(
      row.is_fallback,
      TAB.UNIVERSITIES,
      row.__row,
      'is_fallback',
      errors,
      code === 'KUHS'
    );
    if (!code || !name || !state || !slug) {
      errors.push(TAB.UNIVERSITIES + ' row ' + row.__row + ': code, name, state, slug are required');
      return;
    }
    uniByCode[normKey_(code)] = code;
    universities.push({
      code: code,
      name: name,
      state: state,
      slug: slug,
      is_fallback: !!isFallback,
    });
  });

  var colleges = [];
  colRaw.rows.forEach(function (row) {
    var ucode = trimStr_(row.university_code).toUpperCase();
    var name = trimStr_(row.name);
    if (!uniByCode[normKey_(ucode)]) {
      errors.push(TAB.COLLEGES + ' row ' + row.__row + ': university_code not on Universities tab');
    }
    if (!name) errors.push(TAB.COLLEGES + ' row ' + row.__row + ': name is required');
    colleges.push({ university_code: ucode, name: name });
  });

  var textbooks = [];
  var tbByKey = {};
  tbRaw.rows.forEach(function (row) {
    var key = trimStr_(row.sheet_key);
    var title = trimStr_(row.title);
    if (!key || !title) {
      errors.push(TAB.TEXTBOOKS + ' row ' + row.__row + ': sheet_key and title are required');
      return;
    }
    tbByKey[normKey_(key)] = key;
    textbooks.push({
      sheet_key: key,
      title: title,
      authors: optionalTrimmed_(row.authors),
      edition: optionalTrimmed_(row.edition),
    });
  });

  var subjects = [];
  var subjectByKey = {};
  var topics = [];
  var topicByKey = {};
  var topicOrder = {};
  var lessons = [];
  var lessonByKey = {};
  var questions = [];
  var questionByExt = {};
  var examPapers = [];
  var paperByKey = {};
  var appearances = [];
  var seenApp = {};
  var textbookRefs = [];
  var seenRef = {};

  questionsRaw.rows.forEach(function (row) {
    var ext = trimStr_(row.external_id);
    var uni = trimStr_(row.university_code).toUpperCase();
    var phase = trimStr_(row.phase_code).toLowerCase();
    var subjectName = trimStr_(row.subject_name);
    var topicName = trimStr_(row.topic_name);
    var lessonName = trimStr_(row.lesson_name);
    var kind = trimStr_(row.kind).toLowerCase() || 'mcq';
    var stem = trimStr_(row.question_text);
    if (!ext) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': external_id is required');
    if (!subjectName) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': subject_name is required');
    if (!topicName) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': topic_name is required');
    if (!lessonName) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': lesson_name is required');
    if (!stem) errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': question_text is required');
    if (uni && !uniByCode[normKey_(uni)]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': university_code not on Universities tab');
    }
    if (phase && !PHASE_CODES[phase]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': phase_code must be a known mbbs_phase_code');
    }
    if (!QUESTION_KINDS[kind]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': kind must be mcq or pyq_theory');
    }
    var difficulty = trimStr_(row.difficulty).toLowerCase();
    var plan = trimStr_(row.required_plan).toLowerCase();
    var isActive = parseBool_(row.is_active, TAB.QUESTIONS, row.__row, 'is_active', errors);
    if (difficulty && !DIFFICULTIES[difficulty]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': difficulty must be easy, medium, or hard');
    }
    if (plan && !PLANS[plan]) {
      errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': required_plan must be free, pro, or elite');
    }

    var sKey = normKey_(subjectName);
    if (subjectName && !subjectByKey[sKey]) {
      subjectByKey[sKey] = {
        name: subjectName,
        display_order: Object.keys(subjectByKey).length + 1,
        phase_code: phase || null,
        __row: row.__row,
      };
      subjects.push(subjectByKey[sKey]);
    }
    var tKey = normKey_(topicName);
    if (topicName && !topicByKey[tKey]) {
      topicOrder[sKey] = (topicOrder[sKey] || 0) + 1;
      topicByKey[tKey] = {
        name: topicName,
        subject_name: subjectName,
        display_order: topicOrder[sKey],
        __row: row.__row,
      };
      topics.push(topicByKey[tKey]);
    }
    var lessonExt = inventLessonExternalId_(subjectName, topicName, lessonName);
    var lKey = normKey_(lessonExt);
    if (lessonName && !lessonByKey[lKey]) {
      lessonByKey[lKey] = {
        external_id: lessonExt,
        topic_name: topicName,
        name: lessonName,
        display_order: Object.keys(lessonByKey).length + 1,
        required_plan: plan || 'free',
        is_active: isActive !== false,
      };
      lessons.push(lessonByKey[lKey]);
    }

    if (kind === 'mcq' && !questionByExt[normKey_(ext)]) {
      ['option_a', 'option_b', 'option_c', 'option_d'].forEach(function (field) {
        if (!trimStr_(row[field])) {
          errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': ' + field + ' is required');
        }
      });
      var correct = trimStr_(row.correct_option).toUpperCase();
      if (!CORRECT_OPTIONS[correct]) {
        errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': correct_option must be A, B, C, or D');
      }
    }

    if (ext && !questionByExt[normKey_(ext)]) {
      questionByExt[normKey_(ext)] = true;
      var marksRaw = trimStr_(row.marks);
      questions.push({
        external_id: ext,
        topic_name: topicName,
        question_text: stem,
        option_a: trimStr_(row.option_a),
        option_b: trimStr_(row.option_b),
        option_c: trimStr_(row.option_c),
        option_d: trimStr_(row.option_d),
        correct_option: trimStr_(row.correct_option).toUpperCase(),
        explanation_text: trimStr_(row.explanation_text),
        difficulty: difficulty || 'medium',
        required_plan: plan || 'free',
        is_active: isActive !== false,
        kind: kind,
        lesson_external_id: lessonByKey[lKey] ? lessonByKey[lKey].external_id : '',
        marks: marksRaw === '' ? null : Number(marksRaw),
        sample_answer_text: trimStr_(row.sample_answer_text),
        __row: row.__row,
      });
    }

    var year = trimStr_(row.exam_year);
    var paperName = trimStr_(row.paper_name);
    if (year && paperName && uni) {
      var paperExt = 'EP-' + uni + '-' + sKey.replace(/[^a-z0-9]+/g, '-').toUpperCase() + '-' + year + '-' + paperName.replace(/\s+/g, '-').toUpperCase();
      paperExt = paperExt.substring(0, 80);
      var pKey = normKey_(paperExt);
      if (!paperByKey[pKey]) {
        var examType = trimStr_(row.exam_type).toLowerCase() || 'university';
        if (!EXAM_TYPES[examType]) examType = 'university';
        paperByKey[pKey] = true;
        examPapers.push({
          external_id: paperExt,
          university_code: uni,
          subject_name: subjectName,
          exam_year: Number(year),
          paper_name: paperName,
          exam_type: examType,
        });
      }
      var appKey = normKey_(ext) + '|' + pKey;
      if (!seenApp[appKey]) {
        seenApp[appKey] = true;
        appearances.push({
          question_external_id: ext,
          paper_external_id: paperExt,
        });
      }
    }

    var tbKey = trimStr_(row.textbook_key);
    var page = trimStr_(row.page);
    if (tbKey && page) {
      if (!tbByKey[normKey_(tbKey)]) {
        errors.push(TAB.QUESTIONS + ' row ' + row.__row + ': textbook_key not on Textbooks tab');
      }
      var refKey = normKey_(ext) + '|' + normKey_(tbKey) + '|' + page;
      if (!seenRef[refKey]) {
        seenRef[refKey] = true;
        textbookRefs.push({
          question_external_id: ext,
          textbook_key: tbKey,
          page: Number(page),
          section_heading: optionalTrimmed_(row.section_heading),
        });
      }
    }
  });

  var lessonResources = [];
  lrRaw.rows.forEach(function (row) {
    var title = trimStr_(row.title);
    var url = requireHttpsUrl_(row.url, TAB.LESSON_RESOURCES, row.__row, 'url', errors);
    lessonResources.push({
      lesson_external_id: trimStr_(row.lesson_external_id),
      title: title,
      url: url,
      source_label: optionalTrimmed_(row.source_label),
      display_order: parseIntRequired_(row.display_order, TAB.LESSON_RESOURCES, row.__row, 'display_order', errors),
      is_free: parseBool_(row.is_free, TAB.LESSON_RESOURCES, row.__row, 'is_free', errors),
    });
  });

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
      tests: [],
      testQuestions: [],
      ug: {
        universities: universities,
        colleges: colleges,
        phases: [],
        lessons: lessons,
        lessonResources: lessonResources,
        textbooks: textbooks,
        examPapers: examPapers,
        appearances: appearances,
        textbookRefs: textbookRefs,
        questionResources: [],
      },
    },
  };
}
