/// A simple generic Result type to satisfy the Failure Contract requirement.
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data) : isSuccess = true, error = null;
  Result.failure(this.error) : isSuccess = false, data = null;

  bool get isFailure => !isSuccess;

  static Result<void> successVoid() => Result.success(null);
}
