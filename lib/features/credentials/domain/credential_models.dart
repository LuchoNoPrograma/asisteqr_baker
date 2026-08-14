import 'package:equatable/equatable.dart';

class CredentialStudent extends Equatable {
  const CredentialStudent({
    required this.id,
    required this.code,
    required this.fullName,
    required this.course,
    required this.managementYear,
    required this.qrPayload,
    this.guardianName,
    this.guardianPhone,
    this.photoSource,
    this.active = true,
  });

  final String id;
  final String code;
  final String fullName;
  final String course;
  final int managementYear;
  final String qrPayload;
  final String? guardianName;
  final String? guardianPhone;
  final String? photoSource;
  final bool active;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  @override
  List<Object?> get props => [
    id,
    code,
    fullName,
    course,
    managementYear,
    qrPayload,
    guardianName,
    guardianPhone,
    photoSource,
    active,
  ];
}

enum CredentialPrintMode { frontAndBack, frontOnly }

extension CredentialPrintModeLabel on CredentialPrintMode {
  String get label => switch (this) {
    CredentialPrintMode.frontAndBack => 'Anverso y reverso juntos',
    CredentialPrintMode.frontOnly => 'Solo anverso',
  };
}
