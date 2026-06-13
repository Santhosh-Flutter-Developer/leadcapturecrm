import 'package:flutter/material.dart';
import 'package:leadcapture/theme/src/app_colors.dart';
import 'package:leadcapture/views/screens/attendance/face_recognition_attendance.dart';

class AttendanceFAB extends StatelessWidget {
  const AttendanceFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FaceRecognitionAttendance(),
          ),
        );
      },
      backgroundColor: AppColors.primaryColor,
      icon: const Icon(Icons.fingerprint, color: Colors.white),
      label: const Text(
        'Mark Attendance',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
