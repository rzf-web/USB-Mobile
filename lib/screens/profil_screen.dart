import 'dart:async';
import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import '../core/cache/app_cache_manager.dart';
import '../core/network/api_exception.dart';
import '../core/session/session_manager.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_notification_banner.dart';


class ProfilScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfilScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final int _currentNavIndex = 3;
  bool _showSuccessBanner = false;
  Timer? _bannerTimer;
  bool _isLoading = true;

  void _showNotificationBanner() {
    _bannerTimer?.cancel();
    setState(() {
      _showSuccessBanner = true;
    });
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showSuccessBanner = false;
        });
      }
    });
  }

  void _hideNotificationBanner() {
    _bannerTimer?.cancel();
    setState(() {
      _showSuccessBanner = false;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _openUbahKataSandiDialog() {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? dialogError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ubah Kata Sandi',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Kata Sandi Saat Ini',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: TextField(
                        controller: currentPassController,
                        obscureText: obscureCurrent,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColor.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF98A2B3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 16,
                              color: const Color(0xFF98A2B3),
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureCurrent = !obscureCurrent;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kata Sandi Baru',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: TextField(
                        controller: newPassController,
                        obscureText: obscureNew,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColor.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF98A2B3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 16,
                              color: const Color(0xFF98A2B3),
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Konfirmasi Kata Sandi Baru',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: TextField(
                        controller: confirmPassController,
                        obscureText: obscureConfirm,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColor.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF98A2B3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 16,
                              color: const Color(0xFF98A2B3),
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        dialogError!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFF04438),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final oldPass = currentPassController.text;
                                final newPass = newPassController.text;
                                final confirmPass = confirmPassController.text;

                                if (oldPass.isEmpty) {
                                  setDialogState(() {
                                    dialogError = 'Kata sandi saat ini wajib diisi.';
                                  });
                                  return;
                                }
                                if (newPass.length < 6) {
                                  setDialogState(() {
                                    dialogError = 'Kata sandi baru minimal 6 karakter.';
                                  });
                                  return;
                                }
                                if (newPass == oldPass) {
                                  setDialogState(() {
                                    dialogError = 'Kata sandi baru harus berbeda dari kata sandi lama.';
                                  });
                                  return;
                                }
                                if (newPass != confirmPass) {
                                  setDialogState(() {
                                    dialogError = 'Konfirmasi kata sandi baru tidak cocok.';
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  isSubmitting = true;
                                  dialogError = null;
                                });

                                try {
                                  final empId = SessionManager.employeeId ?? '';
                                  await AuthService().changeEmployeePassword(
                                    employeeId: empId,
                                    oldPassword: oldPass,
                                    newPassword: newPass,
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  _showNotificationBanner();
                                } on ApiException catch (e) {
                                  setDialogState(() {
                                    dialogError = e.message;
                                    isSubmitting = false;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    dialogError = 'Gagal mengubah kata sandi: $e';
                                    isSubmitting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Ubah Kata Sandi',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFF04438),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Keluar Akun Pegawai',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apakah Anda yakin ingin keluar dari akun pegawai ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD0D5DD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF344054),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () async {
                            await AppCacheManager.clearAll();
                            await SessionManager.logoutEmployee();
                            if (!context.mounted) return;

                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.loginPegawai,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF04438),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColor.black,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil Pegawai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const SafeArea(child: ProfilSkeleton())
          : SafeArea(
              child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppNotificationBanner(
                isVisible: _showSuccessBanner,
                isSuccess: true,
                message: 'Ubah Kata Sandi Berhasil',
                onClose: _hideNotificationBanner,
              ),

              const SizedBox(height: 24),

              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile.png',
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 46,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                SessionManager.employeeName ?? '-',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.black,
                ),
              ),
              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColor.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  SessionManager.employeeRole ?? '-',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Profil',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    const SizedBox(height: 12),

                    _buildProfileField('Nama Usaha', SessionManager.companyName ?? '-'),
                    const SizedBox(height: 14),
                    _buildProfileField('Username Pegawai', SessionManager.employeeName ?? '-'),
                    const SizedBox(height: 14),
                    _buildProfileField('Pekerjaan Pegawai', SessionManager.employeeRole ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutConfirmation,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Keluar Akun Pegawai',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF04438),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _openUbahKataSandiDialog,
                        icon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 17,
                          color: AppColor.primaryDark,
                        ),
                        label: const Text(
                          'Ubah Kata Sandi',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColor.primaryDark,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFD0D5DD),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      bottomNavigationBar: widget.isEmbedded
          ? null
          : Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEAECF0), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Beranda',
                  onTap: () {
                    final isCutting =
                        (SessionManager.employeeRole ?? '').toLowerCase().contains('cut');
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      isCutting ? AppRoutes.berandaCutting : AppRoutes.home,
                      (route) => false,
                    );
                  },
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.work_outline_rounded,
                  activeIcon: Icons.work_rounded,
                  label: 'Pekerjaan Saya',
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.pekerjaanSaya,
                    );
                  },
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Laporan',
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.laporan,
                    );
                  },
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 22,
            color: isActive ? AppColor.primary : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColor.primary : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

