import 'Timestamp.dart';
import 'package:hive/hive.dart';

class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final int typeId = 2;

  @override
  Timestamp read(BinaryReader reader) {
    final millisecondsSinceEpoch = reader.readInt();
    return Timestamp.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimestampAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
