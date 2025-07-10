import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RekapDataPage extends StatefulWidget {
  @override
  _RekapDataPageState createState() => _RekapDataPageState();
}

class _RekapDataPageState extends State<RekapDataPage> {
  // Menyimpan data pengiriman per tanggal
  Map<String, _RekapData> rekapData = {};

  @override
  void initState() {
    super.initState();
    _getRekapData();
  }

  Future<void> _getRekapData() async {
    final snapshot = await FirebaseFirestore.instance.collection('pengiriman').get();

    // Menyusun data berdasarkan tanggal dan menghitung total harga per tanggal
    final data = <String, _RekapData>{};

    for (var doc in snapshot.docs) {
      Timestamp timestamp = doc['tanggal'];
      String formattedDate = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
      int totalHarga = doc['total_harga'];

      // Menambahkan data untuk tanggal yang sama
      if (data.containsKey(formattedDate)) {
        data[formattedDate]!.totalHarga += totalHarga;
        data[formattedDate]!.totalPengiriman += 1;
      } else {
        data[formattedDate] = _RekapData(totalHarga: totalHarga, totalPengiriman: 1);
      }
    }

    setState(() {
      // Mengurutkan data berdasarkan tanggal secara descending
      rekapData = Map.fromEntries(
        data.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Data Pengiriman'),
      ),
      body: rekapData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: rekapData.length,
        itemBuilder: (context, index) {
          String date = rekapData.keys.elementAt(index);
          _RekapData rekap = rekapData[date]!;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(DateFormat('dd MMMM yyyy').format(DateFormat('yyyy-MM-dd').parse(date))),
              subtitle: Text('Total Pengiriman: ${rekap.totalPengiriman} pengiriman'),
              trailing: Text(
                'Rp ${NumberFormat('#,##0', 'id_ID').format(rekap.totalHarga)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RekapData {
  int totalHarga;
  int totalPengiriman;

  _RekapData({required this.totalHarga, required this.totalPengiriman});
}
