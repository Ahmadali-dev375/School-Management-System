// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class PermissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> hasPermission(
    String teacherCnic,
    String className,
    String permissionType,
  ) async {
    DocumentSnapshot doc =
        await _firestore
            .collection('TeacherPermissions')
            .doc("Teacher$teacherCnic")
            .get();

    if (!doc.exists) return false;

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool hasPermission = data[permissionType] ?? false;
    List<String> allowedClasses = List<String>.from(
      data['assignedClasses'] ?? [],
    );

    return hasPermission && allowedClasses.contains(className);
  }
}
