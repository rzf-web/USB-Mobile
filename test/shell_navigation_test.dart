import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usb_mobile/widgets/app_bottom_nav_bar.dart';
import 'package:usb_mobile/widgets/app_notification_banner.dart';
import 'package:usb_mobile/widgets/period_picker_dialog.dart';

void main() {
  group('AppBottomNavBar Widget Tests', () {
    testWidgets('renders all 4 navigation items correctly and responds to tap', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return AppBottomNavBar(
                  currentIndex: selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Pekerjaan Saya'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tap tab Laporan (index 2)
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 2);
    });
  });

  group('AppNotificationBanner Widget Tests', () {
    testWidgets('renders success banner and responds to close button', (WidgetTester tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNotificationBanner(
              isVisible: true,
              isSuccess: true,
              message: 'Pekerjaan Berhasil Ditambahkan',
              onClose: () {
                closed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Pekerjaan Berhasil Ditambahkan'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('does not show content when isVisible is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNotificationBanner(
              isVisible: false,
              isSuccess: true,
              message: 'Hidden Banner',
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Hidden Banner'), findsNothing);
    });
  });

  group('PeriodPickerDialog Tests', () {
    testWidgets('PeriodPickerDialog opens, renders, and applies selection', (WidgetTester tester) async {
      String? resultMonth;
      String? resultYear;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PeriodPickerDialog.show(
                      context,
                      initialMonth: 'Januari',
                      initialYear: '2026',
                      onSelected: (year, month) {
                        resultYear = year;
                        resultMonth = month;
                      },
                    );
                  },
                  child: const Text('Open Picker'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Periode'), findsOneWidget);
      expect(find.text('Bulan'), findsOneWidget);
      expect(find.text('Tahun'), findsOneWidget);
      expect(find.text('Terapkan'), findsOneWidget);

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(resultMonth, 'Januari');
      expect(resultYear, '2026');
    });
  });
}
