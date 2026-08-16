//Login Exceptions

class UserNotFoundException implements Exception{}

class WrongPassAuthException implements Exception{}

//Register Exceptions

class EmailAlreadyInUseException implements Exception{}

class InvalidEmailException implements Exception{}

class WeakPassowrdExcetion implements Exception {}

//Generic Exceptions

class GenericAuthException implements Exception{}

class UserNotLoggedinException implements Exception{}

class GoogleSignInCancelledException implements Exception{}

// Custom exception classes
class AuthException implements Exception {}

class InvalidPhoneNumberException implements AuthException {}
class InvalidVerificationCodeException implements AuthException {}
class AuthTimeoutException implements AuthException {}
class GenericAuthExceptions implements AuthException{}

class FacebookSignInCancelledException implements Exception{}