import 'package:flutter/material.dart';
import '../constant/app_color.dart';
import '../core/session/session_manager.dart';
import '../services/konveksi_service.dart';

class DetailPekerjaanScreen extends StatefulWidget {
  const DetailPekerjaanScreen({super.key});

  @override
  State<DetailPekerjaanScreen> createState() => _DetailPekerjaanScreenState();
}

class _DetailPekerjaanScreenState extends State<DetailPekerjaanScreen> {
  bool _initialized = false;
  bool _isProduct = false;
  bool _isLaporan = false;
  String? _paymentStatus;
  late int _income;
  late int _takenCount;
  late int _pricePerUnit;
  late String _code;
  late String _date;
  late String _name;
  late String _priority;
  late String _unit;
  late String _productCode;
  late String _pemesan;
  late String _jenis;
  late String _koordinator;
  late int _itemCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _isProduct = args['isProduct'] == true;
        _isLaporan = args['isLaporan'] == true;
        _paymentStatus = args['paymentStatus'] as String?;
        _takenCount = args['taken'] as int? ?? 0;
        _pricePerUnit = args['pricePerUnit'] as int? ?? 0;
        _income = args['income'] as int? ?? (_takenCount * _pricePerUnit);
        _code = args['code'] as String? ?? '-';
        _date = args['date'] as String? ?? '-';
        _name = args['name'] as String? ?? '-';
        _priority = args['priority'] as String? ?? '-';
        _unit = args['unit'] as String? ?? 'Pcs';
        _productCode = args['productCode'] as String? ?? '-';
        _pemesan = args['pemesan'] as String? ?? '-';
        _jenis = args['jenis'] as String? ?? '-';
        _koordinator = args['koordinator'] as String? ?? '-';
        _itemCount = args['itemCount'] as int? ?? 0;
      } else {
        _isProduct = false;
        _isLaporan = false;
        _paymentStatus = null;
        _income = 0;
        _takenCount = 0;
        _pricePerUnit = 0;
        _code = '-';
        _date = '-';
        _name = '-';
        _priority = '-';
        _unit = 'Pcs';
        _productCode = '-';
        _pemesan = '-';
        _jenis = '-';
        _koordinator = '-';
        _itemCount = 0;
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
                          icon: const Icon(Icons.arrow_back, size: 20),
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
                              'Rp ${_formatNumber(calculatedIncome)}',
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
                            await KonveksiService().updateOrder(
                              idProyek: _code,
                              idPegawai: empId,
                              kerja: empRole,
                              items: [
                                {
                                  'barcode': _productCode,
                                  'nama': _name,
                                  'jumlah': count,
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
                          backgroundColor: AppColor.primaryDark,
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
                              'Rp ${_formatNumber(_pricePerUnit)}',
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
                                'Rp ${_formatNumber(calculatedIncome)}',
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
                            await KonveksiService().submitWork(
                              idProyek: _code,
                              idPegawai: empId,
                              nama: empName,
                              kerja: empRole,
                              items: [
                                {
                                  'barcode': _productCode,
                                  'finish': count,
                                  'harga': _pricePerUnit,
                                  'ket': 'Setoran $empRole $_name (${selectedGrade ?? 'Grade A'})',
                                  'status': 'Belum Lunas',
                                }
                              ],
                            );
                          } catch (_) {}

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryDark,
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
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
                child: Column(
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
                                  'Rp ${_formatNumber(_income)}',
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
                                    'Rp ${_formatNumber(_pricePerUnit)}',
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
                                    'Rp ${_formatNumber(_takenCount * _pricePerUnit)}',
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
                                  color: AppColor.primaryDark,
                                ),
                                label: const Text(
                                  'Ubah Pengambilan Proyek',
                                  style: TextStyle(
                                    fontSize: 13,
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
    return Container(
      width: 130,
      height: 140,
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(120, 130),
        painter: ShirtPainter(isBack: isBack),
      ),
    );
  }
}

class ShirtPainter extends CustomPainter {
  final bool isBack;

  ShirtPainter({required this.isBack});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final fabricPaint = Paint()
      ..color = const Color(0xFF26282C)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFF1E2023)
      ..style = PaintingStyle.fill;

    final seamPaint = Paint()
      ..color = const Color(0xFF191B1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final stitchPaint = Paint()
      ..color = const Color(0xFF383C42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final double sx = w / 120.0;
    final double sy = h / 130.0;

    Offset pt(double x, double y) => Offset(x * sx, y * sy);

    final leftSleevePath = Path()
      ..moveTo(32 * sx, 22 * sy)
      ..lineTo(8 * sx, 88 * sy)
      ..lineTo(18 * sx, 92 * sy)
      ..lineTo(30 * sx, 48 * sy)
      ..close();
    canvas.drawPath(leftSleevePath, shadowPaint);
    canvas.drawPath(leftSleevePath, fabricPaint);
    canvas.drawPath(leftSleevePath, seamPaint);

    canvas.drawLine(pt(10, 82), pt(19, 86), stitchPaint);

    final rightSleevePath = Path()
      ..moveTo(88 * sx, 22 * sy)
      ..lineTo(112 * sx, 88 * sy)
      ..lineTo(102 * sx, 92 * sy)
      ..lineTo(90 * sx, 48 * sy)
      ..close();
    canvas.drawPath(rightSleevePath, shadowPaint);
    canvas.drawPath(rightSleevePath, fabricPaint);
    canvas.drawPath(rightSleevePath, seamPaint);

    canvas.drawLine(pt(110, 82), pt(101, 86), stitchPaint);

    final bodyPath = Path()
      ..moveTo(32 * sx, 22 * sy)
      ..lineTo(46 * sx, 15 * sy)
      ..quadraticBezierTo(60 * sx, isBack ? 13 * sy : 24 * sy, 74 * sx, 15 * sy)
      ..lineTo(88 * sx, 22 * sy)
      ..lineTo(89 * sx, 50 * sy)
      ..lineTo(86 * sx, 118 * sy)
      ..quadraticBezierTo(60 * sx, 122 * sy, 34 * sx, 118 * sy)
      ..lineTo(31 * sx, 50 * sy)
      ..close();

    canvas.drawPath(bodyPath, fabricPaint);
    canvas.drawPath(bodyPath, seamPaint);

    final hemPath = Path()
      ..moveTo(34 * sx, 114 * sy)
      ..quadraticBezierTo(60 * sx, 118 * sy, 86 * sx, 114 * sy);
    canvas.drawPath(hemPath, stitchPaint);

    if (!isBack) {
      final placketRect = Rect.fromLTRB(56 * sx, 20 * sy, 64 * sx, 78 * sy);
      canvas.drawRect(placketRect, shadowPaint);
      canvas.drawRect(placketRect, seamPaint);

      final buttonPaint = Paint()
        ..color = const Color(0xFF71767F)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt(60, 32), 1.6 * sx, buttonPaint);
      canvas.drawCircle(pt(60, 48), 1.6 * sx, buttonPaint);
      canvas.drawCircle(pt(60, 64), 1.6 * sx, buttonPaint);

      final collarPaint = Paint()
        ..color = const Color(0xFF2C3035)
        ..style = PaintingStyle.fill;

      final leftCollar = Path()
        ..moveTo(46 * sx, 14 * sy)
        ..lineTo(54 * sx, 34 * sy)
        ..lineTo(59 * sx, 22 * sy)
        ..close();
      canvas.drawPath(leftCollar, collarPaint);
      canvas.drawPath(leftCollar, seamPaint);

      final rightCollar = Path()
        ..moveTo(74 * sx, 14 * sy)
        ..lineTo(66 * sx, 34 * sy)
        ..lineTo(61 * sx, 22 * sy)
        ..close();
      canvas.drawPath(rightCollar, collarPaint);
      canvas.drawPath(rightCollar, seamPaint);

      final leftPocket = Rect.fromLTRB(37 * sx, 44 * sy, 51 * sx, 64 * sy);
      canvas.drawRect(leftPocket, shadowPaint);
      canvas.drawRect(leftPocket, stitchPaint);
      canvas.drawLine(pt(37, 49), pt(51, 49), stitchPaint);

      final rightPocket = Rect.fromLTRB(69 * sx, 44 * sy, 83 * sx, 64 * sy);
      canvas.drawRect(rightPocket, shadowPaint);
      canvas.drawRect(rightPocket, stitchPaint);
      canvas.drawLine(pt(69, 49), pt(83, 49), stitchPaint);

      final logoPaint = Paint()
        ..color = const Color(0xFF1677FF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt(76, 55), 3.5 * sx, logoPaint);

      final logoInnerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt(76, 55), 1.2 * sx, logoInnerPaint);
    } else {
      final backCollar = Path()
        ..moveTo(46 * sx, 15 * sy)
        ..quadraticBezierTo(60 * sx, 18 * sy, 74 * sx, 15 * sy)
        ..quadraticBezierTo(60 * sx, 12 * sy, 46 * sx, 15 * sy);
      canvas.drawPath(backCollar, shadowPaint);
      canvas.drawPath(backCollar, seamPaint);

      final yokePath = Path()
        ..moveTo(32 * sx, 34 * sy)
        ..lineTo(88 * sx, 34 * sy);
      canvas.drawPath(yokePath, stitchPaint);

      final textSpan = TextSpan(
        text: 'rzfsoftware.com',
        style: TextStyle(
          color: Colors.white,
          fontSize: 6.5 * sx,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((60 * sx) - (textPainter.width / 2), 46 * sy),
      );

      final subSpan = TextSpan(
        text: 'Smart Software Solution',
        style: TextStyle(
          color: const Color(0xFF90B0DF),
          fontSize: 3.2 * sx,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      );
      final subPainter = TextPainter(
        text: subSpan,
        textDirection: TextDirection.ltr,
      );
      subPainter.layout();
      subPainter.paint(
        canvas,
        Offset((60 * sx) - (subPainter.width / 2), 55 * sy),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

