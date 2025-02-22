import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';

final kDatePickerFirstDate = DateTime(0);
final kDatePickerLastDate = DateTime(9999);

extension OrgDateUtil on OrgDate {
  DateTime toDateTime() =>
      DateTime(int.parse(year), int.parse(month), int.parse(day));
}

extension OrgTimeUtil on OrgTime {
  TimeOfDay toTimeOfDay() =>
      TimeOfDay(hour: int.parse(hour), minute: int.parse(minute));
}

final _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

extension DateTimeUtil on DateTime {
  OrgDate toOrgDate() => (
    year: year.toString().padLeft(4, '0'),
    month: month.toString().padLeft(2, '0'),
    day: day.toString().padLeft(2, '0'),
    dayName: _weekdayNames[weekday - 1],
  );
}

extension TimeOfDayUtil on TimeOfDay {
  OrgTime toOrgTime() => (
    hour: hour.toString().padLeft(2, '0'),
    minute: minute.toString().padLeft(2, '0'),
  );
}
