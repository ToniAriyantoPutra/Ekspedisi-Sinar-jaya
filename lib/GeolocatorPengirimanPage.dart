import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    title: 'Delivery Tracker',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: PengirimanListPage(),
  ));
}

class PengirimanListPage extends StatefulWidget {
  @override
  _PengirimanListPageState createState() => _PengirimanListPageState();
}

class _PengirimanListPageState extends State<PengirimanListPage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Theme.of(context).primaryColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan Plat atau Jurusan',
                prefixIcon: Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = "";
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('pengiriman').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Belum ada data pengiriman.'));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var plat = doc['plat'].toString().toLowerCase();
                  var jurusan = doc['jurusan'].toString().toLowerCase();
                  return plat.contains(searchQuery) || jurusan.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text('Tidak ada data yang sesuai dengan pencarian.'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    return _buildPengirimanCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPengirimanCard(QueryDocumentSnapshot doc) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ExpansionTile(
        title: Text(
          'Plat: ${doc['plat']}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        subtitle: Text('Jurusan: ${doc['jurusan']}'),
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Jenis Kendaraan', doc['jenis_kendaraan']),
                _buildInfoRow('Total Biaya', _formatCurrency(doc['total_harga'])),
                _buildInfoRow('Tanggal Pengiriman', _formatDate(doc['tanggal'])),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.info_outline),
                      label: Text('Detail'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarangKirimanPage(pengirimanId: doc.id),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.update),
                      label: Text('Update'),
                      onPressed: () async {
                        await _updateLocation(doc);
                        await _updateBarangStatus(doc);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _updateLocation(QueryDocumentSnapshot doc) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];

      await FirebaseFirestore.instance.collection('pengiriman').doc(doc.id).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'street': place.street,
        'subLocality': place.subLocality,
        'locality': place.locality,
        'postalCode': place.postalCode,
        'country': place.country,
        'lastUpdated': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi pengiriman berhasil diperbarui.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui lokasi: $e')),
      );
    }
  }

  Future<void> _updateBarangStatus(QueryDocumentSnapshot doc) async {
    try {
      final historyDocRef = FirebaseFirestore.instance.collection('historyPengiriman').doc(doc.id);
      await historyDocRef.set(doc.data() as Map<String, dynamic>);

      final barangKirimanSnapshot = await FirebaseFirestore.instance
          .collection('pengiriman')
          .doc(doc.id)
          .collection('barangKiriman')
          .get();

      for (var barangDoc in barangKirimanSnapshot.docs) {
        final barangCollectionSnapshot = await FirebaseFirestore.instance
            .collection('barang')
            .where('JenisBarang', isEqualTo: barangDoc['JenisBarang'])
            .where('NamaPenerima', isEqualTo: barangDoc['NamaPenerima'])
            .get();

        for (var barangItem in barangCollectionSnapshot.docs) {
          await barangItem.reference.update({
            'status': 'Sedang Dikirim',
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status barang berhasil diperbarui menjadi "Sedang Dikirim".')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status barang: $e')),
      );
    }
  }

  String _formatCurrency(int value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(value);
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd-MM-yyyy').format(date);
  }
}

class BarangKirimanPage extends StatelessWidget {
  final String pengirimanId;

  BarangKirimanPage({required this.pengirimanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Barang Kiriman'),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('pengiriman')
            .doc(pengirimanId)
            .collection('barangKiriman')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada data barang kiriman.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return _buildBarangKirimanCard(doc);
            },
          );
        },
      ),
    );
  }

  Widget _buildBarangKirimanCard(QueryDocumentSnapshot doc) {
    // Parse HargaBarang to double, defaulting to 0 if parsing fails
    double hargaBarang = double.tryParse(doc['HargaBarang'].toString()) ?? 0;

    String _cleanString(dynamic value) {
      if (value == null) return 'Tidak ada jenis';
      String stringValue = value.toString();
      return stringValue.replaceAll(RegExp(r'^\[|\]$'), '').trim();
    }
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cleanString(doc['JenisBarang']),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            _buildInfoRow('Jumlah Barang', doc['JumlahBarang'].toString()),
            _buildInfoRow('Harga Barang', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(hargaBarang)),
            _buildInfoRow('Nama Penerima', doc['NamaPenerima']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}