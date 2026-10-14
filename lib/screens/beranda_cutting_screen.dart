import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constant/app_color.dart';
import '../core/session/session_manager.dart';
import '../core/utils/app_formatter.dart';
import '../models/konveksi/employee_earnings_model.dart';
import '../models/konveksi/employee_job_model.dart';
import '../routes/app_routes.dart';
import '../services/konveksi_service.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_notification_banner.dart';
import '../widgets/skeleton.dart';
import '../widgets/take_order_bottom_sheet.dart';
import 'buat_produk_screen.dart';

class BerandaCuttingScreen extends StatefulWidget {
  final bool isEmbedded;

  const BerandaCuttingScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<BerandaCuttingScreen> createState() => _BerandaCuttingScreenState();
}

class _BerandaCuttingScreenState extends State<BerandaCuttingScreen> {
  int _currentNavIndex = 0;

  late String _selectedYear;
  late String _selectedMonth;
  int _fetchSeq = 0;

  bool _isLoading = true;
  bool _showSuccessBanner = false;
  bool _showFailBanner = false;
  String _bannerMessage = '';
  Timer? _bannerTimer;

  int _completedCount = 0;
  int _totalEarnings = 0;
  final List<Map<String, dynamic>> _availableJobs = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year.toString();
    _selectedMonth = AppFormatter.monthName(now.month);
    _loadInitialData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  List<String> get _years => AppFormatter.getYearList(
        selectedYear: _selectedYear,
      );

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _showNotificationBanner({
    required bool success,
    required String message,
  }) {
    _bannerTimer?.cancel();
    setState(() {
      _showSuccessBanner = success;
      _showFailBanner = !success;
      _bannerMessage = message;
    });
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showSuccessBanner = false;
          _showFailBanner = false;
        });
      }
    });
  }

  void _hideNotificationBanner() {
    _bannerTimer?.cancel();
    setState(() {
      _showSuccessBanner = false;
      _showFailBanner = false;
    });
  }

  void _loadFromCacheIfExists() {
    final empId = SessionManager.employeeId;
    if (empId == null || empId.isEmpty) return;

    final (startDate, endDate) =
        AppFormatter.dateRangeForMonth(_selectedYear, _selectedMonth);
    final cachedJobs = KonveksiService().getCachedAvailableJobs(
      idPegawai: empId,
      startDate: startDate,
      endDate: endDate,
    );
    final cachedEarnings = KonveksiService().getCachedEmployeeEarnings(
      idPegawai: empId,
      startDate: startDate,
      endDate: endDate,
    );

    if (cachedJobs != null || cachedEarnings != null) {
      final List<Map<String, dynamic>> loadedJobs = [];

      if (cachedJobs != null) {
        for (final job in cachedJobs) {
          if (job.progressTersedia <= 0) continue;
          final idItem = job.items.isNotEmpty ? job.items.first.idItem : '';
          final barcode = job.items.isNotEmpty ? job.items.first.barcode : '';
          final unit = job.items.isNotEmpty ? job.items.first.satuan : 'Pcs';
          final pricePerUnit = job.upahSatuan;

          final jenisLower = (job.jenis ?? '').toLowerCase();
          final idUpper = job.idProyek.toUpperCase();
          final isProd = jenisLower.contains('produk') ||
              jenisLower.contains('stok') ||
              jenisLower.contains('stock') ||
              idUpper.startsWith('PRD') ||
              idUpper.startsWith('MB') ||
              idUpper.startsWith('JL');

          loadedJobs.add({
            'idproyek': job.idProyek,
            'iditem': idItem,
            'barcode': barcode,
            'code': job.kodeProyek ?? job.idProyek,
            'date': job.deadline ?? '-',
            'name': job.namaProyek,
            'available': job.progressTersedia,
            'priority': job.statusWaktu.isNotEmpty ? job.statusWaktu : 'Prioritas',
            'unit': unit,
            'pricePerUnit': pricePerUnit.toInt(),
            'pemesan': job.pemesan ?? '-',
            'jenis': job.jenis ?? '-',
            'koordinator': job.koordinator ?? '-',
            'itemCount': job.items.isNotEmpty ? job.items.first.jumlah : job.totalTarget,
            'isProduct': isProd,
            'photo': job.photo,
            'photo1': job.photo1,
          });
        }
      }

      int completed = _completedCount;
      int totalEarning = _totalEarnings;
      if (cachedEarnings != null && cachedEarnings.success) {
        completed = cachedEarnings.items
            .where((i) => !i.status.toLowerCase().contains('belum'))
            .length;
        totalEarning = cachedEarnings.totalPendapatan.toInt();
      }

      if (mounted) {
        setState(() {
          if (cachedJobs != null) {
            _availableJobs.clear();
            _availableJobs.addAll(loadedJobs);
          }
          _completedCount = completed;
          _totalEarnings = totalEarning;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEarningsAndJobs() async {
    final empId = SessionManager.employeeId;
    if (empId == null || empId.isEmpty) return;

    final currentSeq = ++_fetchSeq;
    try {
      final (startDate, endDate) =
          AppFormatter.dateRangeForMonth(_selectedYear, _selectedMonth);

      final jobsFuture = KonveksiService().getAvailableJobs(
        idPegawai: empId,
        startDate: startDate,
        endDate: endDate,
      );
      final earningsFuture = KonveksiService()
          .getEmployeeEarnings(
            idPegawai: empId,
            startDate: startDate,
            endDate: endDate,
          )
          .catchError((_) => EmployeeEarningsResponse(success: false));

      final results = await Future.wait([jobsFuture, earningsFuture]);
      if (!mounted || currentSeq != _fetchSeq) return;

      final jobs = results[0] as List<EmployeeJobModel>;
      final earningsRes = results[1] as EmployeeEarningsResponse;

      int completed = 0;
      int totalEarning = 0;
      if (earningsRes.success) {
        completed = earningsRes.items
            .where((i) => !i.status.toLowerCase().contains('belum'))
            .length;
        totalEarning = earningsRes.totalPendapatan.toInt();
      }

      final List<Map<String, dynamic>> loadedJobs = [];

      for (final job in jobs) {
        if (job.progressTersedia <= 0) continue;

        final idItem = job.items.isNotEmpty ? job.items.first.idItem : '';
        final barcode = job.items.isNotEmpty ? job.items.first.barcode : '';
        final unit = job.items.isNotEmpty ? job.items.first.satuan : 'Pcs';
        num pricePerUnit = job.upahSatuan;

        if (pricePerUnit <= 0 && barcode.isNotEmpty) {
          try {
            final role = SessionManager.employeeRole ?? '';
            final wage = await KonveksiService().getJobWage(
              barcode: barcode,
              idItem: idItem,
              idPegawai: empId,
              pekerjaan: role,
            );
            if (wage > 0) {
              pricePerUnit = wage;
            }
          } catch (_) {}
        }

        final jenisLower = (job.jenis ?? '').toLowerCase();
        final idUpper = job.idProyek.toUpperCase();
        final isProd = jenisLower.contains('produk') ||
            jenisLower.contains('stok') ||
            jenisLower.contains('stock') ||
            idUpper.startsWith('PRD') ||
            idUpper.startsWith('MB') ||
            idUpper.startsWith('JL');

        loadedJobs.add({
          'idproyek': job.idProyek,
          'iditem': idItem,
          'barcode': barcode,
          'code': job.kodeProyek ?? job.idProyek,
          'date': job.deadline ?? '-',
          'name': job.namaProyek,
          'available': job.progressTersedia,
          'priority': job.statusWaktu.isNotEmpty ? job.statusWaktu : 'Prioritas',
          'unit': unit,
          'pricePerUnit': pricePerUnit.toInt(),
          'pemesan': job.pemesan ?? '-',
          'jenis': job.jenis ?? '-',
          'koordinator': job.koordinator ?? '-',
          'itemCount': job.items.isNotEmpty ? job.items.first.jumlah : job.totalTarget,
          'isProduct': isProd,
          'photo': job.photo,
          'photo1': job.photo1,
        });
      }

      if (!mounted || currentSeq != _fetchSeq) return;

      setState(() {
        _availableJobs.clear();
        _availableJobs.addAll(loadedJobs);
        _completedCount = completed;
        _totalEarnings = totalEarning;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    final empId = SessionManager.employeeId;
    if (empId == null || empId.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _loadFromCacheIfExists();

    try {
      await _fetchEarningsAndJobs();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openTakeOrderModal(Map<String, dynamic> job) {
    TakeOrderBottomSheet.show(
      context,
      job: job,
      onSubmit: (count) async {
        final empId = SessionManager.employeeId ?? '';
        final empName = SessionManager.employeeName ?? '';
        final empRole = SessionManager.employeeRole ?? '';
        final pricePerUnit = (job['pricePerUnit'] as num?)?.toInt() ?? 0;

        try {
          if (empId.isNotEmpty &&
              job['idproyek'] != null &&
              job['idproyek'].toString().isNotEmpty) {
            await KonveksiService().takeOrder(
              idProyek: job['idproyek']?.toString() ?? '',
              idPegawai: empId,
              nama: empName,
              kerja: empRole,
              items: [
                {
                  'idproyek': job['idproyek']?.toString() ?? '',
                  'barcode': job['barcode'] ?? '',
                  'iditem': job['iditem'] ?? '',
                  'nama': job['name'] ?? '',
                  'jumlah': count,
                  'satuan': job['unit'] ?? 'Pcs',
                  'harga': pricePerUnit,
                }
              ],
            );
          }
        } catch (_) {}

        final currentAvailable = (job['available'] as num?)?.toInt() ?? 0;
        if (mounted) {
          setState(() {
            if (count >= currentAvailable) {
              _availableJobs.removeWhere((j) => j['code'] == job['code']);
            } else {
              job['available'] = currentAvailable - count;
            }
          });

          _showNotificationBanner(
            success: true,
            message: 'Pekerjaan Berhasil Ditambahkan',
          );
        }
        return true;
      },
    );
  }

  Future<void> _navigateToBuatProduk() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuatProdukScreen(),
      ),
    );

    if (result != null && mounted) {
      final Map<String, dynamic> newJob = (result is Map<String, dynamic>)
          ? result
          : {
              'idproyek': 'JL002111938239',
              'code': 'JL002111938239',
              'date': '20/08/2026',
              'name': 'Kemeja RZF Software',
              'available': 50,
              'priority': 'Sedang',
              'unit': 'Pcs',
              'pricePerUnit': 2000,
              'pemesan': 'PT Maju Jaya',
              'isProduct': true,
            };

      setState(() {
        _availableJobs.removeWhere((j) => j['code'] == newJob['code']);
        _availableJobs.insert(0, newJob);
      });
    }
  }

  Widget _buildDropdownYearPill() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          menuMaxHeight: 240,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: Color(0xFF64748B),
          ),
          isDense: true,
          items: _years.map((y) {
            return DropdownMenuItem<String>(
              value: y,
              child: Text(
                y,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475467),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != _selectedYear) {
              setState(() => _selectedYear = val);
              _fetchEarningsAndJobs();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDropdownMonthPill() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          menuMaxHeight: 240,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: Color(0xFF64748B),
          ),
          isDense: true,
          items: AppFormatter.months.map((m) {
            return DropdownMenuItem<String>(
              value: m,
              child: Text(
                m,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475467),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != _selectedMonth) {
              setState(() => _selectedMonth = val);
              _fetchEarningsAndJobs();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empName = SessionManager.employeeName ?? 'Ari';
    final firstName = empName.trim().split(' ').first;
    final role = SessionManager.employeeRole ?? 'Cutting';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          SystemNavigator.pop();
        },
        child: Scaffold(
          backgroundColor: AppColor.primary,
          body: _isLoading
              ? const SingleChildScrollView(child: BerandaSkeleton())
              : RefreshIndicator(
                  color: AppColor.primary,
                  backgroundColor: Colors.white,
                  onRefresh: _fetchEarningsAndJobs,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minHeight = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : 0.0;
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Header with Teal Background
                        Container(
                          width: double.infinity,
                          color: AppColor.primary,
                          child: SafeArea(
                            bottom: false,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _HeaderWavePainter(),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Success / Failure Notification Banner
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 280),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SizeTransition(
                                            sizeFactor: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: AppNotificationBanner(
                                        key: ValueKey('cutting_banner_${_showSuccessBanner}_$_showFailBanner'),
                                        isVisible: _showSuccessBanner || _showFailBanner,
                                        isSuccess: _showSuccessBanner,
                                        icon: Icons.notifications_active_outlined,
                                        message: _bannerMessage.isNotEmpty
                                            ? _bannerMessage
                                            : (_showSuccessBanner
                                                ? 'Pekerjaan Berhasil Ditambahkan'
                                                : 'Pekerjaan Gagal Ditambahkan'),
                                        onClose: _hideNotificationBanner,
                                      ),
                                    ),

                                // Profile header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xD9FFFFFF),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/profile.png',
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Center(
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 26,
                                                color: AppColor.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_getGreeting()}, $firstName!',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              role,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xE6FFFFFF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Notification bell button with badge
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x1A000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const Icon(
                                              Icons.notifications_none_rounded,
                                              size: 22,
                                              color: Color(0xFF1D2939),
                                            ),
                                            Positioned(
                                              top: 7,
                                              right: 7,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF04438),
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  '3',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // "Aktivitas" Card
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0F000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Aktivitas',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColor.black,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                _buildDropdownYearPill(),
                                                const SizedBox(width: 8),
                                                _buildDropdownMonthPill(),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFE8F6F4),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.assignment_turned_in_outlined,
                                                          size: 16,
                                                          color: AppColor.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Flexible(
                                                        child: Text(
                                                          'Proyek Selesai',
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            color: Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '$_completedCount',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColor.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFEF3EB),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.account_balance_wallet_outlined,
                                                          size: 16,
                                                          color: Color(0xFFF79009),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Flexible(
                                                        child: Text(
                                                          'Pendapatan',
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            color: Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    AppFormatter.rupiah(_totalEarnings),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColor.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Body White Section
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Pekerjaan Tersedia',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Pilih proyek dan mulai bekerja.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: _navigateToBuatProduk,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F5A50),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1F0A5049),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            'Buat Produk',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.add_circle_outline_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_availableJobs.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: _availableJobs
                                      .map(
                                        (job) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _buildJobCard(job),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ] else ...[
                              Expanded(
                                child: _buildEmptyState(),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
          bottomNavigationBar: widget.isEmbedded
              ? null
              : AppBottomNavBar(
                  currentIndex: _currentNavIndex,
                  onTabSelected: (index) {
                    if (index == 1) {
                      Navigator.pushNamed(context, AppRoutes.pekerjaanSaya);
                      return;
                    }
                    if (index == 2) {
                      Navigator.pushNamed(context, AppRoutes.laporan);
                      return;
                    }
                    if (index == 3) {
                      Navigator.pushNamed(context, AppRoutes.profil);
                      return;
                    }
                    setState(() {
                      _currentNavIndex = index;
                    });
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final int available = (job['available'] as num?)?.toInt() ?? 0;
    final int pricePerUnit = (job['pricePerUnit'] as num?)?.toInt() ?? 0;
    final bool isProduct = job['isProduct'] == true;
    final String code = job['code']?.toString() ?? 'JL002111938239';
    final String date = job['date']?.toString() ?? '20/08/2026';
    final String name = job['name']?.toString() ?? 'Kemeja RZF Software';
    final String unit = job['unit']?.toString() ?? 'Pcs';
    final String priority = job['priority']?.toString() ?? 'Sedang';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.detailPekerjaan,
            arguments: {
              'idproyek': job['idproyek'],
              'code': code,
              'name': name,
              'pricePerUnit': pricePerUnit,
              'available': available,
              'deadline': date,
              'unit': unit,
              'priority': priority,
              'pemesan': job['pemesan'],
              'jenis': job['jenis'],
              'koordinator': job['koordinator'],
              'itemCount': job['itemCount'],
              'isProduct': isProduct,
              'photo': job['photo'],
              'photo1': job['photo1'],
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF2F4F7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code (pill left) and Date (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Job / Product Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.black,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFF2F4F7), height: 1, thickness: 1),
              const SizedBox(height: 10),
              // 2x2 Grid (Jumlah Tersedia, Prioritas Proyek, Satuan, Upah Satuan)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jumlah Pekerjaan Tersedia',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$available',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prioritas Proyek',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF12B76A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    priority,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF027A48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Satuan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upah Satuan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          AppFormatter.rupiah(pricePerUnit),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Perkiraan Pendapatan Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Perkiraan Pendapatan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475467),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatter.rupiah(available * pricePerUnit),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action Button "Ambil Pekerjaan"
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _openTakeOrderModal(job),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5A50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ambil Pekerjaan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Image.asset(
              'assets/image 1.png',
              width: 190,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak Ada Pekerjaan',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// CustomPainter for the subtle decorative wave contour lines in the teal header.
class _HeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final subtleLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Smooth contour wave 1
    final path1 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.35,
        size.width * 0.75,
        size.height * 0.1,
        size.width,
        size.height * 0.25,
      );
    canvas.drawPath(path1, linePaint);

    // Smooth contour wave 2
    final path2 = Path()
      ..moveTo(size.width * 0.45, 0)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.5,
        size.width * 0.85,
        size.height * 0.25,
        size.width,
        size.height * 0.4,
      );
    canvas.drawPath(path2, subtleLinePaint);

    // Smooth contour wave 3
    final path3 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.2,
        size.width * 0.6,
        size.height * 0.05,
        size.width * 0.85,
        size.height * 0.15,
      );
    canvas.drawPath(path3, subtleLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
