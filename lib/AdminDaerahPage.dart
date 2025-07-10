import 'package:app_projekskripsi/CekBarangAdminDaerahPage.dart';
import 'package:app_projekskripsi/PengirimanAdminDaerahPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_projekskripsi/login.dart';

class AdminDaerahPage extends StatefulWidget {
  const AdminDaerahPage({Key? key}) : super(key: key);

  @override
  State<AdminDaerahPage> createState() => _AdminDaerahPageState();
}

class _AdminDaerahPageState extends State<AdminDaerahPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;

  Future<void> signout() async {
    setState(() {
      isLoading = true;
    });
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
    );
  }

  final List<Map<String, dynamic>> data = [
    {
      "title": "Pengiriman",
      "description": "Cek pengiriman dan Acc Pengiriman Selesai",
      "icon": Icons.local_shipping,
      "color": Colors.blue,
    },
    {
      "title": "History Pengiriman",
      "description": "Pengecekan data lalu pengiriman",
      "icon": Icons.history,
      "color": Colors.green,
    },
    {
      "title": "Cek Barang",
      "description": "pengecekan barang menggunakan QR code",
      "icon": Icons.qr_code,
      "color": Colors.orange,
    },

    //fitur pengaturan
    /*{
      "title": "Pengaturan",
      "description": "Atur preferensi aplikasi",
      "icon": Icons.settings,
      "color": Colors.purple,
    },

     */
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade800, Colors.blue.shade400],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${user?.email?.replaceAll("@gmail.com", " ")}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: Icon(Icons.logout, color: Colors.blue),
                          onPressed: isLoading ? null : signout,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return _buildCard(data[index]);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    // Ensure color is never null by providing a default value
    Color cardColor = item['color'] ?? Colors.grey; // fallback to grey if null

    return Hero(
      tag: item['title'],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleCardTap(item),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1), // safely apply opacity
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardColor.withOpacity(0.5), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], size: 48, color: cardColor),
                  SizedBox(height: 16),
                  Text(
                    item['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cardColor),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    item['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _handleCardTap(Map<String, dynamic> item) {
    switch (item['title']) {
      case 'Pengiriman':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PengirimanListDaerahPage()),
        );
        break;
      case 'History Pengiriman':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => HistoryPengirimanDaerahPage()),
        );
        break;

      case 'Cek Barang':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CekBarangAdminDaerahPage()),
        );
        break;
      default:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item['title']),
            content: Text("Anda memilih ${item['title']}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
    }
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Daerah App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      home: AdminDaerahPage(),
    );
  }
}

