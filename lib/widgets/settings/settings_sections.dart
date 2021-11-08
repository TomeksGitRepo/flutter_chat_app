import 'package:flutter/material.dart';
import 'package:xxxx/widgets/settings/setting_item.dart';

class SettingSection extends StatefulWidget {
  final List<SettingItem> settings;
  final String sectionName;
  SettingSection(this.sectionName, this.settings);

  @override
  _SettingSectionState createState() => _SettingSectionState(settings);
}

class _SettingSectionState extends State<SettingSection> {
  _SettingSectionState(this.settings);

  List<SettingItem> settings;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: EdgeInsets.all(8),
        color: Color.fromARGB(210, 243, 239, 249),
        child: Row(
          children: [
            Text(
              widget.sectionName,
              style: TextStyle(color: Color.fromARGB(255, 150, 150, 150)),
            )
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
            itemCount: widget.settings.length,
            itemBuilder: (context, index) {
              var element = widget.settings[index];
              return SettingItem(
                  element.icon, element.settingName, element.currentValue);
            }),
      ),
    ]);
  }
}
