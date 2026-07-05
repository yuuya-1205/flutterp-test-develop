import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_test_develop/counter/counter_bloc.dart';
import 'package:flutter_test_develop/counter/counter_page.dart';

Widget _wrap() {
  return MaterialApp(
    // 一部環境で ink_sparkle シェーダのコンパイルに失敗するため、
    // テストではシェーダ不要の InkRipple スプラッシュを使う（挙動検証には影響しない）。
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: BlocProvider(
      create: (_) => CounterBloc(),
      child: const CounterPage(title: 'Counter'),
    ),
  );
}

void main() {
  // TC-04: UI — 初期表示は "0"
  testWidgets('初期表示でカウントが 0 と表示される', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  // TC-05: UI — ＋ボタンで "1" が表示される
  testWidgets('＋ボタンをタップするとカウントが 1 になる', (tester) async {
    await tester.pumpWidget(_wrap());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
