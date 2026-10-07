import 'dart:async';

/// Combina o último valor de [a] e de [b] sempre que um deles emite (depois
/// de ambos terem emitido pelo menos uma vez). Equivalente ao `combineLatest2`
/// do rxdart, sem acrescentar a dependência.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  late A lastA;
  late B lastB;
  var hasA = false;
  var hasB = false;

  void emit() {
    if (hasA && hasB) controller.add(combine(lastA, lastB));
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen(
        (value) {
          lastA = value;
          hasA = true;
          emit();
        },
        onError: controller.addError,
      );
      subB = b.listen(
        (value) {
          lastB = value;
          hasB = true;
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}
