import 'package:flutter/material.dart';
import '../core/session/session_manager.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'beranda_cutting_screen.dart';
import 'beranda_screen.dart';
import 'laporan_screen.dart';
import 'pekerjaan_saya_screen.dart';
import 'profil_screen.dart';

/// Shell navigasi utama aplikasi yang menjaga state seluruh tab (IndexedStack)
/// dan menyatukan Bottom Navigation Bar agar tidak di-rebuild saat berpindah menu.
class MainShellScreen extends StatefulWidget {
  final int initialIndex;
  final bool? forceCutting;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
    this.forceCutting,
  });

  /// Helper untuk mengganti tab secara terprogram dari dalam layar anak (child screens).
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellScreenState>();
    state?.setTab(index);
  }

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setTab(int index) {
    if (_currentIndex != index && mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  bool get _isCuttingRole {
    if (widget.forceCutting != null) return widget.forceCutting!;
    final role = SessionManager.employeeRole ?? '';
    return role.toLowerCase().contains('cut');
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _isCuttingRole
          ? const BerandaCuttingScreen(isEmbedded: true)
          : const BerandaScreen(isEmbedded: true),
      PekerjaanSayaScreen(
        isEmbedded: true,
        initialTab: _isCuttingRole ? 1 : 0,
      ),
      const LaporanScreen(isEmbedded: true),
      const ProfilScreen(isEmbedded: true),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          // Jika tidak di tab Beranda, tombol Back kembali ke Beranda terlebih dahulu
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTabSelected: setTab,
        ),
      ),
    );
  }
}
