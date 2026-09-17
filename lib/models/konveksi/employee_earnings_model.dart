class EarningItem {
  final String idGaji;
  final String idProyek;
  final String namaProyek;
  final String keterangan;
  final String tanggal;
  final int jumlah;
  final String satuan;
  final num hargaSatuan;
  final num totalUpah;
  final String status;
  final String photo;
  final String photo1;

  EarningItem({
    required this.idGaji,
    required this.idProyek,
    required this.namaProyek,
    required this.keterangan,
    required this.tanggal,
    required this.jumlah,
    this.satuan = 'PCS',
    required this.hargaSatuan,
    required this.totalUpah,
    required this.status,
    this.photo = '',
    this.photo1 = '',
  });

  factory EarningItem.fromJson(Map<String, dynamic> json) {
    final qty = num.tryParse(json['qty']?.toString() ?? json['jumlah']?.toString() ?? json['finish']?.toString() ?? '0') ?? 0;
    final price = num.tryParse(json['price']?.toString() ?? json['harga']?.toString() ?? json['upah']?.toString() ?? '0') ?? 0;
    final total = num.tryParse(json['earning']?.toString() ?? json['total']?.toString() ?? '0') ?? (qty * price);

    return EarningItem(
      idGaji: json['id']?.toString() ?? json['idgaji']?.toString() ?? json['id_gaji']?.toString() ?? json['paymentId']?.toString() ?? '',
      idProyek: json['idproyek']?.toString() ?? json['id_proyek']?.toString() ?? '',
      namaProyek: json['type']?.toString() ?? json['nama_proyek']?.toString() ?? json['nama']?.toString() ?? 'Pekerjaan',
      keterangan: json['ket']?.toString() ?? json['keterangan']?.toString() ?? '',
      tanggal: json['date']?.toString() ?? json['tanggal']?.toString() ?? '',
      jumlah: qty.toInt(),
      satuan: json['satuan']?.toString() ?? 'PCS',
      hargaSatuan: price,
      totalUpah: total,
      status: json['status']?.toString() ?? 'Belum Lunas',
      photo: json['photo']?.toString() ?? '',
      photo1: json['photo1']?.toString() ?? '',
    );
  }
}

class EmployeeEarningsResponse {
  final bool success;
  final num totalPendapatan;
  final num belumDibayar;
  final num sudahDibayar;
  final List<EarningItem> items;
  final dynamic rawData;

  EmployeeEarningsResponse({
    required this.success,
    this.totalPendapatan = 0,
    this.belumDibayar = 0,
    this.sudahDibayar = 0,
    this.items = const [],
    this.rawData,
  });

  factory EmployeeEarningsResponse.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return EmployeeEarningsResponse(success: false);
    }

    List<EarningItem> list = [];
    final rawDetail = json['detail'] ??
        (json['data'] is Map<String, dynamic> ? json['data']['detail'] ?? json['data']['items'] ?? json['data']['list'] : null) ??
        json['data'] ??
        json['items'] ??
        json['rows'] ??
        json['list'];

    if (rawDetail is List) {
      list = rawDetail
          .whereType<Map<String, dynamic>>()
          .map((e) => EarningItem.fromJson(e))
          .toList();
    }

    num total = 0;
    num unpaid = 0;
    num paid = 0;

    final summary = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> && json['data']['summary'] is Map<String, dynamic>
            ? json['data']['summary'] as Map<String, dynamic>
            : null);

    if (summary != null) {
      total = num.tryParse(summary['totalEarnings']?.toString() ?? summary['total_earnings']?.toString() ?? '0') ?? 0;
      paid = num.tryParse(summary['amountPaid']?.toString() ?? summary['amount_paid']?.toString() ?? '0') ?? 0;
      unpaid = num.tryParse(summary['amountDue']?.toString() ?? summary['amount_due']?.toString() ?? '0') ?? 0;
    } else if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      total = num.tryParse(data['total_pendapatan']?.toString() ?? data['total']?.toString() ?? '0') ?? 0;
      unpaid = num.tryParse(data['belum_dibayar']?.toString() ?? data['unpaid']?.toString() ?? '0') ?? 0;
      paid = num.tryParse(data['sudah_dibayar']?.toString() ?? data['paid']?.toString() ?? '0') ?? 0;
    }

    if (total == 0 && list.isNotEmpty) {
      for (final item in list) {
        total += item.totalUpah;
        if (item.status.toLowerCase().contains('belum')) {
          unpaid += item.totalUpah;
        } else {
          paid += item.totalUpah;
        }
      }
    }

    final isSuccess = json['status'] == true || json['status'] == 200 || json['success'] == true;

    return EmployeeEarningsResponse(
      success: isSuccess,
      totalPendapatan: total,
      belumDibayar: unpaid,
      sudahDibayar: paid,
      items: list,
      rawData: json,
    );
  }
}

