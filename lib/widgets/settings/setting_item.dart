import 'package:flutter/material.dart';
import '../../routes.dart';

class SettingItem extends StatelessWidget {
  final Icon icon;
  final String settingName;
  final currentValue;

  SettingItem(this.icon, this.settingName, this.currentValue);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (settingName == "Hasło firmowe") {
          Navigator.pushNamed(context, CHANGE_USER_COMPANY_PASSWORD);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icon,
          Spacer(),
          Text(settingName),
          Spacer(),
          Text(
            currentValue,
            style: TextStyle(
              color: Color.fromARGB(255, 150, 150, 150),
            ),
          ),
          Icon(Icons.keyboard_arrow_right,
              color: Color.fromARGB(255, 150, 150, 150)),
        ],
      ),
    );
  }
}
