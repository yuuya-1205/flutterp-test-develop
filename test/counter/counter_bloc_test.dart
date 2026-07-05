import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_test_develop/counter/counter_bloc.dart';

void main() {
  // TC-01: 正常系/境界値 — 初期状態は count = 0
  test('初期状態は CounterState(count: 0)', () {
    expect(CounterBloc().state, const CounterState());
  });

  // TC-02: 正常系 — increment で count が 1 になる
  blocTest<CounterBloc, CounterState>(
    'increment で count が 1 になる',
    build: CounterBloc.new,
    act: (bloc) => bloc.increment(),
    expect: () => const [CounterState(count: 1)],
  );

  // TC-03: 状態遷移 — increment 2回で count が積み上がる
  blocTest<CounterBloc, CounterState>(
    'increment 2回で count が 1, 2 と積み上がる',
    build: CounterBloc.new,
    act: (bloc) => bloc
      ..increment()
      ..increment(),
    expect: () => const [CounterState(count: 1), CounterState(count: 2)],
  );
}
