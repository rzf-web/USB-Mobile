import 'package:flutter/material.dart';

/// Banner notifikasi mengambang (floating banner) yang konsisten untuk seluruh screen.
/// Mendukung status sukses (hijau) dan gagal (merah) beserta tombol tutup.
class AppNotificationBanner extends StatelessWidget {
  final bool isVisible;
  final bool isSuccess;
  final String? message;
  final IconData? icon;
  final VoidCallback onClose;

  const AppNotificationBanner({
    super.key,
    required this.isVisible,
    required this.isSuccess,
    this.message,
    this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final bgColor = isSuccess ? const Color(0xFFECFDF3) : const Color(0xFFFEF3F2);
    final borderColor = isSuccess ? const Color(0xFFA6F4C5) : const Color(0xFFFECDCA);
    final iconColor = isSuccess ? const Color(0xFF027A48) : const Color(0xFFB42318);
    final textColor = iconColor;

    final defaultText = isSuccess
        ? 'Pekerjaan berhasil diambil!'
        : 'Jumlah tidak valid atau gagal memproses pekerjaan';
    final displayText = (message != null && message!.isNotEmpty) ? message! : defaultText;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
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
          Icon(
            icon ??
                (isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded),
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
