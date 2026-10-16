import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constant/app_color.dart';
import '../core/utils/app_formatter.dart';

/// Bottom Sheet reusable untuk mengambil pekerjaan (Ambil Pekerjaan).
/// Menampilkan detail kuota, upah satuan, kalkulasi estimasi upah secara realtime,
/// validasi jumlah input, dan penanganan status pemrosesan.
class TakeOrderBottomSheet extends StatefulWidget {
  final Map<String, dynamic> job;
  final Future<bool> Function(int count) onSubmit;

  const TakeOrderBottomSheet({
    super.key,
    required this.job,
    required this.onSubmit,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> job,
    required Future<bool> Function(int count) onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TakeOrderBottomSheet(
        job: job,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<TakeOrderBottomSheet> createState() => _TakeOrderBottomSheetState();
}

class _TakeOrderBottomSheetState extends State<TakeOrderBottomSheet> {
  final TextEditingController _countController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _available => (widget.job['available'] as num?)?.toInt() ?? 0;
  int get _pricePerUnit => (widget.job['pricePerUnit'] as num?)?.toInt() ?? 0;
  String get _unit => widget.job['unit']?.toString() ?? 'Pcs';

  int get _calculatedIncome {
    final count = int.tryParse(_countController.text) ?? 0;
    return count * _pricePerUnit;
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final count = int.tryParse(_countController.text) ?? 0;
    if (count <= 0) {
      setState(() {
        _errorMessage = 'Jumlah harus lebih dari 0';
      });
      return;
    }
    if (count > _available) {
      setState(() {
        _errorMessage = 'Jumlah melebihi kuota tersedia ($_available)';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onSubmit(count);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Gagal mengambil pekerjaan. Silakan coba lagi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Terjadi kesalahan jaringan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final priority = widget.job['priority']?.toString() ?? 'Normal';
    final code = widget.job['code']?.toString() ?? '-';
    final date = widget.job['date']?.toString() ?? '-';
    final name = widget.job['name']?.toString() ?? '-';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header: Back arrow <, Centered Title "Ambil Pekerjaan"
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
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
                const Expanded(
                  child: Center(
                    child: Text(
                      'Ambil Pekerjaan',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
            const SizedBox(height: 18),
            // Job Detail Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
                  const Text(
                    'Nama Produk',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColor.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 2x2 Grid
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
                                fontSize: 11.5,
                                color: Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$_available',
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
                                fontSize: 11.5,
                                color: Color(0xFF667085),
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
                                      const SizedBox(width: 5),
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
                  const SizedBox(height: 12),
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
                                fontSize: 11.5,
                                color: Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(height: 3),
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
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upah Satuan',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(height: 3),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Input section: "Masukkan Jumlah Pekerjaan"
            const Text(
              'Masukkan Jumlah Pekerjaan',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                setState(() {
                  _errorMessage = null;
                });
              },
              decoration: InputDecoration(
                hintText: 'Jumlah pekerjaan',
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
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? const Color(0xFFD92D20)
                        : const Color(0xFFD0D5DD),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? const Color(0xFFD92D20)
                        : const Color(0xFFD0D5DD),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? const Color(0xFFD92D20)
                        : const Color(0xFF0F5A50),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD92D20),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            // Perkiraan Pendapatan
            const Text(
              'Perkiraan Pendapatan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppFormatter.rupiah(_calculatedIncome),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667085),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Button "Simpan"
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5A50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
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
      ),
    );
  }
}
