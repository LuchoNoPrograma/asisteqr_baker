const weekdayLabels = {
  DateTime.monday: 'Lunes',
  DateTime.tuesday: 'Martes',
  DateTime.wednesday: 'Miércoles',
  DateTime.thursday: 'Jueves',
  DateTime.friday: 'Viernes',
};

class TeachingScheduleException implements Exception {
  const TeachingScheduleException(this.message);

  final String message;
}
