class EmployeeJobItem {
  final String idItem;
  final String nama;
  final String barcode;
  final int jumlah;
  final String satuan;
  final num harga;

  EmployeeJobItem({
    required this.idItem,
    required this.nama,
    required this.barcode,
    required this.jumlah,
    this.satuan = 'PCS',
    this.harga = 0,
  });

  factory EmployeeJobItem.fromJson(Map<String, dynamic> json) {
    return EmployeeJobItem(
      idItem: json['iditem']?.toString() ?? json['idItem']?.toString() ?? '',
      nama: json['nama']?.toString() ?? json['name']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      satuan: json['satuan']?.toString() ?? 'PCS',
      harga: num.tryParse(json['harga']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iditem': idItem,
      'nama': nama,
      'barcode': barcode,
      'jumlah': jumlah,
      'satuan': satuan,
      'harga': harga,
    };
  }
}

class EmployeeJobModel {
  final String idProyek;
  final String namaProyek;
  final String? kodeProyek;
  final String? pemesan;
  final String? jenis;
  final String? koordinator;
  final String? deadline;
  final int sisaHari;
  final String statusWaktu;
  final int totalTarget;
  final int progressTersedia;
  final num upahSatuan;
  final List<EmployeeJobItem> items;
  final dynamic rawData;

  EmployeeJobModel({
    required this.idProyek,
    required this.namaProyek,
    this.kodeProyek,
    this.pemesan,
    this.jenis,
    this.koordinator,
    this.deadline,
    this.sisaHari = 0,
    this.statusWaktu = 'Normal',
    this.totalTarget = 0,
    this.progressTersedia = 0,
    this.upahSatuan = 0,
    this.items = const [],
    this.rawData,
  });

  factory EmployeeJobModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<EmployeeJobItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => EmployeeJobItem.fromJson(e))
          .toList();
    }

    final id = json['idproyek']?.toString() ??
        json['id_proyek']?.toString() ??
        json['idProyek']?.toString() ??
        json['id']?.toString() ??
        '';

    final name = json['nama_proyek']?.toString() ??
        json['nama']?.toString() ??
        json['project_name']?.toString() ??
        'Proyek';

    final sisa = int.tryParse(json['sisa_hari']?.toString() ??
            json['days_left']?.toString() ??
            '0') ??
        0;

    return EmployeeJobModel(
      idProyek: id,
      namaProyek: name,
      kodeProyek: json['kode_proyek']?.toString() ?? json['kode']?.toString(),
      pemesan: json['pemesan']?.toString() ?? json['customer']?.toString(),
      jenis: json['jenis']?.toString() ?? json['category']?.toString(),
      koordinator: json['koordinator']?.toString(),
      deadline: json['tenggat_waktu']?.toString() ?? json['deadline']?.toString(),
      sisaHari: sisa,
      statusWaktu: json['status_waktu']?.toString() ?? (sisa <= 2 ? 'Mendesak' : 'Normal'),
      totalTarget: int.tryParse(json['total_target']?.toString() ?? json['target']?.toString() ?? '0') ?? 0,
      progressTersedia: int.tryParse(json['progress_tersedia']?.toString() ?? json['available']?.toString() ?? '0') ?? 0,
      upahSatuan: num.tryParse(json['upah_satuan']?.toString() ?? json['wage']?.toString() ?? json['harga']?.toString() ?? '0') ?? 0,
      items: parsedItems,
      rawData: json,
    );
  }
}

