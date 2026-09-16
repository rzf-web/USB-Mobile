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
  });

  factory EarningItem.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(json['jumlah']?.toString() ?? json['finish']?.toString() ?? '0') ?? 0;
    final price = num.tryParse(json['harga']?.toString() ?? json['upah']?.toString() ?? '0') ?? 0;
    final total = num.tryParse(json['total']?.toString() ?? '0') ?? (qty * price);

    return EarningItem(
      idGaji: json['idgaji']?.toString() ?? json['id_gaji']?.toString() ?? '',
      idProyek: json['idproyek']?.toString() ?? json['id_proyek']?.toString() ?? '',
      namaProyek: json['nama_proyek']?.toString() ?? json['nama']?.toString() ?? 'Pekerjaan',
      keterangan: json['ket']?.toString() ?? json['keterangan']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? json['date']?.toString() ?? '',
      jumlah: qty,
      satuan: json['satuan']?.toString() ?? 'PCS',
      hargaSatuan: price,
      totalUpah: total,
      status: json['status']?.toString() ?? 'Belum Lunas',
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

    final data = json['data'] ?? json;
    List<EarningItem> list = [];

    if (data is Map<String, dynamic>) {
      final rawList = data['items'] ?? data['rows'] ?? data['list'];
      if (rawList is List) {
        list = rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => EarningItem.fromJson(e))
            .toList();
      }
    } else if (data is List) {
      list = data
          .whereType<Map<String, dynamic>>()
          .map((e) => EarningItem.fromJson(e))
          .toList();
    }

    num total = 0;
    num unpaid = 0;
    num paid = 0;

    if (data is Map<String, dynamic>) {
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

    return EmployeeEarningsResponse(
      success: true,
      totalPendapatan: total,
      belumDibayar: unpaid,
      sudahDibayar: paid,
      items: list,
      rawData: json,
    );
  }
}

