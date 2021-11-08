import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

part 'passwordtocompany_state.dart';

class PasswordToCompanyCubit extends Cubit<PasswordToCompanyState> {
  PasswordToCompanyCubit() : super(PasswordToCompanyNotInitated());

  void getCompanyFromPassword(String password) async {
    emit(PasswordToCompanyLoading());
    if (password == "") {
      emit(PasswordToCompanyNotInitated());
      return;
    }
    var result = await FirebaseFirestore.instance
        .collection("companies")
        .where("password", isEqualTo: password)
        .get();
    if (result.docs.length != 0) {
      final resultData = result.docs.first.data();
      print(resultData!["companyName"]);
      emit(PasswordToCompanyCorrect(resultData["companyName"]));
    } else {
      emit(PasswordToCompanyIncorrect());
    }
  }
}
