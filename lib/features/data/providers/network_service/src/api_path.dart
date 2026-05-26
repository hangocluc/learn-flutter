// baseUrl comes from Env; keep only endpoint paths here.

class LessonApiPath {
  static const getAllLessons = '/api/get-all-in-lesson';
  static const getAllProgress = '/api/get-all-process';
  static const updateProcess = '/api/update-process';
}

/// Feedback APIs on BE (lesson content vs system/app).
class FeedbackApiPath {
  static const insertLessonFeedback = '/api/insert-lesson-feedback';
  static const insertSystemFeedback = '/api/insert-system-feedback';
}

class ChatApiPath {
  static const getCommentsByQuestion = '/api/get-comment-by-question';
  static const updateComment = '/api/update-comment';
}

class ProfileApiPath {
  static const getProfileScore = '/api/get-score-profile';
  static const getProfileRank = '/api/get-top-user';
}

class AppApiPath {
  static const demo = '/api/demo';
  static const login = '/api/login';
  static const insertUser = '/api/insert-user';
  static const getUser = '/api/get-user';
}

// Keep backward-compat names used elsewhere
class DemoApiPath {
  static const demo = '/api/demo';
  static const login = '/api/login';
  static const insertUser = '/api/insert-user';
  static const getUser = '/api/get-user';
}

class ProgramApiPath {
  static const getAllPrograms = '/api/get-all-in-program';
}

// Unified path class to match service annotations
class ApiPath {
  static const demo = '/api/demo';
  static const login = '/api/login';
  static const insertUser = '/api/insert-user';
  static const getUser = '/api/get-user';
}
