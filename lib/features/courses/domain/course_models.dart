class CourseSchedule {
  const CourseSchedule({
    required this.id,
    required this.shift,
    required this.deadline,
    required this.toleranceMinutes,
    required this.timeZone,
  });

  final String id;
  final String shift;
  final String deadline;
  final int toleranceMinutes;
  final String timeZone;

  String get shiftLabel => switch (shift) {
    'MANANA' => 'Mañana',
    'TARDE' => 'Tarde',
    'NOCHE' => 'Noche',
    _ => shift,
  };
}

final class WeeklyCourseSlot implements Comparable<WeeklyCourseSlot> {
  const WeeklyCourseSlot({required this.weekday, required this.hour});

  static const firstWeekday = DateTime.monday;
  static const lastWeekday = DateTime.friday;
  static const firstHour = 8;
  static const lastHour = 19;

  final int weekday;
  final int hour;

  bool get isWithinMatrix =>
      weekday >= firstWeekday &&
      weekday <= lastWeekday &&
      hour >= firstHour &&
      hour <= lastHour;

  String get key => '$weekday-$hour';

  @override
  int compareTo(WeeklyCourseSlot other) {
    final dayComparison = weekday.compareTo(other.weekday);
    return dayComparison != 0 ? dayComparison : hour.compareTo(other.hour);
  }

  static List<WeeklyCourseSlot> normalize(Iterable<WeeklyCourseSlot> slots) {
    final unique = <String, WeeklyCourseSlot>{};
    for (final slot in slots) {
      if (slot.isWithinMatrix) unique[slot.key] = slot;
    }
    final normalized = unique.values.toList()..sort();
    return List.unmodifiable(normalized);
  }
}

class CourseEntry {
  const CourseEntry({
    required this.id,
    required this.name,
    required this.level,
    required this.parallel,
    required this.year,
    required this.studentCount,
    required this.teacherCount,
    required this.schedules,
    required this.weeklySchedule,
  });

  final String id;
  final String name;
  final String level;
  final String parallel;
  final int year;
  final int studentCount;
  final int teacherCount;
  final List<CourseSchedule> schedules;
  final List<WeeklyCourseSlot> weeklySchedule;

  CourseEntry copyWith({
    List<CourseSchedule>? schedules,
    List<WeeklyCourseSlot>? weeklySchedule,
  }) => CourseEntry(
    id: id,
    name: name,
    level: level,
    parallel: parallel,
    year: year,
    studentCount: studentCount,
    teacherCount: teacherCount,
    schedules: schedules ?? this.schedules,
    weeklySchedule: weeklySchedule ?? this.weeklySchedule,
  );
}

class CourseDraft {
  const CourseDraft({
    required this.name,
    required this.level,
    required this.parallel,
    required this.year,
  });

  final String name;
  final String level;
  final String parallel;
  final int year;
}

class ScheduleDraft {
  const ScheduleDraft({
    required this.shift,
    required this.deadline,
    required this.toleranceMinutes,
    this.timeZone = 'America/La_Paz',
  });

  final String shift;
  final String deadline;
  final int toleranceMinutes;
  final String timeZone;
}
