import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// ===== Event =====

/// カウンターのイベント。
sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => [];
}

/// 加算イベント。
class CounterIncremented extends CounterEvent {
  const CounterIncremented();
}

// ===== State =====

/// カウンターの状態。
class CounterState extends Equatable {
  const CounterState({this.count = 0});

  final int count;

  @override
  List<Object?> get props => [count];
}

// ===== Bloc =====

/// カウンターの状態管理を担う Bloc。
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncremented>(_onIncremented);
  }

  /// 加算する（add をラップした入口＝公開メソッド）。
  void increment() => add(const CounterIncremented());

  void _onIncremented(CounterIncremented event, Emitter<CounterState> emit) {
    emit(CounterState(count: state.count + 1));
  }
}
