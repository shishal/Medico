/**
 * Menu actions: validate all → upsert in dependency order → replace test_questions.
 * On validation failure: dialog of every error, zero writes.
 */

function checkConfiguration() {
  var ui = SpreadsheetApp.getUi();
  try {
    var cfg = getSupabaseConfig_();
    ui.alert(
      'Configuration OK',
      'SUPABASE_URL is set (' +
        cfg.url +
        ').\nSUPABASE_SERVICE_ROLE_KEY is set (value hidden).\n\nRun the Phase 2.2 migration before the first sync so upsert keys exist.',
      ui.ButtonSet.OK
    );
  } catch (e) {
    ui.alert('Configuration incomplete', String(e.message || e), ui.ButtonSet.OK);
  }
}

function syncToApp() {
  var ui = SpreadsheetApp.getUi();

  var validated;
  try {
    validated = validateAllTabs_();
  } catch (e) {
    ui.alert('Sync aborted', String(e.message || e), ui.ButtonSet.OK);
    return;
  }

  if (!validated.ok) {
    var maxShow = 40;
    var list = validated.errors.slice(0, maxShow).join('\n');
    if (validated.errors.length > maxShow) {
      list += '\n… and ' + (validated.errors.length - maxShow) + ' more';
    }
    ui.alert(
      'Sync aborted — nothing written',
      validated.errors.length +
        ' validation error(s). Fix these and sync again:\n\n' +
        list,
      ui.ButtonSet.OK
    );
    return;
  }

  try {
    getSupabaseConfig_(); // fail fast before writes if props missing
    var summary = performSync_(validated.data);
    var warningBlock = '';
    if (validated.warnings && validated.warnings.length) {
      warningBlock =
        '\n\nWarnings (sync still wrote):\n' + validated.warnings.slice(0, 15).join('\n');
    }
    ui.alert(
      'Sync complete',
      'Upserted:\n' +
        '• Subjects: ' +
        summary.subjects +
        '\n• Topics: ' +
        summary.topics +
        '\n• Questions: ' +
        summary.questions +
        '\n• Tests: ' +
        summary.tests +
        '\n• Test question links replaced for ' +
        summary.testsLinked +
        ' test(s).\n\nRun Sync again with unchanged data — counts should stay the same (no duplicates).' +
        warningBlock,
      ui.ButtonSet.OK
    );
  } catch (e) {
    ui.alert(
      'Sync failed during write',
      'Validation had passed, but a Supabase write failed. Check the migration was applied and inspect the error:\n\n' +
        String(e.message || e),
      ui.ButtonSet.OK
    );
  }
}

function performSync_(data) {
  var phaseReturned = supabaseSelect_('mbbs_phases', '?select=id,code');
  var phaseIdByCode = {};
  (phaseReturned || []).forEach(function (row) {
    phaseIdByCode[normKey_(row.code)] = row.id;
  });

  // 1) Subjects
  var subjectRows = data.subjects.map(function (s) {
    var row = { name: s.name, display_order: s.display_order };
    if (s.phase_code && phaseIdByCode[normKey_(s.phase_code)]) {
      row.mbbs_phase_id = phaseIdByCode[normKey_(s.phase_code)];
    }
    return row;
  });
  var subjectReturned = supabaseUpsert_('subjects', subjectRows, 'name');
  var subjectIdByKey = {};
  subjectReturned.forEach(function (row) {
    subjectIdByKey[normKey_(row.name)] = row.id;
  });
  // Ensure every sheet subject is mapped (return=representation should include all).
  data.subjects.forEach(function (s) {
    if (!subjectIdByKey[normKey_(s.name)]) {
      throw new Error('Subject upsert did not return id for "' + s.name + '"');
    }
  });

  // 2) Topics
  var topicRows = data.topics.map(function (t) {
    var sid = subjectIdByKey[normKey_(t.subject_name)];
    if (!sid) throw new Error('Missing subject id for topic "' + t.name + '"');
    return { subject_id: sid, name: t.name, display_order: t.display_order };
  });
  var topicReturned = supabaseUpsert_('topics', topicRows, 'subject_id,name');
  var topicIdByKey = {};
  topicReturned.forEach(function (row) {
    topicIdByKey[normKey_(row.name)] = row.id;
  });
  data.topics.forEach(function (t) {
    if (!topicIdByKey[normKey_(t.name)]) {
      throw new Error('Topic upsert did not return id for "' + t.name + '"');
    }
  });

  var lessonIdByExt = {};
  if (data.ug && data.ug.lessons && data.ug.lessons.length) {
    var preUg = syncUgCatalog_(data.ug, subjectIdByKey, topicIdByKey, {});
    // Lessons exist; re-read ids for question.lesson_id
    var lessonReturned = supabaseSelect_('lessons', '?select=id,external_id');
    (lessonReturned || []).forEach(function (row) {
      lessonIdByExt[normKey_(row.external_id)] = row.id;
    });
    phaseIdByCode = preUg.phaseIdByCode || phaseIdByCode;
  }

  // 3) Questions
  var questionRows = data.questions.map(function (q) {
    var tid = topicIdByKey[normKey_(q.topic_name)];
    if (!tid) {
      // Should be impossible after validation — still fail loudly.
      throw new Error('Questions: no topic UUID for topic_name "' + q.topic_name + '" (sheet row ' + q.__row + ')');
    }
    var isMcq = (q.kind || 'mcq') === 'mcq';
    return {
      external_id: q.external_id,
      topic_id: tid,
      lesson_id: q.lesson_external_id ? lessonIdByExt[normKey_(q.lesson_external_id)] || null : null,
      kind: q.kind || 'mcq',
      question_text: q.question_text,
      option_a: isMcq ? q.option_a : emptyToNull_(q.option_a),
      option_b: isMcq ? q.option_b : emptyToNull_(q.option_b),
      option_c: isMcq ? q.option_c : emptyToNull_(q.option_c),
      option_d: isMcq ? q.option_d : emptyToNull_(q.option_d),
      correct_option: isMcq ? q.correct_option : emptyToNull_(q.correct_option),
      explanation_text: q.explanation_text,
      explanation_video_url: q.explanation_video_url,
      image_url: q.image_url,
      difficulty: q.difficulty,
      source: q.source,
      marks: q.marks == null || q.marks === '' ? null : Number(q.marks),
      required_plan: q.required_plan,
      is_active: q.is_active,
    };
  });
  var questionReturned = supabaseUpsert_('questions', questionRows, 'external_id');
  var questionIdByExt = {};
  questionReturned.forEach(function (row) {
    questionIdByExt[normKey_(row.external_id)] = row.id;
  });
  data.questions.forEach(function (q) {
    if (!questionIdByExt[normKey_(q.external_id)]) {
      throw new Error('Question upsert did not return id for external_id "' + q.external_id + '"');
    }
  });

  var sampleRows = [];
  data.questions.forEach(function (q) {
    if (!q.sample_answer_text) return;
    sampleRows.push({
      question_id: questionIdByExt[normKey_(q.external_id)],
      body: q.sample_answer_text,
    });
  });
  if (sampleRows.length) {
    supabaseUpsert_('question_sample_answers', sampleRows, 'question_id');
  }

  if (data.ug && data.ug.universities && data.ug.universities.length) {
    syncUgCatalog_(data.ug, subjectIdByKey, topicIdByKey, questionIdByExt);
  }

  // 4) Tests
  // sheet_key (not title) is the PostgREST conflict target. Phase 4B dropped
  // UNIQUE(title) so practice sessions can share "Practice Session"; PostgREST
  // cannot ON CONFLICT on that partial unique index (Postgres 42P10).
  var testRows = data.tests.map(function (t) {
    var payload = {
      sheet_key: t.title,
      title: t.title,
      description: t.description,
      test_type: t.test_type,
      subject_id: t.subject_name ? subjectIdByKey[normKey_(t.subject_name)] : null,
      required_plan: t.required_plan,
      is_sectional: t.is_sectional,
      section_count: t.section_count,
      questions_per_section: t.questions_per_section,
      section_duration_minutes: t.section_duration_minutes,
      total_duration_minutes: t.total_duration_minutes,
      total_questions: t.total_questions,
      correct_marks: t.correct_marks,
      incorrect_marks: t.incorrect_marks,
      unattempted_marks: t.unattempted_marks,
      is_live: t.is_live,
      live_start_at: t.live_start_at,
      live_end_at: t.live_end_at,
      is_active: t.is_active,
    };
    if (t.subject_name && !payload.subject_id) {
      throw new Error('Missing subject id for test "' + t.title + '"');
    }
    return payload;
  });
  var testReturned = supabaseUpsert_('tests', testRows, 'sheet_key');
  var testIdByKey = {};
  testReturned.forEach(function (row) {
    testIdByKey[normKey_(row.title)] = row.id;
  });
  data.tests.forEach(function (t) {
    if (!testIdByKey[normKey_(t.title)]) {
      throw new Error('Test upsert did not return id for "' + t.title + '"');
    }
  });

  // 5) Replace test_questions for every test that appears in the TestQuestions tab
  //    (and for tests with zero links, clear leftovers if total_questions is 0).
  var testsToRelink = {};
  data.testQuestions.forEach(function (tq) {
    testsToRelink[normKey_(tq.test_title)] = true;
  });
  data.tests.forEach(function (t) {
    if ((t.total_questions || 0) === 0) testsToRelink[normKey_(t.title)] = true;
  });

  Object.keys(testsToRelink).forEach(function (key) {
    var testId = testIdByKey[key];
    if (!testId) throw new Error('No test id for relink key ' + key);
    supabaseDeleteEq_('test_questions', 'test_id', testId);
  });

  var linkRows = data.testQuestions.map(function (tq) {
    var testId = testIdByKey[normKey_(tq.test_title)];
    var questionId = questionIdByExt[normKey_(tq.question_external_id)];
    if (!testId || !questionId) {
      throw new Error(
        'TestQuestions row ' + tq.__row + ': could not resolve test/question UUID'
      );
    }
    return {
      test_id: testId,
      question_id: questionId,
      section_number: tq.section_number,
      order_index: tq.order_index,
    };
  });
  if (linkRows.length) {
    supabaseInsert_('test_questions', linkRows);
  }

  return {
    subjects: subjectRows.length,
    topics: topicRows.length,
    questions: questionRows.length,
    tests: testRows.length,
    testsLinked: Object.keys(testsToRelink).length,
  };
}
