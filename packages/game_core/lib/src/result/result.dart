/// The outcome of an operation that can fail in an expected way.
///
/// Used for rule checks and validation, where a failure is a normal result
/// and not an exceptional one.
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;

  bool get isErr => this is Err<T, E>;

  /// The value if this is [Ok], otherwise null.
  T? get valueOrNull => switch (this) {
        Ok<T, E>(:final value) => value,
        Err<T, E>() => null,
      };

  /// The error if this is [Err], otherwise null.
  E? get errorOrNull => switch (this) {
        Ok<T, E>() => null,
        Err<T, E>(:final error) => error,
      };

  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok<T, E>(:final value) => onOk(value),
        Err<T, E>(:final error) => onErr(error),
      };

  Result<U, E> map<U>(U Function(T value) transform) => switch (this) {
        Ok<T, E>(:final value) => Ok(transform(value)),
        Err<T, E>(:final error) => Err(error),
      };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;
}
