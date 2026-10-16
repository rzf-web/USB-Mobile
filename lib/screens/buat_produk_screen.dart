import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import '../core/session/session_manager.dart';
import '../services/konveksi_service.dart';

class BahanCuttingItem {
  final String barcode;
  final String nama;
  final String satuan;
  final int jumlah;

  BahanCuttingItem({
    required this.barcode,
    required this.nama,
    required this.satuan,
    required this.jumlah,
  });
}

class HasilCuttingItem {
  final String barcode;
  final String nama;
  final String satuan;
  final int jumlah;
  String? photoName;
  String? photoAsset;

  HasilCuttingItem({
    required this.barcode,
    required this.nama,
    required this.satuan,
    required this.jumlah,
    this.photoName,
    this.photoAsset,
  });
}

class BuatProdukScreen extends StatefulWidget {
  const BuatProdukScreen({super.key});

  @override
  State<BuatProdukScreen> createState() => _BuatProdukScreenState();
}

class _BuatProdukScreenState extends State<BuatProdukScreen> {
  int _currentStep = 0;
  final TextEditingController _kodeProjectController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  String _selectedPemesan = '- Pilih -';
  String _selectedKoordinator = '- Pilih -';
  String _selectedJenisBahan = '- Pilih -';
  String _selectedPrioritas = '- Pilih -';
  String _selectedStatus = '- Pilih -';

  final TextEditingController _customPemesanController = TextEditingController();
  final TextEditingController _customKoordinatorController = TextEditingController();
  final TextEditingController _customJenisBahanController = TextEditingController();
  bool _isCustomPemesan = false;
  bool _isCustomKoordinator = false;
  bool _isCustomJenisBahan = false;
  bool _isLoadingOptions = false;

  final List<String> _pemesanOptions = ['- Pilih -'];
  final List<String> _koordinatorOptions = ['- Pilih -'];
  final List<String> _jenisBahanOptions = ['- Pilih -'];
  final List<Map<String, dynamic>> _bahanDetailList = [];

  final List<String> _prioritasOptions = [
    '- Pilih -',
    'Rendah',
    'Sedang',
    'Tinggi',
    'Urgent',
  ];

  final List<String> _statusOptions = [
    '- Pilih -',
    'Menunggu',
    'Diproses',
    'Selesai',
  ];

  // Step 2 & 3 Data
  final List<BahanCuttingItem> _bahanCuttingList = [];
  final List<HasilCuttingItem> _hasilCuttingList = [];

  String _generateDefaultProjectCode() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return 'MP$yy$mm${dd}001';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final formattedDate = '$day/$month/$year';
    _tanggalController.text = formattedDate;
    _deadlineController.text = formattedDate;
    _kodeProjectController.text = _generateDefaultProjectCode();
    _loadProjectOptions();
  }

  Future<void> _loadProjectOptions() async {
    final empId = SessionManager.employeeId ?? '';
    if (empId.isEmpty) return;
    setState(() => _isLoadingOptions = true);
    try {
      final options = await KonveksiService().getProjectOptions(idPegawai: empId);
      final pemesans = (options['pemesan'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final koordinators = (options['koordinator'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final bahanRaw = (options['bahan'] as List?)
              ?.map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
              .whereType<Map<String, dynamic>>()
              .toList() ??
          [];
      final jenisBahans = (options['jenis_bahan'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final apiKodeProject = options['kode_project']?.toString() ?? options['next_project_code']?.toString() ?? '';

      if (mounted) {
        setState(() {
          if (apiKodeProject.isNotEmpty &&
              (_kodeProjectController.text.isEmpty ||
                  _kodeProjectController.text == _generateDefaultProjectCode())) {
            _kodeProjectController.text = apiKodeProject;
          }

          final uniquePemesans = <String>{'- Pilih -'};
          for (final p in pemesans) {
            final clean = p.trim();
            if (clean.isNotEmpty &&
                clean != '-' &&
                clean != '- Pilih -' &&
                clean != '+ Ketik Pemesan Baru') {
              uniquePemesans.add(clean);
            }
          }
          uniquePemesans.add('+ Ketik Pemesan Baru');

          final uniqueKoordinators = <String>{'- Pilih -'};
          for (final k in koordinators) {
            final clean = k.trim();
            if (clean.isNotEmpty &&
                clean != '-' &&
                clean != '- Pilih -' &&
                clean != '+ Ketik Koordinator Baru') {
              uniqueKoordinators.add(clean);
            }
          }
          uniqueKoordinators.add('+ Ketik Koordinator Baru');

          _bahanDetailList.clear();
          _bahanDetailList.addAll(bahanRaw);

          final uniqueJenisBahan = <String>{'- Pilih -'};
          for (final jb in jenisBahans) {
            final clean = jb.trim();
            if (clean.isNotEmpty &&
                clean != '-' &&
                clean != '- Pilih -' &&
                clean != '+ Ketik Bahan Baru') {
              uniqueJenisBahan.add(clean);
            }
          }
          uniqueJenisBahan.add('+ Ketik Bahan Baru');

          _pemesanOptions.clear();
          _pemesanOptions.addAll(uniquePemesans);

          _koordinatorOptions.clear();
          _koordinatorOptions.addAll(uniqueKoordinators);

          _jenisBahanOptions.clear();
          _jenisBahanOptions.addAll(uniqueJenisBahan);

          _isLoadingOptions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  @override
  void dispose() {
    _kodeProjectController.dispose();
    _tanggalController.dispose();
    _deadlineController.dispose();
    _customPemesanController.dispose();
    _customKoordinatorController.dispose();
    _customJenisBahanController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              onSurface: AppColor.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        controller.text = '$day/$month/$year';
      });
    }
  }

  String get _appBarTitle {
    switch (_currentStep) {
      case 0:
        return 'Identitas Proyek';
      case 1:
        return 'Bahan Cutting';
      case 2:
        return 'Perkiraan Hasil Cutting';
      default:
        return 'Buat Produk';
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _onNext() {
    if (_currentStep == 0) {
      if (_kodeProjectController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode Project harus diisi')),
        );
        return;
      }
      setState(() {
        _currentStep = 1;
      });
    } else if (_currentStep == 1) {
      if (_bahanCuttingList.isEmpty) {
        _showTambahBahanBottomSheet();
      } else {
        setState(() {
          _currentStep = 2;
        });
      }
    } else if (_currentStep == 2) {
      if (_hasilCuttingList.isEmpty) {
        _showTambahHasilBottomSheet();
      } else {
        // Selesai / Simpan produk -> kembali ke Beranda dengan data produk
        final finalPemesan = _isCustomPemesan
            ? _customPemesanController.text.trim()
            : (_selectedPemesan != '- Pilih -' ? _selectedPemesan : '');
        final finalKoordinator = _isCustomKoordinator
            ? _customKoordinatorController.text.trim()
            : (_selectedKoordinator != '- Pilih -' ? _selectedKoordinator : '');
        final finalJenisBahan = _isCustomJenisBahan
            ? _customJenisBahanController.text.trim()
            : (_selectedJenisBahan != '- Pilih -'
                ? _selectedJenisBahan
                : (_bahanCuttingList.isNotEmpty ? _bahanCuttingList.first.nama : '-'));

        if (finalPemesan.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pemesan harus dipilih atau diisi')),
          );
          return;
        }

        final item = _hasilCuttingList.first;
        final createdData = {
          'idproyek': _kodeProjectController.text.trim(),
          'code': _kodeProjectController.text.trim(),
          'date': _tanggalController.text.trim(),
          'deadline': _deadlineController.text.trim(),
          'name': item.nama,
          'available': item.jumlah,
          'priority': _selectedPrioritas != '- Pilih -' ? _selectedPrioritas : 'Normal',
          'unit': item.satuan != '- Pilih -' ? item.satuan : 'Pcs',
          'pricePerUnit': 0,
          'pemesan': finalPemesan,
          'jenis': finalJenisBahan,
          'koordinator': finalKoordinator.isNotEmpty ? finalKoordinator : '-',
          'status': _selectedStatus != '- Pilih -' ? _selectedStatus : '-',
          'isProduct': true,
          'bahanCutting': _bahanCuttingList
              .map((b) => {
                    'barcode': b.barcode,
                    'nama': b.nama,
                    'satuan': b.satuan,
                    'jumlah': b.jumlah,
                  })
              .toList(),
          'hasilCutting': _hasilCuttingList
              .map((h) => {
                    'barcode': h.barcode,
                    'nama': h.nama,
                    'satuan': h.satuan,
                    'jumlah': h.jumlah,
                  })
              .toList(),
        };
        Navigator.pop(context, createdData);
      }
    }
  }

  void _showTambahBahanBottomSheet() {
    final barcodeCtrl = TextEditingController();
    final jumlahCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    String selectedBahanDropdown = _selectedJenisBahan != '- Pilih -' && _jenisBahanOptions.contains(_selectedJenisBahan)
        ? _selectedJenisBahan
        : (_jenisBahanOptions.length > 1 ? _jenisBahanOptions[1] : '- Pilih -');
    String selectedSatuan = '- Pilih -';

    // Auto-fill jika ada bahan yang dipilih
    if (selectedBahanDropdown != '- Pilih -' && selectedBahanDropdown != '+ Ketik Bahan Baru') {
      final matched = _bahanDetailList.firstWhere(
        (b) => (b['nama'] ?? '').toString().toLowerCase() == selectedBahanDropdown.toLowerCase(),
        orElse: () => {},
      );
      if (matched.isNotEmpty) {
        barcodeCtrl.text = matched['barcode']?.toString() ?? '';
        namaCtrl.text = matched['nama']?.toString() ?? selectedBahanDropdown;
        selectedSatuan = matched['satuan']?.toString() ?? 'Kg';
      } else {
        namaCtrl.text = selectedBahanDropdown;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tambah Bahan Cutting',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'Jenis Bahan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF344054),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Data Produk',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475467),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _jenisBahanOptions.contains(selectedBahanDropdown)
                        ? selectedBahanDropdown
                        : _jenisBahanOptions.first,
                    items: _jenisBahanOptions
                        .map(
                          (jb) => DropdownMenuItem(
                            value: jb,
                            child: Text(
                              jb,
                              style: TextStyle(
                                fontSize: 13,
                                color: jb == '- Pilih -'
                                    ? const Color(0xFF98A2B3)
                                    : (jb.startsWith('+') ? const Color(0xFF0F5A50) : AppColor.black),
                                fontWeight: jb.startsWith('+') ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          selectedBahanDropdown = val;
                          if (val != '- Pilih -' && val != '+ Ketik Bahan Baru') {
                            final matched = _bahanDetailList.firstWhere(
                              (b) => (b['nama'] ?? '').toString().toLowerCase() == val.toLowerCase(),
                              orElse: () => {},
                            );
                            if (matched.isNotEmpty) {
                              barcodeCtrl.text = matched['barcode']?.toString() ?? '';
                              namaCtrl.text = matched['nama']?.toString() ?? val;
                              selectedSatuan = matched['satuan']?.toString() ?? 'Kg';
                            } else {
                              namaCtrl.text = val;
                            }
                          } else if (val == '+ Ketik Bahan Baru') {
                            barcodeCtrl.clear();
                            namaCtrl.clear();
                          }
                        });
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Barcode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: barcodeCtrl,
                    onChanged: (val) {
                      final cleanVal = val.trim();
                      if (cleanVal.isNotEmpty) {
                        final matched = _bahanDetailList.firstWhere(
                          (b) => (b['barcode'] ?? '').toString() == cleanVal,
                          orElse: () => {},
                        );
                        if (matched.isNotEmpty) {
                          setSheetState(() {
                            namaCtrl.text = matched['nama']?.toString() ?? '';
                            selectedSatuan = matched['satuan']?.toString() ?? 'Kg';
                            final matchedNama = matched['nama']?.toString() ?? '';
                            if (_jenisBahanOptions.contains(matchedNama)) {
                              selectedBahanDropdown = matchedNama;
                            }
                          });
                        }
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukan atau cari barcode',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF98A2B3),
                      ),
                      suffixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF667085),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jumlah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: jumlahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Satuan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: ['- Pilih -', 'Kg', 'KG', 'Meter', 'Roll', 'Yard', 'Pcs'].contains(selectedSatuan)
                                  ? selectedSatuan
                                  : '- Pilih -',
                              items: ['- Pilih -', 'Kg', 'KG', 'Meter', 'Roll', 'Yard', 'Pcs']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => selectedSatuan = val);
                                }
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Nama / Spesifikasi Bahan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: namaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nama jenis bahan',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF98A2B3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final nama = namaCtrl.text.trim();
                        final barcode = barcodeCtrl.text.trim();
                        final parsedJumlah =
                            int.tryParse(jumlahCtrl.text.trim());
                        final jumlah = (parsedJumlah != null && parsedJumlah > 0)
                            ? parsedJumlah
                            : 0;
                        final satuan = selectedSatuan != '- Pilih -'
                            ? selectedSatuan
                            : '';

                        if (nama.isEmpty ||
                            barcode.isEmpty ||
                            jumlah <= 0 ||
                            satuan.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Harap lengkapi semua data bahan cutting'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _bahanCuttingList.add(
                            BahanCuttingItem(
                              barcode: barcode,
                              nama: nama,
                              satuan: satuan,
                              jumlah: jumlah,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5A50),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
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
            );
          },
        );
      },
    );
  }

  void _showTambahHasilBottomSheet() {
    final barcodeCtrl = TextEditingController();
    final jumlahCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    String selectedSatuan = '- Pilih -';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tambah Perkiraan Hasil Cutting',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Barcode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: barcodeCtrl,
                    decoration: InputDecoration(
                      hintText: 'Masukan atau cari barcode',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF98A2B3),
                      ),
                      suffixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF667085),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jumlah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: jumlahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Satuan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedSatuan,
                              items: ['- Pilih -', 'KG', 'Meter', 'Roll', 'Yard', 'Pcs']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => selectedSatuan = val);
                                }
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Nama Produk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: namaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nama produk',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF98A2B3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final nama = namaCtrl.text.trim();
                        final barcode = barcodeCtrl.text.trim();
                        final parsedJumlah =
                            int.tryParse(jumlahCtrl.text.trim());
                        final jumlah = (parsedJumlah != null && parsedJumlah > 0)
                            ? parsedJumlah
                            : 0;
                        final satuan = selectedSatuan != '- Pilih -'
                            ? selectedSatuan
                            : '';

                        if (nama.isEmpty ||
                            barcode.isEmpty ||
                            jumlah <= 0 ||
                            satuan.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Harap lengkapi semua data hasil cutting'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _hasilCuttingList.add(
                            HasilCuttingItem(
                              barcode: barcode,
                              nama: nama,
                              satuan: satuan,
                              jumlah: jumlah,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5A50),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF344054),
          ),
          onPressed: _onBack,
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
        actions: [
          if (_currentStep == 1 || _currentStep == 2)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _currentStep == 1
                    ? _showTambahBahanBottomSheet
                    : _showTambahHasilBottomSheet,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F5A50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildCurrentStepContent(),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF2F4F7), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5A50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    (_currentStep == 2 && _hasilCuttingList.isNotEmpty)
                        ? 'Simpan'
                        : 'Selanjutnya',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIdentitasProyekStep();
      case 1:
        return _buildBahanCuttingStep();
      case 2:
        return _buildHasilCuttingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdentitasProyekStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Kode Project',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF344054),
                          ),
                        ),
                        Text(
                          'Otomatis',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F5A50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _kodeProjectController,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: MP261016001',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF344054),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickDate(_tanggalController),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _tanggalController,
                          style:
                              const TextStyle(fontSize: 13, color: AppColor.black),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD0D5DD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD0D5DD)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Pemesan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Pelanggan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475467),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoadingOptions)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0F5A50)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('dropdown_pemesan_${_pemesanOptions.join(',')}'),
            initialValue: _pemesanOptions.contains(_selectedPemesan) ? _selectedPemesan : _pemesanOptions.first,
            items: _pemesanOptions
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 13,
                        color: p == '- Pilih -'
                            ? const Color(0xFF98A2B3)
                            : (p.startsWith('+') ? const Color(0xFF0F5A50) : AppColor.black),
                        fontWeight: p.startsWith('+') ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedPemesan = val;
                  _isCustomPemesan = val == '+ Ketik Pemesan Baru';
                });
              }
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
            ),
          ),
          if (_isCustomPemesan) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customPemesanController,
              style: const TextStyle(fontSize: 13, color: AppColor.black),
              decoration: InputDecoration(
                hintText: 'Ketik nama pemesan',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF98A2B3)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Jenis Bahan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Data Produk',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('dropdown_jenis_bahan_${_jenisBahanOptions.join(',')}'),
            initialValue: _jenisBahanOptions.contains(_selectedJenisBahan)
                ? _selectedJenisBahan
                : _jenisBahanOptions.first,
            items: _jenisBahanOptions
                .map(
                  (jb) => DropdownMenuItem(
                    value: jb,
                    child: Text(
                      jb,
                      style: TextStyle(
                        fontSize: 13,
                        color: jb == '- Pilih -'
                            ? const Color(0xFF98A2B3)
                            : (jb.startsWith('+') ? const Color(0xFF0F5A50) : AppColor.black),
                        fontWeight: jb.startsWith('+') ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedJenisBahan = val;
                  _isCustomJenisBahan = val == '+ Ketik Bahan Baru';
                });
              }
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
            ),
          ),
          if (_isCustomJenisBahan) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customJenisBahanController,
              style: const TextStyle(fontSize: 13, color: AppColor.black),
              decoration: InputDecoration(
                hintText: 'Ketik nama jenis bahan',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF98A2B3)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Koordinator',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Data Pegawai',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('dropdown_koordinator_${_koordinatorOptions.join(',')}'),
            initialValue: _koordinatorOptions.contains(_selectedKoordinator) ? _selectedKoordinator : _koordinatorOptions.first,
            items: _koordinatorOptions
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(
                      k,
                      style: TextStyle(
                        fontSize: 13,
                        color: k == '- Pilih -'
                            ? const Color(0xFF98A2B3)
                            : (k.startsWith('+') ? const Color(0xFF0F5A50) : AppColor.black),
                        fontWeight: k.startsWith('+') ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedKoordinator = val;
                  _isCustomKoordinator = val == '+ Ketik Koordinator Baru';
                });
              }
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
            ),
          ),
          if (_isCustomKoordinator) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customKoordinatorController,
              style: const TextStyle(fontSize: 13, color: AppColor.black),
              decoration: InputDecoration(
                hintText: 'Ketik nama koordinator',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF98A2B3)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deadline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF344054),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickDate(_deadlineController),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _deadlineController,
                          style:
                              const TextStyle(fontSize: 13, color: AppColor.black),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD0D5DD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD0D5DD)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prioritas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF344054),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPrioritas,
                      items: _prioritasOptions
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: p == '- Pilih -'
                                      ? const Color(0xFF98A2B3)
                                      : AppColor.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPrioritas = val);
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            items: _statusOptions
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        color: s == '- Pilih -'
                            ? const Color(0xFF98A2B3)
                            : AppColor.black,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBahanCuttingStep() {
    if (_bahanCuttingList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/image 1.png',
                width: 190,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              const Text(
                'Tidak Ada Bahan Cutting',
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

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _bahanCuttingList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _bahanCuttingList[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF2F4F7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.barcode,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.nama,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.satuan,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.jumlah}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _bahanCuttingList.removeAt(index);
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3F2),
                    border: Border.all(color: const Color(0xFFFECDCA)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFD92D20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHasilCuttingStep() {
    if (_hasilCuttingList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/image 1.png',
                width: 190,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              const Text(
                'Tidak Ada Perkiraan Hasil Cutting',
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

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _hasilCuttingList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _hasilCuttingList[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF2F4F7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.barcode,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.nama,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.satuan,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475467),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD0D5DD)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.jumlah}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _hasilCuttingList.removeAt(index);
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3F2),
                        border: Border.all(color: const Color(0xFFFECDCA)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Color(0xFFD92D20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    item.photoName ?? 'Belum ada foto',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475467),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        item.photoName = 'Photo1.jpg';
                        item.photoAsset = 'assets/hero-image.png';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Select file',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                ],
              ),
              if (item.photoAsset != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: const Color(0xFFF8FAFC),
                    child: Image.asset(
                      item.photoAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
