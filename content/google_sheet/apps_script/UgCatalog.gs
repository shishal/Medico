/**
 * UG catalog tabs: universities, colleges, phases, lessons, papers, refs.
 */

function requireHttpsUrl_(raw, tab, row, field, errors) {
  var url = trimStr_(raw);
  if (!url) {
    errors.push(tab + ' row ' + row + ': ' + field + ' is required');
    return null;
  }
  if (url.indexOf('https://') !== 0) {
    errors.push(tab + ' row ' + row + ': ' + field + ' must start with https://');
    return null;
  }
  return url;
}

function validateUgCatalog_(errors, questionByExt, theoryByExt) {
  var empty = {
    universities: [],
    colleges: [],
    phases: [],
    lessons: [],
    lessonResources: [],
    textbooks: [],
    examPapers: [],
    appearances: [],
    textbookRefs: [],
    questionResources: [],
  };

  if (!sheetExists_(TAB.UNIVERSITIES)) {
    return empty;
  }

  var uniRaw = readTabObjects_(TAB.UNIVERSITIES);
  var colRaw = readTabObjects_(TAB.COLLEGES);
  var phRaw = readTabObjects_(TAB.PHASES);
  var lesRaw = readTabObjects_(TAB.LESSONS);
  var lrRaw = sheetExists_(TAB.LESSON_RESOURCES)
    ? readTabObjects_(TAB.LESSON_RESOURCES)
    : { headers: [], rows: [] };
  var tbRaw = sheetExists_(TAB.TEXTBOOKS)
    ? readTabObjects_(TAB.TEXTBOOKS)
    : { headers: [], rows: [] };
  var epRaw = sheetExists_(TAB.EXAM_PAPERS)
    ? readTabObjects_(TAB.EXAM_PAPERS)
    : { headers: [], rows: [] };
  var apRaw = sheetExists_(TAB.APPEARANCES)
    ? readTabObjects_(TAB.APPEARANCES)
    : { headers: [], rows: [] };
  var trRaw = sheetExists_(TAB.TEXTBOOK_REFS)
    ? readTabObjects_(TAB.TEXTBOOK_REFS)
    : { headers: [], rows: [] };
  var qrRaw = sheetExists_(TAB.QUESTION_RESOURCES)
    ? readTabObjects_(TAB.QUESTION_RESOURCES)
    : { headers: [], rows: [] };

  var hdr;
  hdr = requireHeaders_(TAB.UNIVERSITIES, uniRaw.headers, ['code', 'name', 'state', 'slug']);
  if (hdr) errors.push(hdr);
  hdr = requireHeaders_(TAB.COLLEGES, colRaw.headers, ['university_code', 'name']);
  if (hdr) errors.push(hdr);
  hdr = requireHeaders_(TAB.PHASES, phRaw.headers, ['code', 'name', 'display_order']);
  if (hdr) errors.push(hdr);
  hdr = requireHeaders_(TAB.LESSONS, lesRaw.headers, [
    'external_id',
    'topic_name',
    'name',
    'display_order',
    'required_plan',
    'is_active',
  ]);
  if (hdr) errors.push(hdr);

  var universities = [];
  var uniByCode = {};
  uniRaw.rows.forEach(function (row) {
    var code = trimStr_(row.code).toUpperCase();
    var name = trimStr_(row.name);
    var state = trimStr_(row.state);
    var slug = trimStr_(row.slug).toLowerCase();
    if (!code || !name || !state || !slug) {
      errors.push(TAB.UNIVERSITIES + ' row ' + row.__row + ': code, name, state, slug are required');
      return;
    }
    uniByCode[normKey_(code)] = code;
    universities.push({ code: code, name: name, state: state, slug: slug });
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

  var phases = [];
  phRaw.rows.forEach(function (row) {
    var code = trimStr_(row.code).toLowerCase();
    var name = trimStr_(row.name);
    var displayOrder = parseIntRequired_(row.display_order, TAB.PHASES, row.__row, 'display_order', errors);
    if (!PHASE_CODES[code]) {
      errors.push(TAB.PHASES + ' row ' + row.__row + ': code must be a known mbbs_phase_code');
    }
    phases.push({ code: code, name: name, display_order: displayOrder });
  });

  var lessons = [];
  var lessonByExt = {};
  lesRaw.rows.forEach(function (row) {
    var ext = trimStr_(row.external_id);
    var topicName = trimStr_(row.topic_name);
    var name = trimStr_(row.name);
    var displayOrder = parseIntRequired_(row.display_order, TAB.LESSONS, row.__row, 'display_order', errors);
    var plan = trimStr_(row.required_plan).toLowerCase();
    var isActive = parseBool_(row.is_active, TAB.LESSONS, row.__row, 'is_active', errors);
    if (!ext) errors.push(TAB.LESSONS + ' row ' + row.__row + ': external_id is required');
    if (!name) errors.push(TAB.LESSONS + ' row ' + row.__row + ': name is required');
    if (!PLANS[plan]) {
      errors.push(TAB.LESSONS + ' row ' + row.__row + ': required_plan must be free, pro, or elite');
    }
    if (ext) lessonByExt[normKey_(ext)] = true;
    lessons.push({
      external_id: ext,
      topic_name: topicName,
      name: name,
      display_order: displayOrder,
      required_plan: plan,
      is_active: isActive,
      __row: row.__row,
    });
  });

  var lessonResources = [];
  lrRaw.rows.forEach(function (row) {
    var ext = trimStr_(row.lesson_external_id);
    var title = trimStr_(row.title);
    var url = requireHttpsUrl_(row.url, TAB.LESSON_RESOURCES, row.__row, 'url', errors);
    if (!lessonByExt[normKey_(ext)]) {
      errors.push(TAB.LESSON_RESOURCES + ' row ' + row.__row + ': lesson_external_id not on Lessons tab');
    }
    if (!title) errors.push(TAB.LESSON_RESOURCES + ' row ' + row.__row + ': title is required');
    var isFree = parseBool_(row.is_free, TAB.LESSON_RESOURCES, row.__row, 'is_free', errors);
    var displayOrder = parseIntRequired_(
      row.display_order,
      TAB.LESSON_RESOURCES,
      row.__row,
      'display_order',
      errors
    );
    lessonResources.push({
      lesson_external_id: ext,
      title: title,
      url: url,
      source_label: optionalTrimmed_(row.source_label),
      display_order: displayOrder,
      is_free: isFree,
    });
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
    tbByKey[normKey_(key)] = true;
    textbooks.push({
      sheet_key: key,
      title: title,
      authors: optionalTrimmed_(row.authors),
      edition: optionalTrimmed_(row.edition),
    });
  });

  var examPapers = [];
  var paperByExt = {};
  epRaw.rows.forEach(function (row) {
    var ext = trimStr_(row.external_id);
    var ucode = trimStr_(row.university_code).toUpperCase();
    var subjectName = trimStr_(row.subject_name);
    var year = parseIntRequired_(row.exam_year, TAB.EXAM_PAPERS, row.__row, 'exam_year', errors);
    var paperName = trimStr_(row.paper_name);
    var examType = trimStr_(row.exam_type).toLowerCase() || 'university';
    if (!EXAM_TYPES[examType]) {
      errors.push(TAB.EXAM_PAPERS + ' row ' + row.__row + ': exam_type must be university or internal');
    }
    if (!uniByCode[normKey_(ucode)]) {
      errors.push(TAB.EXAM_PAPERS + ' row ' + row.__row + ': university_code not on Universities tab');
    }
    if (ext) paperByExt[normKey_(ext)] = true;
    examPapers.push({
      external_id: ext,
      university_code: ucode,
      subject_name: subjectName,
      exam_year: year,
      paper_name: paperName,
      exam_type: examType,
    });
  });

  var appearances = [];
  var appeared = {};
  apRaw.rows.forEach(function (row) {
    var qid = trimStr_(row.question_external_id);
    var pid = trimStr_(row.paper_external_id);
    if (!questionByExt[normKey_(qid)]) {
      errors.push(TAB.APPEARANCES + ' row ' + row.__row + ': question_external_id not on Questions tab');
    }
    if (!paperByExt[normKey_(pid)]) {
      errors.push(TAB.APPEARANCES + ' row ' + row.__row + ': paper_external_id not on ExamPapers tab');
    }
    appeared[normKey_(qid)] = true;
    appearances.push({ question_external_id: qid, paper_external_id: pid });
  });
  Object.keys(theoryByExt || {}).forEach(function (key) {
    if (!appeared[key]) {
      errors.push(
        TAB.QUESTIONS +
          ' row ' +
          theoryByExt[key] +
          ': pyq_theory rows need at least one Appearances row'
      );
    }
  });

  var textbookRefs = [];
  trRaw.rows.forEach(function (row) {
    var qid = trimStr_(row.question_external_id);
    var tb = trimStr_(row.textbook_key);
    var page = parseIntRequired_(row.page, TAB.TEXTBOOK_REFS, row.__row, 'page', errors);
    if (!questionByExt[normKey_(qid)]) {
      errors.push(TAB.TEXTBOOK_REFS + ' row ' + row.__row + ': question_external_id not on Questions tab');
    }
    if (!tbByKey[normKey_(tb)]) {
      errors.push(TAB.TEXTBOOK_REFS + ' row ' + row.__row + ': textbook_key not on Textbooks tab');
    }
    textbookRefs.push({
      question_external_id: qid,
      textbook_key: tb,
      page: page,
      section_heading: optionalTrimmed_(row.section_heading),
    });
  });

  var questionResources = [];
  qrRaw.rows.forEach(function (row) {
    var qid = trimStr_(row.question_external_id);
    var title = trimStr_(row.title);
    var url = requireHttpsUrl_(row.url, TAB.QUESTION_RESOURCES, row.__row, 'url', errors);
    if (!questionByExt[normKey_(qid)]) {
      errors.push(TAB.QUESTION_RESOURCES + ' row ' + row.__row + ': question_external_id not on Questions tab');
    }
    var isFree = parseBool_(row.is_free, TAB.QUESTION_RESOURCES, row.__row, 'is_free', errors);
    var displayOrder = parseIntRequired_(
      row.display_order,
      TAB.QUESTION_RESOURCES,
      row.__row,
      'display_order',
      errors
    );
    questionResources.push({
      question_external_id: qid,
      title: title,
      url: url,
      source_label: optionalTrimmed_(row.source_label),
      display_order: displayOrder,
      is_free: isFree,
    });
  });

  return {
    universities: universities,
    colleges: colleges,
    phases: phases,
    lessons: lessons,
    lessonResources: lessonResources,
    textbooks: textbooks,
    examPapers: examPapers,
    appearances: appearances,
    textbookRefs: textbookRefs,
    questionResources: questionResources,
  };
}

function emptyToNull_(value) {
  if (value === '' || value == null) return null;
  return value;
}

function syncUgCatalog_(ug, subjectIdByKey, topicIdByKey, questionIdByExt) {
  if (!ug || !ug.universities || !ug.universities.length) {
    return { universities: 0, lessons: 0 };
  }

  var uniReturned = supabaseUpsert_('universities', ug.universities, 'code');
  var uniIdByCode = {};
  uniReturned.forEach(function (row) {
    uniIdByCode[normKey_(row.code)] = row.id;
  });

  var collegeRows = ug.colleges.map(function (c) {
    return {
      university_id: uniIdByCode[normKey_(c.university_code)],
      name: c.name,
    };
  });
  if (collegeRows.length) supabaseUpsert_('colleges', collegeRows, 'university_id,name');

  var phaseReturned = supabaseSelect_('mbbs_phases', '?select=id,code');
  var phaseIdByCode = {};
  (phaseReturned || []).forEach(function (row) {
    phaseIdByCode[normKey_(row.code)] = row.id;
  });

  var lessonRows = ug.lessons.map(function (l) {
    var tid = topicIdByKey[normKey_(l.topic_name)];
    if (!tid) throw new Error('Lesson "' + l.external_id + '": topic_name not resolved');
    return {
      external_id: l.external_id,
      topic_id: tid,
      name: l.name,
      display_order: l.display_order,
      required_plan: l.required_plan,
      is_active: l.is_active,
    };
  });
  var lessonReturned = lessonRows.length
    ? supabaseUpsert_('lessons', lessonRows, 'external_id')
    : [];
  var lessonIdByExt = {};
  lessonReturned.forEach(function (row) {
    lessonIdByExt[normKey_(row.external_id)] = row.id;
  });

  var lrRows = ug.lessonResources.map(function (r) {
    return {
      lesson_id: lessonIdByExt[normKey_(r.lesson_external_id)],
      title: r.title,
      url: r.url,
      source_label: r.source_label,
      display_order: r.display_order,
      is_free: r.is_free,
    };
  });
  if (lrRows.length) supabaseUpsert_('lesson_resources', lrRows, 'lesson_id,url');

  var tbReturned = ug.textbooks.length
    ? supabaseUpsert_('textbooks', ug.textbooks, 'sheet_key')
    : [];
  var tbIdByKey = {};
  tbReturned.forEach(function (row) {
    tbIdByKey[normKey_(row.sheet_key)] = row.id;
  });

  var paperRows = ug.examPapers.map(function (p) {
    return {
      external_id: p.external_id,
      university_id: uniIdByCode[normKey_(p.university_code)],
      subject_id: subjectIdByKey[normKey_(p.subject_name)],
      exam_year: p.exam_year,
      paper_name: p.paper_name,
      exam_type: p.exam_type,
    };
  });
  var paperReturned = paperRows.length
    ? supabaseUpsert_('exam_papers', paperRows, 'external_id')
    : [];
  var paperIdByExt = {};
  paperReturned.forEach(function (row) {
    paperIdByExt[normKey_(row.external_id)] = row.id;
  });

  var appearanceRows = ug.appearances
    .map(function (a) {
      var qid = questionIdByExt[normKey_(a.question_external_id)];
      var pid = paperIdByExt[normKey_(a.paper_external_id)];
      if (!qid || !pid) return null;
      return { question_id: qid, exam_paper_id: pid };
    })
    .filter(function (row) {
      return row;
    });
  if (appearanceRows.length) {
    supabaseUpsert_('question_appearances', appearanceRows, 'question_id,exam_paper_id');
  }

  var refRows = ug.textbookRefs.map(function (r) {
    return {
      question_id: questionIdByExt[normKey_(r.question_external_id)],
      textbook_id: tbIdByKey[normKey_(r.textbook_key)],
      page: r.page,
      section_heading: r.section_heading,
    };
  });
  if (refRows.length) {
    supabaseUpsert_('question_textbook_refs', refRows, 'question_id,textbook_id,page');
  }

  var qrRows = ug.questionResources.map(function (r) {
    return {
      question_id: questionIdByExt[normKey_(r.question_external_id)],
      title: r.title,
      url: r.url,
      source_label: r.source_label,
      display_order: r.display_order,
      is_free: r.is_free,
    };
  });
  if (qrRows.length) supabaseUpsert_('question_resources', qrRows, 'question_id,url');

  return { universities: ug.universities.length, lessons: lessonRows.length, phaseIdByCode: phaseIdByCode };
}
