import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:learn_flutter/features/presentation/cubits/quiz_cubit/quiz_cubit.dart';
import 'package:learn_flutter/features/presentation/cubits/quiz_cubit/quiz_state.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';
import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/features/data/models/lesson_model/progress_request_model.dart';
import 'package:learn_flutter/core/base/src/api_response.dart';

class MockLessonService extends Mock implements LessonService {}

class MockAppSharedPreferences extends Mock implements AppSharedPreferences {}

class FakeProgressRequestModel extends Fake implements ProgressRequestModel {}

QuestionEntity makeQuestion({
  String id = 'q1',
  String correctAnswer = '1',
  List<String>? answers,
}) {
  return QuestionEntity(
    id: id,
    quizId: 'quiz1',
    stt: 1,
    content: 'What is Dart?',
    answers: answers ?? ['A language', 'A fruit', 'A bird', 'A car'],
    correctAnswer: correctAnswer,
  );
}

QuizEntity makeQuiz({List<QuestionEntity>? questions}) {
  return QuizEntity(
    id: 'quiz1',
    lessonId: 'lesson1',
    name: 'Dart Quiz',
    questions: questions ??
        [
          makeQuestion(id: 'q1'),
          makeQuestion(id: 'q2', correctAnswer: '2'),
        ],
  );
}

void main() {
  late MockLessonService lessonService;
  late MockAppSharedPreferences sharedPreferences;

  setUpAll(() {
    registerFallbackValue(FakeProgressRequestModel());
  });

  setUp(() {
    lessonService = MockLessonService();
    sharedPreferences = MockAppSharedPreferences();
    when(() => sharedPreferences.get(any())).thenReturn(null);
    when(() => lessonService.updateProcess(any())).thenAnswer(
      (_) async => ApiResponse(null, 200, 'ok', true),
    );
  });

  QuizCubit buildCubit() => QuizCubit(
        lessonService: lessonService,
        sharedPreferences: sharedPreferences,
      );

  group('QuizCubit', () {
    test('initial state is QuizStateInitial', () {
      expect(buildCubit().state, isA<QuizStateInitial>());
    });

    blocTest<QuizCubit, QuizState>(
      'startQuiz emits QuizStateQuestion with index 0',
      build: buildCubit,
      act: (cubit) => cubit.startQuiz(makeQuiz()),
      expect: () => [
        isA<QuizStateQuestion>()
            .having((s) => s.currentQuestionIndex, 'index', 0)
            .having((s) => s.isLastQuestion, 'isLastQuestion', false),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'startQuiz with single question sets isLastQuestion true',
      build: buildCubit,
      act: (cubit) => cubit.startQuiz(makeQuiz(questions: [makeQuestion()])),
      expect: () => [
        isA<QuizStateQuestion>()
            .having((s) => s.isLastQuestion, 'isLastQuestion', true),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'selectAnswer updates userAnswers at current index',
      build: buildCubit,
      act: (cubit) {
        cubit.startQuiz(makeQuiz());
        cubit.selectAnswer('A language');
      },
      expect: () => [
        isA<QuizStateQuestion>(),
        isA<QuizStateQuestion>()
            .having((s) => s.userAnswers[0], 'answer[0]', 'A language'),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'nextQuestion advances to next question',
      build: buildCubit,
      act: (cubit) {
        cubit.startQuiz(makeQuiz());
        cubit.nextQuestion();
      },
      expect: () => [
        isA<QuizStateQuestion>().having((s) => s.currentQuestionIndex, 'index', 0),
        isA<QuizStateQuestion>()
            .having((s) => s.currentQuestionIndex, 'index', 1)
            .having((s) => s.isLastQuestion, 'isLastQuestion', true),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'nextQuestion on last question emits QuizStateSummary',
      build: buildCubit,
      act: (cubit) {
        cubit.startQuiz(makeQuiz(questions: [makeQuestion()]));
        cubit.selectAnswer('A language');
        cubit.nextQuestion();
      },
      expect: () => [
        isA<QuizStateQuestion>(),
        isA<QuizStateQuestion>(),
        isA<QuizStateSummary>(),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'summary has correct score when all answers are correct',
      build: buildCubit,
      act: (cubit) {
        // q1 correctAnswer='1' → answers[0]='A language'
        // q2 correctAnswer='2' → answers[1]='A fruit'
        final quiz = makeQuiz();
        cubit.startQuiz(quiz);
        cubit.selectAnswer('A language'); // q1 correct
        cubit.nextQuestion();
        cubit.selectAnswer('A fruit'); // q2 correct
        cubit.nextQuestion();
      },
      expect: () => [
        isA<QuizStateQuestion>(),
        isA<QuizStateQuestion>(),
        isA<QuizStateQuestion>(),
        isA<QuizStateQuestion>(),
        isA<QuizStateSummary>()
            .having((s) => s.correctAnswers, 'correctAnswers', 2)
            .having((s) => s.score, 'score', 100.0),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'summary has 0 score when no answers given',
      build: buildCubit,
      act: (cubit) {
        final quiz = makeQuiz(questions: [makeQuestion()]);
        cubit.startQuiz(quiz);
        cubit.nextQuestion();
      },
      expect: () => [
        isA<QuizStateQuestion>(),
        isA<QuizStateSummary>()
            .having((s) => s.correctAnswers, 'correctAnswers', 0)
            .having((s) => s.score, 'score', 0.0),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'restartQuiz resets to QuizStateInitial',
      build: buildCubit,
      act: (cubit) {
        cubit.startQuiz(makeQuiz());
        cubit.restartQuiz();
      },
      expect: () => [
        isA<QuizStateQuestion>(),
        isA<QuizStateInitial>(),
      ],
    );

    blocTest<QuizCubit, QuizState>(
      'selectAnswer does nothing when state is not QuizStateQuestion',
      build: buildCubit,
      act: (cubit) => cubit.selectAnswer('anything'),
      expect: () => [],
    );

    blocTest<QuizCubit, QuizState>(
      'nextQuestion does nothing when state is not QuizStateQuestion',
      build: buildCubit,
      act: (cubit) => cubit.nextQuestion(),
      expect: () => [],
    );
  });

  group('QuizCubit.isCorrectAnswer', () {
    late QuizCubit cubit;

    setUp(() => cubit = buildCubit());

    test('returns true when userAnswer matches by numeric index (1-based)', () {
      final q = makeQuestion(
        correctAnswer: '1',
        answers: ['Dart', 'Java', 'Kotlin'],
      );
      expect(cubit.isCorrectAnswer(q, 'Dart'), isTrue);
    });

    test('returns false when numeric index points to wrong answer', () {
      final q = makeQuestion(
        correctAnswer: '2',
        answers: ['Dart', 'Java', 'Kotlin'],
      );
      expect(cubit.isCorrectAnswer(q, 'Dart'), isFalse);
    });

    test('returns true when userAnswer matches correctAnswer text (fallback)', () {
      final q = makeQuestion(
        correctAnswer: 'Dart',
        answers: ['Java', 'Dart'],
      );
      expect(cubit.isCorrectAnswer(q, 'Dart'), isTrue);
    });

    test('comparison is case-insensitive for text fallback', () {
      final q = makeQuestion(
        correctAnswer: 'dart',
        answers: ['Java', 'Dart'],
      );
      expect(cubit.isCorrectAnswer(q, 'DART'), isTrue);
    });

    test('returns false for completely wrong answer', () {
      final q = makeQuestion(
        correctAnswer: '1',
        answers: ['Dart', 'Java'],
      );
      expect(cubit.isCorrectAnswer(q, 'Java'), isFalse);
    });

    test('returns false when numeric index out of range', () {
      final q = makeQuestion(
        correctAnswer: '10',
        answers: ['Dart', 'Java'],
      );
      expect(cubit.isCorrectAnswer(q, 'Dart'), isFalse);
    });

    test('returns false for empty userAnswer with text fallback', () {
      final q = makeQuestion(correctAnswer: 'Dart', answers: ['Dart', 'Java']);
      expect(cubit.isCorrectAnswer(q, ''), isFalse);
    });
  });
}
