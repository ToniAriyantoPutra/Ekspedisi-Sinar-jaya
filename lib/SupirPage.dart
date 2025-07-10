import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_projekskripsi/Login.dart';
import 'package:app_projekskripsi/GeolocatorPengirimanPage.dart';
import 'package:app_projekskripsi/SOSDriverPage.dart';
import 'package:app_projekskripsi/SosSupirPage.dart';

class SupirPage extends StatefulWidget {
  const SupirPage({Key? key}) : super(key: key);

  @override
  State<SupirPage> createState() => _SupirPageState();
}

class _SupirPageState extends State<SupirPage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
    );
  }

  final List<Map<String, dynamic>> data = [
    {
      "title": "Pengiriman",
      "description": "Cek Pengiriman",
      "icon": Icons.local_shipping,
      "color": Colors.blue,
      "route": PengirimanListPage(),
    },
    {
      "title": "SOS Button",
      "description": "Tekan jika dalam keadaan darurat",
      "icon": Icons.warning,
      "color": Colors.red,
      "route": NotificationScreen(),
      //"route": SOSDriverPage(),

    },
    /*{
      "title": "Notifikasi",
      "description": "Lihat notifikasi terbaru",
      "icon": Icons.notifications,
      "color": Colors.orange,
      "route": NotificationScreen(),
    },

     */
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard Supir"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: signout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Selamat datang, ${user?.email?.replaceAll("@gmail.com", " ")}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return _buildCard(data[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => item['route']));
        },
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(item['icon'], size: 64, color: item['color']),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      item['description'],
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SupirPage(),
    theme: ThemeData(
      primarySwatch: Colors.green,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 16),
      ),
    ),
  ));
}

