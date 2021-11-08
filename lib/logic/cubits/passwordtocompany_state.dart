part of 'passwordtocompany_cubit.dart';

@immutable
abstract class PasswordToCompanyState {}

class PasswordToCompanyNotInitated extends PasswordToCompanyState {}

class PasswordToCompanyLoading extends PasswordToCompanyState {}

class PasswordToCompanyIncorrect extends PasswordToCompanyState {}

class PasswordToCompanyCorrect extends PasswordToCompanyState {
  final companyName;

  PasswordToCompanyCorrect(this.companyName);
}
