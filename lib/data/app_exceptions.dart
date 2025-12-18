class AppExceptions implements Exception {
  final String? message;
  final String? prefix;

  AppExceptions([this.message, this.prefix]);

  @override
  String toString() {
    return "$prefix$message";
  }
}

class InternetException extends AppExceptions {
  InternetException(String? message) : super(message, "No Internet: ");
}

class RequestTimeOut extends AppExceptions {
  RequestTimeOut(String? message) : super(message, "Request Timeout: ");
}

class ServerException extends AppExceptions {
  ServerException(String? message) : super(message, "Server Error: ");
}

class FetchDataException extends AppExceptions {
  FetchDataException(String? message) : super(message, "Error During Communication: ");
}

class InvalidUrlException extends AppExceptions {
  InvalidUrlException(String? message) : super(message, "Invalid Url: ");
}