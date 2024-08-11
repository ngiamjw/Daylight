import 'package:isar/isar.dart';

//dart run build_runner build to activate, need to save the file first
part 'app_settings.g.dart';

@Collection()
class AppSettings {
  Id id = Isar.autoIncrement;
  DateTime? firstLaunchDate;
}
