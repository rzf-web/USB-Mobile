import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_mobile/core/cache/app_cache_manager.dart';
import 'package:usb_mobile/core/session/session_manager.dart';
import 'package:usb_mobile/core/utils/app_formatter.dart';
import 'package:usb_mobile/screens/buat_produk_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=http://localhost:8080\nCONNECT_TIMEOUT_SECONDS=20\nRECEIVE_TIMEOUT_SECONDS=20',
    );
    SharedPreferences.setMockInitialValues({
      'employee_id': '1',
      'employee_name': 'Test User',
      'employee_role': 'Cutting',
    });
    await SessionManager.init();
    await AppCacheManager.init();
    await AppFormatter.init();
  });

  testWidgets('BuatProdukScreen loads and renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuatProdukScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BuatProdukScreen), findsOneWidget);
    expect(find.text('Identitas Proyek'), findsWidgets);
    expect(find.text('Kode Project'), findsOneWidget);
    expect(find.text('Pemesan'), findsOneWidget);
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Jenis Bahan'), findsWidgets);
    expect(find.text('Data Produk'), findsWidgets);
    expect(find.text('Koordinator'), findsOneWidget);
    expect(find.text('Data Pegawai'), findsOneWidget);

    // Verify Kode Project is auto-generated matching desktop app format (MP...)
    final textField = find.byType(TextField).first;
    final TextField widget = tester.widget<TextField>(textField);
    expect(widget.controller?.text.startsWith('MP'), isTrue);

    // Test entering custom project code and tap Lanjut
    await tester.enterText(textField, 'PRD-TEST-001');
    await tester.pump();

    // Tap Selanjutnya
    final selanjutnyaButton = find.text('Selanjutnya');
    expect(selanjutnyaButton, findsOneWidget);
    await tester.tap(selanjutnyaButton);
    await tester.pumpAndSettle();

    // Should now be on Bahan Cutting step
    expect(find.text('Bahan Cutting'), findsWidgets);
    expect(find.text('Tidak Ada Bahan Cutting'), findsOneWidget);
  });
}
