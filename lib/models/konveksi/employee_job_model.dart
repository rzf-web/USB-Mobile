class EmployeeJobItem {
  final String idItem;
  final String nama;
  final String barcode;
  final int jumlah;
  final String satuan;
  final num harga;
  final String photo;
  final String photo1;

  EmployeeJobItem({
    required this.idItem,
    required this.nama,
    required this.barcode,
    required this.jumlah,
    this.satuan = 'PCS',
    this.harga = 0,
    this.photo = '',
    this.photo1 = '',
  });

  factory EmployeeJobItem.fromJson(Map<String, dynamic> json) {
    return EmployeeJobItem(
      idItem: json['iditem']?.toString() ?? json['idItem']?.toString() ?? '',
      nama: json['produk']?.toString() ?? json['nama']?.toString() ?? json['name']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      jumlah: num.tryParse(json['jumlahTersedia']?.toString() ?? json['jumlahOrder']?.toString() ?? json['jumlah']?.toString() ?? '0')?.toInt() ?? 0,
      satuan: json['satuan']?.toString() ?? 'Pcs',
      harga: num.tryParse(json['upah']?.toString() ?? json['harga']?.toString() ?? json['wage']?.toString() ?? '0') ?? 0,
      photo: json['photo']?.toString() ?? '',
      photo1: json['photo1']?.toString() ?? '',
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
      'photo': photo,
      'photo1': photo1,
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
  final String photo;
  final String photo1;
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
    this.photo = '',
    this.photo1 = '',
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

    if (parsedItems.isEmpty &&
        (json['iditem'] != null || json['barcode'] != null || json['produk'] != null)) {
      parsedItems = [EmployeeJobItem.fromJson(json)];
    }

    final id = json['idproyek']?.toString() ??
        json['id_proyek']?.toString() ??
        json['idProyek']?.toString() ??
        json['id']?.toString() ??
        '';

    final name = json['produk']?.toString() ??
        json['nama_proyek']?.toString() ??
        json['nama']?.toString() ??
        json['project_name']?.toString() ??
        'Proyek';

    final sisa = int.tryParse(json['sisa_hari']?.toString() ??
            json['days_left']?.toString() ??
            '0') ??
        0;

    final target = num.tryParse(json['jumlahOrder']?.toString() ??
            json['total_target']?.toString() ??
            json['target']?.toString() ??
            '0')
        ?.toInt() ??
        0;

    final available = num.tryParse(json['jumlahTersedia']?.toString() ??
            json['progress_tersedia']?.toString() ??
            json['available']?.toString() ??
            '0')
        ?.toInt() ??
        0;

    final wage = num.tryParse(json['upah']?.toString() ??
            json['upah_satuan']?.toString() ??
            json['wage']?.toString() ??
            json['harga']?.toString() ??
            '0') ??
        0;

    final photo = json['photo']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.photo : '');
    final photo1 = json['photo1']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.photo1 : '');

    String priority = json['status_waktu']?.toString() ?? '';
    if (priority.isEmpty ||
        priority == 'Belum Mulai' ||
        priority == 'Proses' ||
        priority == 'Selesai') {
      final rawPrior = json['prioritas']?.toString() ?? '';
      if (rawPrior.toLowerCase() == 'krisis') {
        priority = 'Krisis';
      } else if (rawPrior == '1' ||
          rawPrior == '1.000000' ||
          rawPrior.toLowerCase() == 'tinggi') {
        priority = 'Tinggi';
      } else if (rawPrior == '2' ||
          rawPrior == '2.000000' ||
          rawPrior.toLowerCase() == 'sedang') {
        priority = 'Sedang';
      } else if (rawPrior == '3' ||
          rawPrior == '3.000000' ||
          rawPrior == '4' ||
          rawPrior == '4.000000' ||
          rawPrior.toLowerCase() == 'rendah') {
        priority = 'Rendah';
      } else {
        priority = 'Sedang';
      }
    }

    return EmployeeJobModel(
      idProyek: id,
      namaProyek: name,
      kodeProyek: json['kode_proyek']?.toString() ?? json['kode']?.toString() ?? id,
      pemesan: json['pemesan']?.toString() ?? json['customer']?.toString(),
      jenis: json['jenis']?.toString() ?? json['category']?.toString(),
      koordinator: json['koordinator']?.toString(),
      deadline: json['deadline']?.toString() ?? json['tenggat_waktu']?.toString() ?? json['tanggal']?.toString(),
      sisaHari: sisa,
      statusWaktu: priority,
      totalTarget: target,
      progressTersedia: available,
      upahSatuan: wage,
      photo: photo,
      photo1: photo1,
      items: parsedItems,
      rawData: json,
    );
  }
}

