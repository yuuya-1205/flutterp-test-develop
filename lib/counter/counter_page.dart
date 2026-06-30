import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'counter_bloc.dart';

/// カウンター画面。
class CounterPage extends StatelessWidget {
  const CounterPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            BlocBuilder<CounterBloc, CounterState>(
              builder: (context, state) {
                return Text(
                  '${state.count}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // add は直接呼ばず、Bloc が公開するメソッド（add をラップした入口）を呼ぶ。
        onPressed: () => context.read<CounterBloc>().increment(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
