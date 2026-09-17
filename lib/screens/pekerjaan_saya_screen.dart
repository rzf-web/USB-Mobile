import 'dart:async';
import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import '../core/session/session_manager.dart';
import '../routes/app_routes.dart';
import '../services/konveksi_service.dart';
import '../widgets/skeleton.dart';
import '../core/utils/app_formatter.dart';


class PekerjaanSayaScreen extends StatefulWidget {
  const PekerjaanSayaScreen({super.key});

  @override
  State<PekerjaanSayaScreen> createState() => _PekerjaanSayaScreenState();
}

class _PekerjaanSayaScreenState extends State<PekerjaanSayaScreen> {
  int _selectedTab = 0;
  final int _currentNavIndex = 1;
  bool _isLoading = true;

  String? _activeFilter;
  bool _showSuccessBanner = false;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _projectJobs = [];
  final List<Map<String, dynamic>> _productJobs = [];

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

  late String _selectedYear;
  late String _selectedMonth;

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

  void _loadFromCacheIfExists() {
    final empId = SessionManager.employeeId;
    final empRole = SessionManager.employeeRole ?? '';
    if (empId == null || empId.isEmpty) return;

    final (startDate, endDate) =
        AppFormatter.dateRangeForMonth(_selectedYear, _selectedMonth);
    final cachedJobs = KonveksiService().getCachedMyJobs(
      idPegawai: empId,
      kerja: empRole,
      startDate: startDate,
      endDate: endDate,
    );

    if (cachedJobs != null) {
      final List<Map<String, dynamic>> loadedProjectJobs = [];
      final List<Map<String, dynamic>> loadedProductJobs = [];

      for (final job in cachedJobs) {
        final jenisLower = (job.jenis ?? '').toLowerCase();
        final idUpper = job.idProyek.toUpperCase();
        final isProd = jenisLower.contains('produk') ||
            jenisLower.contains('stok') ||
            jenisLower.contains('stock') ||
            idUpper.startsWith('PRD') ||
            idUpper.startsWith('MB');
        final barcode = job.items.isNotEmpty ? job.items.first.barcode : '';
        final idItem = job.items.isNotEmpty ? job.items.first.idItem : '';
        final item = {
          'idproyek': job.idProyek,
          'code': job.kodeProyek ?? job.idProyek,
          'date': job.deadline ?? '-',
          'name': job.namaProyek,
          'taken': job.progressTersedia,
          'priority': job.statusWaktu,
          'unit': job.items.isNotEmpty ? job.items.first.satuan : 'Pcs',
          'pricePerUnit': job.upahSatuan.toInt(),
          'productCode': barcode.isNotEmpty ? barcode : job.idProyek,
          'barcode': barcode,
          'iditem': idItem,
          'pemesan': job.pemesan ?? '-',
          'jenis': job.jenis ?? '-',
          'koordinator': job.koordinator ?? '-',
          'itemCount': job.items.isNotEmpty ? job.items.first.jumlah : job.totalTarget,
          'isProduct': isProd,
          'photo': job.photo,
          'photo1': job.photo1,
        };

        if (isProd) {
          loadedProductJobs.add(item);
        } else {
          loadedProjectJobs.add(item);
        }
      }

      if (mounted) {
        setState(() {
          _projectJobs.clear();
          _projectJobs.addAll(loadedProjectJobs);
          _productJobs.clear();
          _productJobs.addAll(loadedProductJobs);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    final empId = SessionManager.employeeId;
    final empRole = SessionManager.employeeRole ?? '';
    if (empId == null || empId.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    // Tampilkan data dari cache lokal (0 ms)
    _loadFromCacheIfExists();

    try {
      final (startDate, endDate) =
          AppFormatter.dateRangeForMonth(_selectedYear, _selectedMonth);
      final jobs = await KonveksiService().getMyJobs(
        idPegawai: empId,
        kerja: empRole,
        startDate: startDate,
        endDate: endDate,
      );
      if (!mounted) return;
      _projectJobs.clear();
      _productJobs.clear();

      for (final job in jobs) {
        final jenisLower = (job.jenis ?? '').toLowerCase();
        final idUpper = job.idProyek.toUpperCase();
        final isProd = jenisLower.contains('produk') ||
            jenisLower.contains('stok') ||
            jenisLower.contains('stock') ||
            idUpper.startsWith('PRD') ||
            idUpper.startsWith('MB');
        final barcode = job.items.isNotEmpty ? job.items.first.barcode : '';
        final idItem = job.items.isNotEmpty ? job.items.first.idItem : '';
        final item = {
          'idproyek': job.idProyek,
          'code': job.kodeProyek ?? job.idProyek,
          'date': job.deadline ?? '-',
          'name': job.namaProyek,
          'taken': job.progressTersedia,
          'priority': job.statusWaktu,
          'unit': job.items.isNotEmpty ? job.items.first.satuan : 'Pcs',
          'pricePerUnit': job.upahSatuan.toInt(),
          'productCode': barcode.isNotEmpty ? barcode : job.idProyek,
          'barcode': barcode,
          'iditem': idItem,
          'pemesan': job.pemesan ?? '-',
          'jenis': job.jenis ?? '-',
          'koordinator': job.koordinator ?? '-',
          'itemCount': job.items.isNotEmpty ? job.items.first.jumlah : job.totalTarget,
          'isProduct': isProd,
          'photo': job.photo,
          'photo1': job.photo1,
        };

        if (isProd) {
          _productJobs.add(item);
        } else {
          _projectJobs.add(item);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
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

  List<Map<String, dynamic>> get _filteredJobs {
    final currentList = _selectedTab == 0 ? _projectJobs : _productJobs;
    if (_activeFilter == null) {
      return currentList;
    }
    return currentList
        .where((job) => job['priority'] == _activeFilter)
        .toList();
  }

  void _openFilterDialog() {
    String? tempSelected = _activeFilter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Status Proyek',
                          style: TextStyle(
                            fontSize: 13.5,
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
                    const SizedBox(height: 8),
                    ...['Krisis', 'Tinggi', 'Sedang', 'Rendah'].map((priority) {
                      final bool isSelected = tempSelected == priority;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            tempSelected = priority;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColor.primary
                                        : const Color(0xFFD0D5DD),
                                    width: isSelected ? 4.5 : 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                priority,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: tempSelected == null
                            ? null
                            : () {
                                setState(() {
                                  _activeFilter = tempSelected;
                                });
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryDark,
                          disabledBackgroundColor: const Color(0xFF64748B),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Simpan',
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

  void _openSetorHasilModal(Map<String, dynamic> job) {
    final TextEditingController countController = TextEditingController();
    String? selectedGrade;
    int calculatedIncome = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Expanded(
                          child: Text(
                            'Setor Hasil',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColor.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nama Produk',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jumlah Pekerjaan Diambil',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
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
                            const SizedBox(height: 8),
                            Text(
                              'Satuan',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job['unit'],
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
                              'Prioritas Proyek',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
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
                            const SizedBox(height: 8),
                            Text(
                              'Upah Satuan',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatter.rupiah(job['pricePerUnit']),
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Setor Pekerjaan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.black,
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColor.primary,
                                    width: 1.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: AppColor.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jumlah Setor Pekerjaan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFD0D5DD),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: countController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColor.black,
                                        ),
                                        onChanged: (val) {
                                          final count = int.tryParse(val) ?? 0;
                                          setModalState(() {
                                            calculatedIncome = count *
                                                (job['pricePerUnit'] as int);
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                          hintStyle: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF98A2B3),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Status',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFD0D5DD),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedGrade,
                                          hint: const Text(
                                            '- pilih -',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF98A2B3),
                                            ),
                                          ),
                                          isExpanded: true,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          items: ['Grade A', 'Grade B', 'Reject']
                                              .map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColor.black,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setModalState(() {
                                              selectedGrade = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pendapatan',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                AppFormatter.rupiah(calculatedIncome),
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
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          final count = int.tryParse(countController.text) ?? 0;
                          if (count <= 0) return;

                          Navigator.pop(context);

                          final empId = SessionManager.employeeId ?? '';
                          final empName = SessionManager.employeeName ?? '';
                          final empRole = SessionManager.employeeRole ?? '';
                          final pricePerUnit = job['pricePerUnit'] ?? 0;

                          try {
                            final res = await KonveksiService().submitWork(
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

                            if (!mounted) return;
                            if (res.success) {
                              _showNotificationBanner();
                              _loadInitialData();
                            }
                          } catch (_) {}
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Setor Sekarang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final jobs = _filteredJobs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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
          'Pekerjaan Saya',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openFilterDialog,
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColor.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const PekerjaanSayaSkeleton()
          : SafeArea(
              child: Column(
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
              child: _showSuccessBanner
                  ? Container(
                      key: const ValueKey('pekerjaan_saya_success_banner'),
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA6F4C5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                            color: Color(0xFF027A48),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Setor Pekerjaan Berhasil',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF027A48),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFF027A48),
                            ),
                            onPressed: _hideNotificationBanner,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            if (_activeFilter != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Hasil filter prioritas proyek : ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        children: [
                          TextSpan(
                            text: _activeFilter,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColor.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () {
                        setState(() {
                          _activeFilter = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Periode Pekerjaan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColor.black,
                    ),
                  ),
                  Row(
                    children: [
                      _buildDropdownYearPill(),
                      const SizedBox(width: 6),
                      _buildDropdownMonthPill(),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Container(
                height: 42,
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
                            color: _selectedTab == 0
                                ? AppColor.primaryDark
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Proyek',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedTab == 0
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
                            color: _selectedTab == 1
                                ? AppColor.primaryDark
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Produk',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedTab == 1
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

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitialData,
                child: jobs.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          return _buildJobCard(job);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
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
                  onTap: () {},
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

  Widget _buildJobCard(Map<String, dynamic> job) {
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _openSetorHasilModal(job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Setor Hasil',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        AppRoutes.detailPekerjaan,
                        arguments: {
                          ...job,
                          'isProduct': _selectedTab == 1,
                        },
                      );
                      if (result == true) {
                        _showNotificationBanner();
                        _loadInitialData();
                      }
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
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
            Text.rich(
              TextSpan(
                text: _activeFilter != null
                    ? 'Tidak Ada Pekerjaan dengan prioritas\n'
                    : 'Tidak Ada Pekerjaan',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  if (_activeFilter != null)
                    TextSpan(
                      text: _activeFilter,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColor.black,
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
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

  Widget _buildDropdownYearPill() {
    return Container(
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
              _loadInitialData();
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
              _loadInitialData();
            }
          },

        ),
      ),
    );

  }
}

