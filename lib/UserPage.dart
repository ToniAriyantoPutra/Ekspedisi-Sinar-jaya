import 'package:app_projekskripsi/CekBarangUserPage.dart';
import 'package:app_projekskripsi/ForgotPassword.dart';
import 'package:app_projekskripsi/SearchBarangUserPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_projekskripsi/login.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
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
      "title": "Cek QR Barang",
      "description": "Pengecekan QR Barang",
      "icon": Icons.qr_code_scanner,
      "color": Colors.blue,
      "route": CekBarangUserPage(),
    },
    {
      "title": "Cek Barang Kiriman",
      "description": "Cek Pengiriman Anda",
      "icon": Icons.local_shipping,
      "color": Colors.green,
      "route": SearchBarangUserPage(),
    },
    {
      "title": "Reset Password",
      "description": "Mengubah Password anda",
      "icon": Icons.password,
      "color": Colors.orange,
      "route": ForgotPassword(),
    },
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
              title: Text('Dashboard Pengguna',style: TextStyle(color: Colors.black)) ,
              background: Image.network(
                'https://sinarjaya-exp.com/assets/img/dakwa-about.png',
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.black),
                onPressed: () => _showLogoutDialog(),
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
                    'Selamat datang',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${user?.email?.replaceAll("@gmail.com", " ")}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Layanan Kami',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: AnimationLimiter(
              child: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _buildCard(data[index]),
                        ),
                      ),
                    );
                  },
                  childCount: data.length,
                ),
              ),
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
          if (item['route'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['route']),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fitur ini akan segera hadir!')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'], size: 48, color: item['color']),
              SizedBox(height: 8),
              Text(
                item['title'],
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                item['description'],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                signout();
              },
            ),
          ],
        );
      },
    );
  }
}

