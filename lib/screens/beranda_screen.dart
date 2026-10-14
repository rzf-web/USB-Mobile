import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constant/app_color.dart';
import '../core/session/session_manager.dart';
import '../models/konveksi/employee_earnings_model.dart';
import '../models/konveksi/employee_job_model.dart';
import '../routes/app_routes.dart';
import '../services/konveksi_service.dart';
import '../widgets/app_notification_banner.dart';
import '../widgets/skeleton.dart';
import '../widgets/take_order_bottom_sheet.dart';
import '../core/utils/app_formatter.dart';

class BerandaScreen extends StatefulWidget {
  final bool isEmbedded;

  const BerandaScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  int _currentNavIndex = 0;
  int _selectedTabIndex = 0;

  late String _selectedYear;
  late String _selectedMonth;
  int _fetchEarningsSeq = 0;
  bool _showSuccessBanner = false;
  bool _showFailBanner = false;
  Timer? _bannerTimer;
  bool _isLoading = true;
  int _completedCount = 0;
  int _totalEarnings = 0;

  final List<Map<String, dynamic>> _projectJobs = [];
  final List<Map<String, dynamic>> _productJobs = [];

  List<Map<String, dynamic>> get _currentJobs =>
      _selectedTabIndex == 0 ? _projectJobs : _productJobs;

  void _showNotificationBanner({required bool success}) {
    _bannerTimer?.cancel();
    setState(() {
      _showSuccessBanner = success;
      _showFailBanner = !success;
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year.toString();
    _selectedMonth = AppFormatter.monthName(now.month);
    _loadJobs();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  List<String> get _years => AppFormatter.getYearList(
        selectedYear: _selectedYear,
      );

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
      final List<Map<String, dynamic>> loadedProjectJobs = [];
      final List<Map<String, dynamic>> loadedProductJobs = [];

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
              idUpper.startsWith('MB');

          final jobMap = {
            'idproyek': job.idProyek,
            'iditem': idItem,
            'barcode': barcode,
            'code': job.kodeProyek ?? job.idProyek,
            'date': job.deadline ?? '-',
            'name': job.namaProyek,
            'available': job.progressTersedia,
            'priority': job.statusWaktu,
            'unit': unit,
            'pricePerUnit': pricePerUnit.toInt(),
            'pemesan': job.pemesan ?? '-',
            'jenis': job.jenis ?? '-',
            'koordinator': job.koordinator ?? '-',
            'itemCount': job.items.isNotEmpty ? job.items.first.jumlah : job.totalTarget,
            'isProduct': isProd,
            'photo': job.photo,
            'photo1': job.photo1,
          };

          if (isProd) {
            loadedProductJobs.add(jobMap);
          } else {
            loadedProjectJobs.add(jobMap);
          }
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
            _projectJobs.clear();
            _projectJobs.addAll(loadedProjectJobs);
            _productJobs.clear();
            _productJobs.addAll(loadedProductJobs);
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

    final currentSeq = ++_fetchEarningsSeq;
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
      if (!mounted || currentSeq != _fetchEarningsSeq) return;

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

      final List<Map<String, dynamic>> loadedProjectJobs = [];
      final List<Map<String, dynamic>> loadedProductJobs = [];

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
            idUpper.startsWith('MB');

        final jobMap = {
          'idproyek': job.idProyek,
          'iditem': idItem,
          'barcode': barcode,
          'code': job.kodeProyek ?? job.idProyek,
          'date': job.deadline ?? '-',
          'name': job.namaProyek,
          'available': job.progressTersedia,
          'priority': job.statusWaktu,
          'unit': unit,
          'pricePerUnit': pricePerUnit.toInt(),
          'pemesan': job.pemesan ?? '-',
          'jenis': job.jenis ?? '-',
          'koordinator': job.koordinator ?? '-',
          'itemCount': job.items.isNotEmpty ? job.items.first.jumlah : job.totalTarget,
          'isProduct': isProd,
          'photo': job.photo,
          'photo1': job.photo1,
        };

        if (isProd) {
          loadedProductJobs.add(jobMap);
        } else {
          loadedProjectJobs.add(jobMap);
        }
      }

      if (!mounted || currentSeq != _fetchEarningsSeq) return;

      setState(() {
        _projectJobs.clear();
        _projectJobs.addAll(loadedProjectJobs);
        _productJobs.clear();
        _productJobs.addAll(loadedProductJobs);
        _completedCount = completed;
        _totalEarnings = totalEarning;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        if (_projectJobs.isEmpty && _productJobs.isEmpty) {
          setState(() {
            _projectJobs.clear();
            _productJobs.clear();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loadJobs() async {
    final empId = SessionManager.employeeId;
    if (empId == null || empId.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Tampilkan data cache terlebih dahulu (0 ms)
    _loadFromCacheIfExists();

    try {
      await _fetchEarningsAndJobs();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _openAmbilPekerjaanModal(Map<String, dynamic> job) {
    TakeOrderBottomSheet.show(
      context,
      job: job,
      onSubmit: (count) async {
        final empId = SessionManager.employeeId ?? '';
        final empName = SessionManager.employeeName ?? '';
        final empRole = SessionManager.employeeRole ?? '';
        final pricePerUnit = (job['pricePerUnit'] as num?)?.toInt() ?? 0;

        final res = await KonveksiService().takeOrder(
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

        if (res.success) {
          _showNotificationBanner(success: true);
          _fetchEarningsAndJobs();
          return true;
        } else {
          _showNotificationBanner(success: false);
          return false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        color: AppColor.primary,
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                      isVisible: _showSuccessBanner || _showFailBanner,
                      isSuccess: _showSuccessBanner,
                      message: _showSuccessBanner
                          ? 'Pekerjaan Berhasil Ditambahkan'
                          : 'Pekerjaan Gagal Ditambahkan',
                      onClose: _hideNotificationBanner,
                    ),
                  ),
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
                            border: Border.all(color: const Color(0xD9FFFFFF), width: 2),
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
                                'Selamat Datang, ${SessionManager.employeeName ?? '-'}!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Text(
                                    'Pekerjaan Anda ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      SessionManager.employeeRole ?? '-',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        const Text(
                                          'Proyek Selesai',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        const Text(
                                          'Pendapatan',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTabChanged(0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 0
                                      ? AppColor.primaryDark
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Proyek',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedTabIndex == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedTabIndex == 0
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTabChanged(1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 1
                                      ? AppColor.primaryDark
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Produk',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedTabIndex == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedTabIndex == 1
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pekerjaan Tersedia',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTabIndex == 0
                              ? 'Pilih proyek dan mulai bekerja.'
                              : 'Pilih produk dan mulai bekerja.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _currentJobs.isNotEmpty
                        ? Column(
                            children: _currentJobs
                                .map(
                                  (job) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildJobCard(job),
                                  ),
                                )
                                .toList(),
                          )
                        : _buildEmptyState(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
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
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.work_outline_rounded,
                  activeIcon: Icons.work_rounded,
                  label: 'Pekerjaan Saya',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Laporan',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
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
              _loadFromCacheIfExists();
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
              _loadFromCacheIfExists();
              _fetchEarningsAndJobs();
            }
          },

        ),
      ),
    );

  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final int available = (job['available'] as num?)?.toInt() ?? 0;
    final int pricePerUnit = (job['pricePerUnit'] as num?)?.toInt() ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.detailPekerjaan,
            arguments: {
              'idproyek': job['idproyek'],
              'code': job['code'],
              'date': job['date'],
              'name': job['name'],
              'taken': job['available'],
              'priority': job['priority'],
              'unit': job['unit'],
              'pricePerUnit': job['pricePerUnit'],
              'productCode': job['barcode'],
              'barcode': job['barcode'],
              'iditem': job['iditem'],
              'pemesan': job['pemesan'],
              'jenis': job['jenis'],
              'koordinator': job['koordinator'],
              'itemCount': job['itemCount'],
              'isProduct': job['isProduct'],
              'photo': job['photo'] ?? '',
              'photo1': job['photo1'] ?? '',
              'isLaporan': false,
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAECF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      job['code'] ?? '-',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475467),
                      ),
                    ),
                  ),
                  Text(
                    job['date'] ?? '-',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job['name'] ?? '-',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.black,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah Pekerjaan Tersedia',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$available',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColor.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Satuan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job['unit'] ?? 'Pcs',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.black,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTabIndex == 0
                            ? 'Prioritas Proyek'
                            : 'Prioritas Produk',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
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
                              job['priority'] ?? 'Sedang',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF027A48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upah Satuan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
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
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _openAmbilPekerjaanModal(job),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryDark,
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadJobs();
              },
              child: const Text(
                'Muat Ulang',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
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
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColor.primary : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

