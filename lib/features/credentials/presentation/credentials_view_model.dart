import 'package:asisteqr_baker/features/credentials/domain/credential_document_generator.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_repository.dart';
import 'package:flutter/foundation.dart';

enum CredentialsLoadStatus { loading, ready, failure }

class CredentialsViewModel extends ChangeNotifier {
  CredentialsViewModel(this._repository, this._documentGenerator);

  final CredentialRepository _repository;
  final CredentialDocumentGenerator _documentGenerator;

  List<CredentialStudent> students = const [];
  CredentialsLoadStatus loadStatus = CredentialsLoadStatus.loading;
  CredentialPrintMode printMode = CredentialPrintMode.frontAndBack;
  String? course;
  String? previewStudentId;
  String? error;
  bool exporting = false;
  String _query = '';
  final Set<String> _selectedIds = {};

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  List<CredentialStudent> get filtered {
    final query = _query.trim().toLowerCase();
    return students
        .where((student) {
          final matchesCourse = course == null || student.course == course;
          final matchesQuery =
              query.isEmpty ||
              student.fullName.toLowerCase().contains(query) ||
              student.code.toLowerCase().contains(query);
          return matchesCourse && matchesQuery;
        })
        .toList(growable: false);
  }

  List<CredentialStudent> get selected => students
      .where((student) => _selectedIds.contains(student.id))
      .toList(growable: false);

  List<String> get courses {
    final values = students.map((student) => student.course).toSet().toList()
      ..sort();
    return values;
  }

  CredentialStudent? get previewStudent {
    for (final student in students) {
      if (student.id == previewStudentId) return student;
    }
    final selectedStudents = selected;
    if (selectedStudents.isNotEmpty) return selectedStudents.first;
    final visible = filtered;
    return visible.isEmpty ? null : visible.first;
  }

  Future<void> load() async {
    loadStatus = CredentialsLoadStatus.loading;
    error = null;
    notifyListeners();
    try {
      students = List.unmodifiable(await _repository.getStudents());
      _selectedIds.removeWhere(
        (id) => !students.any((student) => student.id == id),
      );
      loadStatus = CredentialsLoadStatus.ready;
    } on Object {
      error = 'No pudimos cargar los estudiantes.';
      loadStatus = CredentialsLoadStatus.failure;
    } finally {
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCourse(String? value) {
    course = value;
    notifyListeners();
  }

  void setPrintMode(CredentialPrintMode value) {
    printMode = value;
    notifyListeners();
  }

  void toggleVisible(bool selected) {
    final visible = filtered;
    if (selected) {
      _selectedIds.addAll(visible.map((student) => student.id));
      if (visible.isNotEmpty) previewStudentId ??= visible.first.id;
    } else {
      _selectedIds.removeAll(visible.map((student) => student.id));
    }
    notifyListeners();
  }

  void toggleStudent(CredentialStudent student) {
    previewStudentId = student.id;
    if (!_selectedIds.remove(student.id)) _selectedIds.add(student.id);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<Uint8List> buildSelectedPdf() async {
    exporting = true;
    notifyListeners();
    try {
      return await _documentGenerator.build(
        students: selected,
        mode: printMode,
      );
    } finally {
      exporting = false;
      notifyListeners();
    }
  }
}
