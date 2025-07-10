import 'package:app_projekskripsi/AddAdminDaerahDanSupirPage.dart';
import 'package:app_projekskripsi/AddBarangPage.dart';
import 'package:app_projekskripsi/AddPengirimanPage.dart';
import 'package:app_projekskripsi/CekBarangPage.dart';
import 'package:app_projekskripsi/DokumentasiBarangPage.dart';
import 'package:app_projekskripsi/RecapDataPage.dart';
import 'package:app_projekskripsi/SearchBarangPage.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'Login.dart';

class AdminPage extends StatelessWidget {
  AdminPage({Key? key}) : super(key: key);

  final user = FirebaseAuth.instance.currentUser;

  void signout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const Login());
  }

  final List<Map<String, dynamic>> data = [
    {"title": "Tambah Barang", "description": "Menambah barang.", "icon": Icons.add_box, "color": Colors.blue},
    {"title": "Cek Barang", "description": "Cek barang menggunakan QR code.", "icon": Icons.qr_code_scanner, "color": Colors.green},
    {"title": "Cari Barang", "description": "Cari barang dalam daftar.", "icon": Icons.search, "color": Colors.orange},
    {"title": "Tambah Pengiriman", "description": "Tambah data pengiriman baru.", "icon": Icons.local_shipping, "color": Colors.purple},
    {"title": "Histori Pengiriman", "description": "Lihat riwayat pengiriman.", "icon": Icons.history, "color": Colors.teal},
    {"title": "Dokumentasi Nota", "description": "Catat nota pelanggan.", "icon": Icons.receipt, "color": Colors.pink},
    {"title": "Tambah Admin & Supir", "description": "Tambah admin dan supir.", "icon": Icons.person_add, "color": Colors.indigo},
    {"title": "Recap per Hari", "description": "rekapan per hari.", "icon": Icons.receipt, "color": Colors.indigo},

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Ekspedisi Sinar Jaya', style: TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.red[900]!, Colors.blueGrey[700]!],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: signout,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.email?.replaceAll("@gmail.com", " ")}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    DateFormat.yMMMMd('en_US').format(DateTime.now()),
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[600]),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildGridItem(context, data[index], index);
                },
                childCount: data.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, Map<String, dynamic> item, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToPage(context, index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [item['color'], item['color'].withOpacity(0.7)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'], size: 48, color: Colors.white),
              SizedBox(height: 8),
              Text(
                item['title'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item['description'],
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => AddBarangPage()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => CekBarangPage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => SearchBarangPage()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => PengirimanListPage()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPengirimanPage()));
        break;
      case 5:
        Navigator.push(context, MaterialPageRoute(builder: (context) => DokumentasiNotaPage()));
        break;
      case 6:
        Navigator.push(context, MaterialPageRoute(builder: (context) => AddAdminDaerahDanSupirPage()));
        break;
      case 7:
        Navigator.push(context, MaterialPageRoute(builder: (context) => RekapDataPage()));
        break;
    }
  }
}

void main() {
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: AdminPage(),
    theme: ThemeData(
      primarySwatch: Colors.blueGrey,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: Colors.grey[100],
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.blueGrey[800]),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey[700]!, width: 2),
        ),
      ),
    ),
  ));
}
