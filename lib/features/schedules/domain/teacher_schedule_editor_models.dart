class ScheduleTeacher {
  const ScheduleTeacher({
    required this.id,
    required this.code,
    required this.fullName,
    required this.specialty,
    this.phone,
    this.email,
    this.photoUrl,
  });

  final int id;
  final int code;
  final String fullName;
  final String specialty;
  final String? phone;
  final String? email;
  final String? photoUrl;
}

class SchedulePeriod {
  const SchedulePeriod({
    required this.id,
    required this.name,
    required this.year,
  });

  final int id;
  final String name;
  final int year;
}

class GeneralScheduleConfig {
  const GeneralScheduleConfig({
    required this.id,
    required this.periodId,
    required this.startTime,
    required this.endTime,
    required this.intervalMinutes,
    required this.toleranceMinutes,
    required this.timeZone,
    required this.version,
  });

  final int? id;
  final int periodId;
  final String startTime;
  final String endTime;
  final int intervalMinutes;
  final int toleranceMinutes;
  final String timeZone;
  final int version;

  int get startMinutes => scheduleTimeToMinutes(startTime);
  int get endMinutes => scheduleTimeToMinutes(endTime);

  GeneralScheduleConfig copyWith({
    int? id,
    int? periodId,
    String? startTime,
    String? endTime,
    int? intervalMinutes,
    int? toleranceMinutes,
    String? timeZone,
    int? version,
  }) => GeneralScheduleConfig(
    id: id ?? this.id,
    periodId: periodId ?? this.periodId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
    timeZone: timeZone ?? this.timeZone,
    version: version ?? this.version,
  );
}

class GeneralScheduleDraft {
  const GeneralScheduleDraft({
    required this.periodId,
    required this.version,
    required this.startTime,
    required this.endTime,
    required this.toleranceMinutes,
    required this.breaks,
    this.intervalMinutes = 30,
    this.timeZone = 'America/La_Paz',
  });

  final int periodId;
  final int version;
  final String startTime;
  final String endTime;
  final int intervalMinutes;
  final int toleranceMinutes;
  final String timeZone;
  final List<ScheduleBreak> breaks;
}

class ScheduleBreak {
  const ScheduleBreak({
    required this.name,
    required this.startTime,
    required this.endTime,
    this.id,
  });

  final int? id;
  final String name;
  final String startTime;
  final String endTime;

  bool includesRange(int start, int end) =>
      start < scheduleTimeToMinutes(endTime) &&
      end > scheduleTimeToMinutes(startTime);
}

class ScheduleCourse {
  const ScheduleCourse({required this.id, required this.name});
  final int id;
  final String name;
}

class ScheduleSubject {
  const ScheduleSubject({required this.id, required this.name});
  final int id;
  final String name;
}

class ScheduleClassroom {
  const ScheduleClassroom({
    required this.id,
    required this.name,
    this.capacity,
    this.location,
  });
  final int id;
  final String name;
  final int? capacity;
  final String? location;
}

int scheduleTimeToMinutes(String value) {
  final parts = value.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String scheduleMinutesToTime(int value) {
  final hours = value ~/ 60;
  final minutes = value % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}
