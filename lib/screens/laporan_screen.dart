import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import '../core/session/session_manager.dart';
import '../models/konveksi/employee_earnings_model.dart';
import '../routes/app_routes.dart';
import '../services/konveksi_service.dart';
import '../widgets/skeleton.dart';
import '../core/utils/app_formatter.dart';


class LaporanScreen extends StatefulWidget {
  final bool isEmbedded;
  const LaporanScreen({super.key, this.isEmbedded = false});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  int _selectedTab = 0;
  final int _currentNavIndex = 2;
  late String _selectedYear;
  late String _selectedMonth;
  int _fetchEarningsSeq = 0;
  bool _isLoading = true;
  EmployeeEarningsResponse? _earningsResponse;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year.toString();
    _selectedMonth = AppFormatter.monthName(now.month);
    _fetchEarnings(isInitial: true);
  }

  List<String> get _years => AppFormatter.getYearList(
        selectedYear: _selectedYear,
      );

  void _loadFromCacheIfExists() {
    final empId = SessionManager.employeeId;
    if (empId == null || empId.isEmpty) return;

    final (startDate, endDate) =
        AppFormatter.dateRangeForMonth(_selectedYear, _selectedMonth);
    final cached = KonveksiService().getCachedEmployeeEarnings(
      idPegawai: empId,
      startDate: startDate,
      endDate: endDate,
    );

    if (cached != null) {
      if (mounted) {
        setState(() {
          _earningsResponse = cached;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEarnings({bool isInitial = false}) async {
    final empId = SessionManager.employeeId;
    if (empId == null || empId.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Tampilkan data cache lokal terlebih dahulu (0 ms)
    _loadFromCacheIfExists();

    final currentSeq = ++_fetchEarningsSeq;
    try {
      final (startDate, endDate) =
          AppFormatter.dateRangeForMonth(_selectedYear, _selectedMonth);
      final res = await KonveksiService().getEmployeeEarnings(
        idPegawai: empId,
        startDate: startDate,
        endDate: endDate,
      );
      if (!mounted || currentSeq != _fetchEarningsSeq) return;
      setState(() {
        _earningsResponse = res;
        _isLoading = false;
      });
    } catch (_) {
    } finally {
      if (mounted && isInitial) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _onTabChanged(int index) {
    if (_selectedTab == index) return;
    setState(() {
      _selectedTab = index;
    });
  }

  int get _completedProjects {
    if (_earningsResponse == null) return 0;
    return _earningsResponse!.items
        .where((item) => !item.status.toLowerCase().contains('belum'))
        .length;
  }

  int get _paidAmount => _earningsResponse?.sudahDibayar.toInt() ?? 0;
  int get _unpaidAmount => _earningsResponse?.belumDibayar.toInt() ?? 0;

  List<Map<String, dynamic>> get _currentJobs {
    if (_earningsResponse == null) return [];
    final isPaidTab = _selectedTab == 0;
    final filtered = _earningsResponse!.items.where((item) {
      final isPaid = !item.status.toLowerCase().contains('belum');
      return isPaidTab ? isPaid : !isPaid;
    }).toList();

    return filtered.map((item) {
      final isPaid = !item.status.toLowerCase().contains('belum');
      return {
        'code': item.idProyek.isNotEmpty ? item.idProyek : item.idGaji,
        'date': item.tanggal.isNotEmpty ? item.tanggal : '-',
        'name': item.namaProyek,
        'taken': item.jumlah,
        'priority': 'Normal',
        'unit': item.satuan,
        'pricePerUnit': item.hargaSatuan.toInt(),
        'productCode': item.idProyek,
        'pemesan': item.keterangan.isNotEmpty ? item.keterangan : '-',
        'jenis': '-',
        'koordinator': '-',
        'itemCount': item.jumlah,
        'isProduct': false,
        'type': 'Proyek',
        'status': isPaid ? 'Dibayar' : 'Belum Dibayar',
        'photo': item.photo,
        'photo1': item.photo1,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _currentJobs;

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
          'Laporan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const LaporanSkeleton()
          : SafeArea(
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              padding: const EdgeInsets.all(16),
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
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
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
                                  return DropdownMenuItem(
                                    value: y,
                                    child: Text(
                                      y,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF475467),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null && val != _selectedYear) {
                                    setState(() => _selectedYear = val);
                                    _loadFromCacheIfExists();
                                    _fetchEarnings();
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
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
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF475467),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null && val != _selectedMonth) {
                                    setState(() => _selectedMonth = val);
                                    _loadFromCacheIfExists();
                                    _fetchEarnings();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 16,
                            color: Color(0xFF12B76A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Proyek Selesai',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475467),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_completedProjects',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 14,
                                      color: Color(0xFF12B76A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Sudah Dibayar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF475467),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppFormatter.rupiah(_paidAmount),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3F2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 14,
                                      color: Color(0xFFF04438),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Belum Dibayar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF475467),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppFormatter.rupiah(_unpaidAmount),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabItem(title: 'Sudah Dibayar', index: 0),
                  ),
                  Expanded(
                    child: _buildTabItem(title: 'Belum Dibayar', index: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: jobs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return _buildReportJobCard(job);
                      },
                    ),
            ),
          ],
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
                  onTap: () => Navigator.pop(context),
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
                  onTap: () {},
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.profil,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColor.primaryDark : const Color(0xFF64748B),
              ),
            ),
          ),
          Container(
            height: 2.5,
            decoration: BoxDecoration(
              color: isActive ? AppColor.primaryDark : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportJobCard(Map<String, dynamic> job) {
    final bool isPaid = _selectedTab == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isPaid ? Icons.check : Icons.close,
                    size: 14,
                    color: isPaid
                        ? const Color(0xFF12B76A)
                        : const Color(0xFFD92D20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPaid ? 'Dibayar' : 'Belum Dibayar',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isPaid
                          ? const Color(0xFF027A48)
                          : const Color(0xFFD92D20),
                    ),
                  ),
                ],
              ),
              Text(
                job['type'] ?? (job['isProduct'] == true ? 'Produk' : 'Proyek'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  job['code'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
              Text(
                job['date'],
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF98A2B3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job['name'],
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
                    'Jumlah Pekerjaan Diambil',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${job['taken']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColor.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prioritas Proyek',
                    style: TextStyle(
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
                          job['priority'],
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.detailPekerjaan,
                  arguments: {
                    ...job,
                    'isLaporan': true,
                    'paymentStatus': isPaid ? 'Dibayar' : 'Belum Dibayar',
                    'income':
                        (job['taken'] as int) * (job['pricePerUnit'] as int),
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFD0D5DD),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lihat Detail',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image 1.png',
              width: 180,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(
              _selectedTab == 0
                  ? 'Tidak Ada Pekerjaan Dibayar\nBulan $_selectedMonth $_selectedYear'
                  : 'Tidak Ada Pekerjaan Belum Dibayar\nBulan $_selectedMonth $_selectedYear',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
                height: 1.4,
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
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColor.primary : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

