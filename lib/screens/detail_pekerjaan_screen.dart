import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import '../core/session/session_manager.dart';
import '../core/utils/app_formatter.dart';
import '../routes/app_routes.dart';
import '../services/konveksi_service.dart';
import '../widgets/cached_product_image.dart';

class DetailPekerjaanScreen extends StatefulWidget {
  const DetailPekerjaanScreen({super.key});

  @override
  State<DetailPekerjaanScreen> createState() => _DetailPekerjaanScreenState();
}

class _DetailPekerjaanScreenState extends State<DetailPekerjaanScreen> {
  bool _initialized = false;
  bool _isProduct = false;
  bool _isCutting = false;
  bool _isLaporan = false;
  String? _paymentStatus;
  late int _income;
  late int _takenCount;
  late int _pricePerUnit;
  late String _idProyek;
  late String _idItem;
  late String _code;
  late String _date;
  late String _deadline;
  late String _name;
  late String _priority;
  late String _unit;
  late String _productCode;
  late String _pemesan;
  late String _jenis;
  late String _koordinator;
  late int _itemCount;
  late String _photo;
  late String _photo1;
  List<Map<String, dynamic>> _bahanCuttingList = [];
  List<Map<String, dynamic>> _hasilCuttingList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _isProduct = args['isProduct'] == true;
        _isCutting = args['isCutting'] == true ||
            (_isProduct && (SessionManager.employeeRole ?? '').toLowerCase().contains('cut'));
        _isLaporan = args['isLaporan'] == true;
        _paymentStatus = args['paymentStatus'] as String?;
        _takenCount = args['taken'] as int? ?? args['jumlah'] as int? ?? 0;
        _pricePerUnit = args['pricePerUnit'] as int? ??
            args['harga'] as int? ??
            args['upah'] as int? ??
            0;
        _income = args['income'] as int? ?? (_takenCount * _pricePerUnit);
        _idProyek = args['idproyek'] as String? ?? args['code'] as String? ?? '-';
        _idItem = args['iditem'] as String? ?? '';
        _code = args['code'] as String? ?? '-';
        _date = args['date'] as String? ?? '-';
        _deadline = args['deadline'] as String? ?? args['dedline'] as String? ?? _date;
        _name = args['name'] as String? ?? '-';
        _priority = args['priority'] as String? ?? '-';
        if (_priority == 'Belum Mulai' ||
            _priority == 'Proses' ||
            _priority == 'Selesai' ||
            _priority == '-') {
          final p = args['statusWaktu'] ?? args['status_waktu'] ?? args['prioritas'];
          if (p != null &&
              p.toString().isNotEmpty &&
              !p.toString().contains('.')) {
            _priority = p.toString();
          } else {
            _priority = 'Tinggi';
          }
        }
        _unit = args['unit'] as String? ?? 'Pcs';
        _productCode =
            args['productCode'] as String? ?? args['barcode'] as String? ?? '-';
        _pemesan = args['pemesan'] as String? ?? '-';
        _jenis = args['jenis'] as String? ?? '-';
        _koordinator = args['koordinator'] as String? ?? '-';
        _itemCount = args['itemCount'] as int? ?? _takenCount;
        _photo = args['photo'] as String? ?? '';
        _photo1 = args['photo1'] as String? ?? '';

        if (args['bahanCutting'] is List && (args['bahanCutting'] as List).isNotEmpty) {
          _bahanCuttingList = (args['bahanCutting'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          _bahanCuttingList = [];
        }

        if (args['hasilCutting'] is List && (args['hasilCutting'] as List).isNotEmpty) {
          _hasilCuttingList = (args['hasilCutting'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          _hasilCuttingList = [];
        }

        if (_pricePerUnit == 0 && _productCode.isNotEmpty && _productCode != '-') {
          final empId = SessionManager.employeeId ?? '';
          final empRole = SessionManager.employeeRole ?? '';
          if (empId.isNotEmpty && empRole.isNotEmpty) {
            KonveksiService().getJobWage(
              barcode: _productCode,
              idItem: _idItem,
              idPegawai: empId,
              pekerjaan: empRole,
            ).then((wage) {
              if (mounted && wage > 0) {
                setState(() {
                  _pricePerUnit = wage.toInt();
                  _income = _takenCount * _pricePerUnit;
                });
              }
            }).catchError((_) {});
          }
        }
      } else {
        _isProduct = false;
        _isCutting = false;
        _isLaporan = false;
        _paymentStatus = null;
        _income = 0;
        _takenCount = 0;
        _pricePerUnit = 0;
        _idProyek = '-';
        _idItem = '';
        _code = '-';
        _date = '-';
        _deadline = '-';
        _name = '-';
        _priority = '-';
        _unit = 'Pcs';
        _productCode = '-';
        _pemesan = '-';
        _jenis = '-';
        _koordinator = '-';
        _itemCount = 0;
        _photo = '';
        _photo1 = '';
        _bahanCuttingList = [];
        _hasilCuttingList = [];
      }
      _initialized = true;
    }
  }

  void _openUbahPengambilanModal() {
    final TextEditingController countController =
        TextEditingController(text: '$_takenCount');
    int calculatedIncome = _takenCount * _pricePerUnit;

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
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Expanded(
                          child: Text(
                            'Ubah Pengambilan Pekerjaan',
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
                    const SizedBox(height: 20),
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
                          const Text(
                            'Jumlah Pekerjaan Diambil',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColor.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD0D5DD)),
                            ),
                            child: TextField(
                              controller: countController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final count = int.tryParse(val) ?? 0;
                                setModalState(() {
                                  calculatedIncome = count * _pricePerUnit;
                                });
                              },
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColor.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Perkiraan Pendapatan',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppFormatter.rupiah(calculatedIncome),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColor.black,
                              ),
                            ),
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
                          final empId = SessionManager.employeeId ?? '';
                          final empRole = SessionManager.employeeRole ?? '';

                          try {
                            final projId = _idProyek.isNotEmpty && _idProyek != '-' ? _idProyek : _code;
                            await KonveksiService().updateOrder(
                              idProyek: projId,
                              idPegawai: empId,
                              kerja: empRole,
                              items: [
                                {
                                  'idproyek': projId,
                                  'iditem': _idItem,
                                  'barcode': _productCode,
                                  'nama': _name,
                                  'jumlah': count,
                                  'satuan': _unit,
                                  'harga': _pricePerUnit,
                                }
                              ],
                            );
                          } catch (_) {}

                          if (!mounted || !context.mounted) return;
                          setState(() {
                            _takenCount = count;
                            if (_isProduct) {
                              _itemCount = count;
                            }
                          });
                          Navigator.pop(context);
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

  void _openSetorHasilModal() {
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
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
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
                      _name,
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
                              '$_takenCount',
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
                              _unit,
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
                                    _priority,
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
                              AppFormatter.rupiah(_pricePerUnit),
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
                                    color: const Color(0xFF0F5A50),
                                    width: 1.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Color(0xFF0F5A50),
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
                                            calculatedIncome =
                                                count * _pricePerUnit;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                          hintStyle: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF98A2B3),
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
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
                          final empId = SessionManager.employeeId ?? '';
                          final empName = SessionManager.employeeName ?? '';
                          final empRole = SessionManager.employeeRole ?? '';

                          try {
                            if (empId.isNotEmpty) {
                              await KonveksiService().submitWork(
                                idProyek: _idProyek.isNotEmpty && _idProyek != '-'
                                    ? _idProyek
                                    : _code,
                                idPegawai: empId,
                                nama: empName,
                                kerja: empRole,
                                items: [
                                  {
                                    'barcode': _productCode,
                                    'finish': count,
                                    'jumlah': count,
                                    'satuan': _unit,
                                    'harga': _pricePerUnit,
                                    'ket':
                                        'Setoran $empRole $_name (${selectedGrade ?? 'Grade A'})',
                                    'status': 'Belum Lunas',
                                  }
                                ],
                              );
                            }

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.pop(context, true);
                          } catch (_) {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.pop(context, true);
                          }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 15,
              color: AppColor.black,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pekerjaan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: _isCutting
                    ? _buildCuttingDetailContent()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    if (_isLaporan)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _paymentStatus == 'Dibayar'
                              ? const Color(0xFFECFDF3)
                              : const Color(0xFFFEF3F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _paymentStatus == 'Dibayar'
                                      ? Icons.check
                                      : Icons.close,
                                  size: 16,
                                  color: _paymentStatus == 'Dibayar'
                                      ? const Color(0xFF12B76A)
                                      : const Color(0xFFD92D20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _paymentStatus ?? 'Dibayar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _paymentStatus == 'Dibayar'
                                        ? const Color(0xFF027A48)
                                        : const Color(0xFFD92D20),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Pendapatan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatter.rupiah(_income),
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
                    Container(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _code,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475467),
                                  ),
                                ),
                              ),
                              Text(
                                _date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF98A2B3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
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
                                    '$_takenCount',
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
                                    _unit,
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
                                        const Icon(
                                          Icons.circle,
                                          size: 6,
                                          color: Color(0xFF12B76A),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _priority,
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
                                    AppFormatter.rupiah(_pricePerUnit),
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
                          if (!_isLaporan) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    AppFormatter.rupiah(_takenCount * _pricePerUnit),
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
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: _openUbahPengambilanModal,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Color(0xFF0F5A50),
                                ),
                                label: const Text(
                                  'Ubah Pengambilan Proyek',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F5A50),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF0F5A50),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isProduct ? 'Informasi Produk' : 'Informasi Proyek',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isProduct) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInfoColumn('Nama Produk', _name),
                          ),
                          Expanded(
                            child: _buildInfoColumn('Kode Produk', _productCode),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInfoColumn('Satuan', _unit)),
                          Expanded(
                            child: _buildInfoColumn('Jumlah', '$_takenCount'),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildInfoRow('Pemesan', _pemesan),
                      const SizedBox(height: 10),
                      _buildInfoRow('Jenis', _jenis),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInfoColumn('Koordinator', _koordinator),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prioritas Proyek',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Color(0xFF12B76A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _priority,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF027A48),
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
                            child: _buildInfoColumn('Nama Produk', _name),
                          ),
                          Expanded(
                            child: _buildInfoColumn('Kode Produk', _productCode),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInfoColumn('Satuan', _unit)),
                          Expanded(
                            child: _buildInfoColumn('Jumlah', '$_itemCount'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildShirtPreview(isBack: false),
                          const SizedBox(width: 24),
                          _buildShirtPreview(isBack: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (!_isLaporan)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEAECF0)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _openSetorHasilModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5A50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Setor Hasil',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCuttingDetailContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.buatProduk);
            },
            icon: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: Color(0xFF0F5A50),
            ),
            label: const Text(
              'Ubah Proyek',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F5A50),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF0F5A50),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Identitas Proyek',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F5A50),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFEAECF0)),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoColumn(
                'Kode Project',
                _productCode.isNotEmpty && _productCode != '-'
                    ? _productCode
                    : (_code.isNotEmpty && _code != '-' ? _code : '-'),
              ),
            ),
            Expanded(
              child: _buildInfoColumn(
                'Tanggal',
                _date.isNotEmpty && _date != '-' ? _date : '-',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Pemesan',
          _pemesan.isNotEmpty && _pemesan != '-' ? _pemesan : '-',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Koordinator',
          _koordinator.isNotEmpty && _koordinator != '-' ? _koordinator : '-',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoColumn(
                'Dedline',
                _deadline.isNotEmpty && _deadline != '-' ? _deadline : '-',
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prioritas Proyek',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                          _priority.isNotEmpty && _priority != '-' ? _priority : 'Normal',
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
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Bahan Cutting',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F5A50),
          ),
        ),
        const SizedBox(height: 12),
        if (_bahanCuttingList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada rincian bahan cutting.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF98A2B3),
              ),
            ),
          )
        else
          ..._bahanCuttingList.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['barcode']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF98A2B3),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['nama']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColor.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['satuan']?.toString() ?? 'KG',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item['jumlah'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 16),
        const Text(
          'Perkiraan Hasil Cutting',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F5A50),
          ),
        ),
        const SizedBox(height: 12),
        if (_hasilCuttingList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada rincian perkiraan hasil cutting.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF98A2B3),
              ),
            ),
          )
        else
          ..._hasilCuttingList.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final bool isDelete = item['showDelete'] == true || index > 0;
            final bool showPreview = item['showPreview'] == true || index == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['barcode']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF98A2B3),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['nama']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColor.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['satuan']?.toString() ?? 'PCS',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item['jumlah'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    if (isDelete) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _hasilCuttingList.removeAt(index);
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE4E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Color(0xFFD92D20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['photoName']?.toString() ?? 'Photo1.jpg',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: const Text(
                        'Select file',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF344054),
                        ),
                      ),
                    ),
                  ],
                ),
                if (showPreview) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 44,
                              color: Color(0xFF98A2B3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 44,
                              color: Color(0xFF98A2B3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value) {
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColor.black,
          ),
        ),
      ],
    );
  }

  Widget _buildShirtPreview({required bool isBack}) {
    final photoName = isBack ? _photo1 : _photo;
    final label = isBack ? 'Tampak Belakang' : 'Tampak Depan';

    return Column(
      children: [
        Container(
          width: 140,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAECF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedProductImage(
            photoName: photoName,
            fit: BoxFit.contain,
            fallbackBuilder: (context) => const Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: Color(0xFF98A2B3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475467),
          ),
        ),
      ],
    );
  }
}


