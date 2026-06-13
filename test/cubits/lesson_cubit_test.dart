import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:learn_flutter/core/base/src/base_usecase.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';
import 'package:learn_flutter/features/domain/usecases/src/lesson_usecase.dart';
import 'package:learn_flutter/features/presentation/cubits/lesson_cubit/lesson_cubit.dart';
import 'package:learn_flutter/features/presentation/cubits/lesson_cubit/lesson_state.dart';

class MockLessonUseCase extends Mock implements LessonUseCase {}

LessonEntity fakeLesson({String id = 'l1', String title = 'Intro to Dart'}) =>
    LessonEntity(
      id: id,
      title: title,
      totalTopic: 5,
      learnCount: 2,
      topics: [],
    );

void main() {
  late MockLessonUseCase useCase;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    useCase = MockLessonUseCase();
  });

  LessonCubit buildCubit() => LessonCubit(useCase: useCase);

  group('LessonCubit', () {
    test('initial state is LessonStateInitial', () {
      expect(buildCubit().state, isA<LessonStateInitial>());
    });

    blocTest<LessonCubit, LessonState>(
      'loadLessons emits Loading then Success on successful fetch',
      build: buildCubit,
      setUp: () {
        when(() => useCase.call(any()))
            .thenAnswer((_) async => Right([fakeLesson()]));
      },
      act: (cubit) => cubit.loadLessons(),
      expect: () => [
        isA<LessonStateLoading>(),
        isA<LessonStateSuccess>()
            .having((s) => s.lessons.length, 'lessons count', 1),
      ],
    );

    blocTest<LessonCubit, LessonState>(
      'loadLessons emits Loading then Failure on error',
      build: buildCubit,
      setUp: () {
        when(() => useCase.call(any()))
            .thenAnswer((_) async => Left(Exception('Network error')));
      },
      act: (cubit) => cubit.loadLessons(),
      expect: () => [
        isA<LessonStateLoading>(),
        isA<LessonStateFailure>()
            .having((s) => s.message, 'message', contains('Network error')),
      ],
    );

    blocTest<LessonCubit, LessonState>(
      'loadLessons skips reload when already Success and forceRefresh=false',
      build: buildCubit,
      setUp: () {
        when(() => useCase.call(any()))
            .thenAnswer((_) async => Right([fakeLesson()]));
      },
      act: (cubit) async {
        await cubit.loadLessons();
        await cubit.loadLessons(); // second call should be skipped
      },
      verify: (_) {
        // useCase.call should only be invoked once
        verify(() => useCase.call(any())).called(1);
      },
    );

    blocTest<LessonCubit, LessonState>(
      'loadLessons reloads when forceRefresh=true even in Success state',
      build: buildCubit,
      setUp: () {
        when(() => useCase.call(any()))
            .thenAnswer((_) async => Right([fakeLesson()]));
      },
      act: (cubit) async {
        await cubit.loadLessons();
        await cubit.loadLessons(forceRefresh: true);
      },
      verify: (_) {
        verify(() => useCase.call(any())).called(2);
      },
    );

    blocTest<LessonCubit, LessonState>(
      'loadLessons with empty lesson list emits Success with empty list',
      build: buildCubit,
      setUp: () {
        when(() => useCase.call(any()))
            .thenAnswer((_) async => Right([]));
      },
      act: (cubit) => cubit.loadLessons(),
      expect: () => [
        isA<LessonStateLoading>(),
        isA<LessonStateSuccess>()
            .having((s) => s.lessons, 'lessons', isEmpty),
      ],
    );
  });
}
