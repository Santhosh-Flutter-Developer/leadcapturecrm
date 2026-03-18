import 'package:intl/intl.dart';
import 'package:leadcapture/models/src/worktime_model.dart';
import 'package:leadcapture/utils/src/open_file.dart';
import 'package:leadcapture/utils/src/time_format.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class XlsExport {
  // static Future rideReportExport({required List<RideModel> model}) async {
  //   final workbook = Workbook();
  //   final sheet = workbook.worksheets[0];

  //   final headers = [
  //     "Sno",
  //     "Ride By",
  //     "Start Time",
  //     "End Time",
  //     "Start Point",
  //     "End Point",
  //     "Time Taken",
  //     "Distance Covered",
  //   ];

  //   // Header row
  //   for (int i = 0; i < headers.length; i++) {
  //     sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
  //   }

  //   for (int row = 0; row < model.length; row++) {
  //     final product = model[row];
  //     final excelRow = row + 2;

  //     sheet.getRangeByIndex(excelRow, 1).setNumber(row + 1);
  //     sheet.getRangeByIndex(excelRow, 2).setText(product.userName);
  //     sheet
  //         .getRangeByIndex(excelRow, 3)
  //         .setText(DateFormat('dd-MM-yyyy hh:mm a').format(product.created));
  //     sheet
  //         .getRangeByIndex(excelRow, 4)
  //         .setText(DateFormat('dd-MM-yyyy hh:mm a').format(product.modified));

  //     sheet.getRangeByIndex(excelRow, 5).setText(
  //         "${product.points.first.latitude}, ${product.points.first.longitude}");

  //     sheet.getRangeByIndex(excelRow, 6).setText(
  //         "${product.points.last.latitude}, ${product.points.last.longitude}");

  //     sheet
  //         .getRangeByIndex(excelRow, 7)
  //         .setText(formatDuration(product.modified.difference(product.created)));

  //     sheet.getRangeByIndex(excelRow, 8).setText(
  //         "${LocationService.calculateTotalDistance(product.points.map((e) {
  //           return LatLng(e.latitude, e.longitude);
  //         }).toList()).toStringAsFixed(2)} KM");
  //   }

  //   sheet.autoFitColumn(1);
  //   sheet.autoFitColumn(8);

  //   final bytes = workbook.saveAsStream();
  //   workbook.dispose();

  //   FileHelper.launchFile(
  //     bt: bytes,
  //     nf: false,
  //     fn: "Ride Report.xlsx",
  //     name: "Ride Report",
  //   );
  // }

  static Future workTimeReportExport({
    required List<WorktimeModel> model,
  }) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];

    final headers = [
      "Sno",
      "Name",
      "Clock In",
      "Clock Out",
      "Total Breaks",
      "Total Working Hours",
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    for (int row = 0; row < model.length; row++) {
      final product = model[row];
      final excelRow = row + 2;

      Duration totalBreaks = Duration.zero;
      Duration totalWorktime = Duration.zero;

      for (var breakEntry in product.breaks.entries) {
        final start = breakEntry.value["start"].toDate();
        final end = breakEntry.value["end"].toDate();
        totalBreaks += end.difference(start);
      }

      if (product.clockOut != null) {
        totalWorktime =
            product.clockOut!.difference(product.clockIn) - totalBreaks;
      }

      sheet.getRangeByIndex(excelRow, 1).setNumber(row + 1);
      sheet.getRangeByIndex(excelRow, 2).setText(product.userName);
      sheet
          .getRangeByIndex(excelRow, 3)
          .setText(DateFormat('dd-MM-yyyy hh:mm a').format(product.clockIn));
      sheet
          .getRangeByIndex(excelRow, 4)
          .setText(
            product.clockOut != null
                ? DateFormat('dd-MM-yyyy hh:mm a').format(product.clockOut!)
                : "",
          );
      sheet.getRangeByIndex(excelRow, 5).setText(formatDuration(totalBreaks));
      sheet.getRangeByIndex(excelRow, 6).setText(formatDuration(totalWorktime));
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    FileHelper.launchFile(
      bt: bytes,
      nf: false,
      fn: "Worktime Report.xlsx",
      name: "Worktime Report",
    );
  }
}
