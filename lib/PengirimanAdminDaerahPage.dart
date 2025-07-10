import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class PengirimanListDaerahPage extends StatefulWidget {
  @override
  _PengirimanListDaerahPageState createState() => _PengirimanListDaerahPageState();
}

class _PengirimanListDaerahPageState extends State<PengirimanListDaerahPage> {
  String searchQuery = "";
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pengiriman'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildPengirimanList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari berdasarkan Plat atau Jurusan',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildPengirimanList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('pengiriman').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Belum ada data pengiriman.'));
        }

        var filteredDocs = _filterDocuments(snapshot.data!.docs);

        if (filteredDocs.isEmpty) {
          return Center(child: Text('Tidak ada data yang sesuai dengan pencarian.'));
        }

        return SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) => _buildPengirimanCard(filteredDocs[index]),
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterDocuments(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      var plat = doc['plat'].toString().toLowerCase();
      var jurusan = doc['jurusan'].toString().toLowerCase();
      return plat.contains(searchQuery) || jurusan.contains(searchQuery);
    }).toList();
  }

  Widget _buildPengirimanCard(QueryDocumentSnapshot doc) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plat: ${doc['plat']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            SizedBox(height: 8.0),
            _buildInfoRow('Jurusan', doc['jurusan']),
            _buildInfoRow('Jenis Kendaraan', doc['jenis_kendaraan']),
            _buildInfoRow('Total Biaya', _formatCurrency(doc['total_harga'])),
            _buildInfoRow('Tanggal', _formatDate(doc['tanggal'])),
            _buildInfoRow('Lokasi', '${doc['street']}, ${doc['subLocality']}, ${doc['locality']}, ${doc['postalCode']}'),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton('Detail', () => _navigateToDetail(doc.id)),
                SizedBox(width: 8.0),
                _buildActionButton('Selesai', () => _showConfirmationDialog(doc)),
                SizedBox(width: 8.0),
                _buildActionButton('Invoice', () => _printInvoice(doc)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: label == 'Selesai' ? Colors.green : null,
      ),
    );
  }

  void _navigateToDetail(String pengirimanId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarangKirimanPage(pengirimanId: pengirimanId),
      ),
    );
  }

  void _showConfirmationDialog(QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda yakin pengiriman ini telah selesai?'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Ya'),
              onPressed: () {
                Navigator.of(context).pop();
                _moveToHistory(doc);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _moveToHistory(QueryDocumentSnapshot doc) async {
    // Copy data from pengiriman to historyPengiriman
    final historyDocRef = FirebaseFirestore.instance.collection('historyPengiriman').doc(doc.id);
    await historyDocRef.set(doc.data() as Map<String, dynamic>);

    // Move barangKiriman sub-collection
    final barangKirimanSnapshot = await FirebaseFirestore.instance
        .collection('pengiriman')
        .doc(doc.id)
        .collection('barangKiriman')
        .get();

    for (var barangDoc in barangKirimanSnapshot.docs) {
      // Copy each document to the historyPengiriman collection
      await historyDocRef.collection('barangKiriman').doc(barangDoc.id).set(barangDoc.data());

      // Delete each document from the original pengiriman collection
      await FirebaseFirestore.instance
          .collection('pengiriman')
          .doc(doc.id)
          .collection('barangKiriman')
          .doc(barangDoc.id)
          .delete();

      // Delete the corresponding item from the "barang" collection
      final barangCollectionSnapshot = await FirebaseFirestore.instance
          .collection('barang')
          .where('JenisBarang', isEqualTo: barangDoc['JenisBarang'])
          .where('NamaPenerima', isEqualTo: barangDoc['NamaPenerima'])
          .get();

      for (var barangItem in barangCollectionSnapshot.docs) {
        await barangItem.reference.delete();
      }
    }

    // Delete the original document from pengiriman
    await FirebaseFirestore.instance.collection('pengiriman').doc(doc.id).delete();
  }




  Future<void> _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatCurrency(int value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(value)}';
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd-MM-yyyy').format(date);
  }
}

//done

class BarangKirimanPage extends StatelessWidget {
  final String pengirimanId;

  const BarangKirimanPage({Key? key, required this.pengirimanId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang Kiriman'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pengiriman')
            .doc(pengirimanId)
            .collection('barangKiriman')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data barang kiriman.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return BarangKirimanCard(doc: doc);
            },
          );
        },
      ),
    );
  }
}

class BarangKirimanCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const BarangKirimanCard({Key? key, required this.doc}) : super(key: key);

  String _cleanString(dynamic value) {
    if (value == null) return 'Tidak ada jenis';
    String stringValue = value.toString();
    return stringValue.replaceAll(RegExp(r'^\[|\]$'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    // Handle different data types for HargaBarang
    String formattedHarga = 'N/A';
    final hargaBarang = doc['HargaBarang'];
    if (hargaBarang != null) {
      if (hargaBarang is int || hargaBarang is double) {
        formattedHarga = currencyFormatter.format(hargaBarang);
      } else if (hargaBarang is String) {
        try {
          final parsedHarga = double.parse(hargaBarang);
          formattedHarga = currencyFormatter.format(parsedHarga);
        } catch (e) {
          formattedHarga = hargaBarang;
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cleanString(doc['JenisBarang']),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.inventory, 'Jumlah', _cleanString(doc['JumlahBarang'])),
            _buildInfoRow(Icons.attach_money, 'Harga', formattedHarga),
            _buildInfoRow(Icons.person, 'Penerima', _cleanString(doc['NamaPenerima'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

//done

class HistoryBarangKirimanPage extends StatelessWidget {
  final String historyPengirimanId;

  const HistoryBarangKirimanPage({Key? key, required this.historyPengirimanId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang Kiriman'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('historyPengiriman')
            .doc(historyPengirimanId)
            .collection('barangKiriman')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data barang kiriman.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return HistoryBarangKirimanCard(doc: doc);
            },
          );
        },
      ),
    );
  }
}

class HistoryBarangKirimanCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const HistoryBarangKirimanCard({Key? key, required this.doc}) : super(key: key);

  String _cleanString(dynamic value) {
    if (value == null) return 'N/A';
    String stringValue = value.toString();
    return stringValue.replaceAll(RegExp(r'^\[|\]$'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    // Handle different data types for HargaBarang
    String formattedHarga = 'N/A';
    final hargaBarang = doc['HargaBarang'];
    if (hargaBarang != null) {
      if (hargaBarang is int || hargaBarang is double) {
        formattedHarga = currencyFormatter.format(hargaBarang);
      } else if (hargaBarang is String) {
        try {
          final parsedHarga = double.parse(hargaBarang);
          formattedHarga = currencyFormatter.format(parsedHarga);
        } catch (e) {
          formattedHarga = hargaBarang;
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cleanString(doc['JenisBarang']),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.inventory, 'Jumlah', _cleanString(doc['JumlahBarang'])),
            _buildInfoRow(Icons.attach_money, 'Harga', formattedHarga),
            _buildInfoRow(Icons.person, 'Penerima', _cleanString(doc['NamaPenerima'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}



String _formatCurrency(int value) {
  final formatter = NumberFormat('#,##0', 'id_ID');
  return formatter.format(value);
}

void _printInvoice(QueryDocumentSnapshot doc) async {
  final pdf = pw.Document();
  final pw.MemoryImage logoImage = await _loadLogoImage();

  // Fetch barangKiriman data from Firestore
  final barangSnapshot = await FirebaseFirestore.instance
      .collection('pengiriman')
      .doc(doc.id)
      .collection('barangKiriman')
      .get();

  // Get QR code URL
  String qrCodeUrl = doc['qrCodeUrl'];

  // Download QR code image data
  pw.MemoryImage? qrCodeImage;
  if (qrCodeUrl != null && qrCodeUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(qrCodeUrl));
      if (response.statusCode == 200) {
        qrCodeImage = pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Failed to load QR code image: $e');
    }
  }

  // Helper function to clean string
  String cleanString(dynamic value) {
    if (value == null) return '';
    String str = value.toString();
    // Remove square brackets
    str = str.replaceAll(RegExp(r'^\[|\]$'), '');
    // Remove extra commas and whitespace
    str = str.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).join(', ');
    return str;
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section with Logo and Title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 100, height: 100),
                  if (qrCodeImage != null)
                    pw.Image(qrCodeImage, width: 80, height: 80),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'INVOICE PENGIRIMAN',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Invoice Details Section
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInvoiceRow('ID Pengiriman', doc.id),
                    _buildInvoiceRow('Nomor Plat', doc['plat']),
                    _buildInvoiceRow('Jurusan', doc['jurusan']),
                    _buildInvoiceRow('Jenis Kendaraan', doc['jenis_kendaraan']),
                    _buildInvoiceRow('Total Biaya', 'Rp ${_formatCurrency(doc['total_harga'])}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Barang Kiriman Section
              pw.Text(
                'DETAIL BARANG KIRIMAN',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Individual Item Cards
              ...barangSnapshot.docs.map((barangDoc) => pw.Container(
                margin: pw.EdgeInsets.only(bottom: 15),
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildItemRow('Nama Penerima', barangDoc['NamaPenerima'].toString()),
                              _buildItemRow('Jenis Barang', cleanString(barangDoc['JenisBarang'])),
                              _buildItemRow('Jumlah', barangDoc['JumlahBarang'].toString()),
                              _buildItemRow('Harga', 'Rp ${_formatCurrency(int.tryParse(barangDoc['HargaBarang'].toString()) ?? 0)}'),
                            ],
                          ),
                        ),
                        pw.Container(
                          width: 120,
                          height: 120,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 0.5),
                          ),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text('Tanda Tangan', style: pw.TextStyle(fontSize: 8)),
                              pw.Text('Penerima', style: pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )).toList(),

              pw.SizedBox(height: 30),

              // Signatures Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureBox('Tanda Tangan Admin'),
                  _buildSignatureBox('Tanda Tangan Supir'),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Terima kasih telah menggunakan layanan kami',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}

// Helper function to build invoice detail rows
pw.Widget _buildInvoiceRow(String label, String value) {
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      children: [
        pw.SizedBox(width: 120),
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(' : '),
        pw.Expanded(
          child: pw.Text(value),
        ),
      ],
    ),
  );
}

// Helper function to build item detail rows
pw.Widget _buildItemRow(String label, String value) {
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10),
          ),
        ),
        pw.Text(
          ' : ',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper function to build signature boxes
pw.Widget _buildSignatureBox(String title) {
  return pw.Container(
    width: 200,
    child: pw.Column(
      children: [
        pw.Container(
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(title, style: pw.TextStyle(fontSize: 10)),
      ],
    ),
  );
}




class HistoryPengirimanDaerahPage extends StatefulWidget {
  @override
  _HistoryPengirimanDaerahPageState createState() => _HistoryPengirimanDaerahPageState();
}

class _HistoryPengirimanDaerahPageState extends State<HistoryPengirimanDaerahPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Pengiriman'),
        backgroundColor: Colors.blueAccent, // AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search TextField
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Cari berdasarkan Plat atau Jurusan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  filled: true,
                  fillColor: Colors.grey[200], // Light background for the text field
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            // StreamBuilder for displaying the data
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('historyPengiriman').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Belum ada riwayat pengiriman.'));
                  }

                  // Filter data based on search query
                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    var plat = doc['plat'].toString().toLowerCase();
                    var jurusan = doc['jurusan'].toString().toLowerCase();
                    return plat.contains(searchQuery) || jurusan.contains(searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(child: Text('Tidak ada data yang sesuai dengan pencarian.'));
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      return Card(
                        elevation: 6.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ListTile to display the main information
                              ListTile(
                                title: Text(
                                  'Plat: ${doc['plat']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8.0),
                                    Text('Jurusan: ${doc['jurusan']}'),
                                    Text('Jenis Kendaraan: ${doc['jenis_kendaraan']}'),
                                    Text('Total Biaya Pengiriman: ${_formatCurrency(doc['total_harga'])}'),
                                    Text('Tanggal Pengiriman: ${_formatDate(doc['tanggal'])}'),
                                  ],
                                ),
                              ),
                              // Buttons for actions (Detail, Print Invoice, Delete)
                              // Buttons for actions (Detail, Print Invoice, Delete)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    child: _buildActionButton('Detail', () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HistoryBarangKirimanPage(historyPengirimanId: doc.id),
                                        ),
                                      );
                                    }),
                                  ),
                                  Flexible(
                                    child: _buildActionButton('Invoice', () {
                                      _printHistoryInvoice(doc);
                                    }),
                                  ),
                                  Flexible(
                                    child: _buildActionButton('Hapus', () async {
                                      bool confirmDelete = await _showDeleteConfirmationDialog();
                                      if (confirmDelete) {
                                        await _deleteHistory(doc);
                                      }
                                    }),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build action buttons
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data ini beserta seluruh koleksi di dalamnya?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Delete history document
  Future<void> _deleteHistory(DocumentSnapshot doc) async {
    var barangSnapshot = await FirebaseFirestore.instance
        .collection('historyPengiriman')
        .doc(doc.id)
        .collection('barangKiriman')
        .get();

    for (var barangDoc in barangSnapshot.docs) {
      await barangDoc.reference.delete();
    }

    // Delete the history document
    await doc.reference.delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil dihapus.')));
  }

  // Format currency
  String _formatCurrency(int value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(value);
  }

  // Format date
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd-MM-yyyy').format(date);
  }
}

Future<pw.MemoryImage> _loadLogoImage() async {
  final ByteData bytes = await rootBundle.load('assets/sj_logo_clean.png');
  return pw.MemoryImage(bytes.buffer.asUint8List());
}
void _printHistoryInvoice(QueryDocumentSnapshot doc) async {
  final pdf = pw.Document();
  final pw.MemoryImage logoImage = await _loadLogoImage();

  // Fetch barangKiriman data from Firestore
  final barangSnapshot = await FirebaseFirestore.instance
      .collection('historyPengiriman')
      .doc(doc.id)
      .collection('barangKiriman')
      .get();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Image(logoImage, width: 150, height: 150), // Sesuaikan ukuran sesuai kebutuhan
              ),
              pw.Text('Invoice Pengiriman', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Unique Id: ${doc.id}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Plat: ${doc['plat']}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Jurusan: ${doc['jurusan']}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Jenis Kendaraan: ${doc['jenis_kendaraan']}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Total Harga: ${_formatCurrency(doc['total_harga'])}', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 16),
              pw.Text('Barang Kiriman:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              for (var barangDoc in barangSnapshot.docs)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Nama Penerima: ${barangDoc['NamaPenerima']}', style: pw.TextStyle(fontSize: 16)),
                          pw.Text('Jumlah: ${barangDoc['JumlahBarang']}', style: pw.TextStyle(fontSize: 16)),
                          pw.Text('Harga: ${_formatCurrency(int.tryParse(barangDoc['HargaBarang'].toString()) ?? 0)}', style: pw.TextStyle(fontSize: 16)),
                          pw.Text('Jenis Barang: ${barangDoc['JenisBarang']}', style: pw.TextStyle(fontSize: 16)),
                          pw.SizedBox(height: 8),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Table(
                        border: pw.TableBorder.all(),
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text('Tanda Tangan Penerima:', style: pw.TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: pw.EdgeInsets.symmetric(vertical: 32, horizontal: 8),
                                child: pw.Text(''), // Space for signature
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              pw.SizedBox(height: 32),
              pw.Text('Terima kasih telah menggunakan layanan kami.', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 32),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Tanda Tangan Supir:', style: pw.TextStyle(fontSize: 16)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Tanda Tangan Admin:', style: pw.TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(vertical: 32, horizontal: 8),
                        child: pw.Text(''), // Space for signature
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(vertical: 32, horizontal: 8),
                        child: pw.Text(''), // Space for signature
                      ),
                    ],
                  ),
                ],
              ),
            ],
          )
        ];
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}

//done

class BarangListPage extends StatelessWidget {
  final String pengirimanId;

  BarangListPage({required this.pengirimanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List: $pengirimanId'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('historyPengiriman')
            .doc(pengirimanId)
            .collection('barangKiriman')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada data barang untuk pengiriman ini.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nama Penerima: ${doc['NamaPenerima']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text('Jumlah: ${doc['JumlahBarang']}'),
                      Text('Harga: ${_formatCurrency(int.tryParse(doc['HargaBarang'].toString()) ?? 0)}'),
                      Text('Jenis Barang: ${doc['JenisBarang']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatCurrency(int value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(value);
  }
}


class AddPengirimanPage extends StatefulWidget {
  @override
  _AddPengirimanState createState() => _AddPengirimanState();
}

class _AddPengirimanState extends State<AddPengirimanPage> {
  final TextEditingController platController = TextEditingController();
  final List<Map<String, dynamic>> barangList = [];
  String? jenisKendaraan;
  String? jurusan;
  final String pengirimanId = Uuid().v4();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Pengiriman'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: platController,
                decoration: const InputDecoration(
                  labelText: 'Plat Kendaraan',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                ),
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: jurusan,
                hint: Text('Pilih Jurusan'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                ),
                items: ['Siwa', 'Belopa', 'Sengkang', 'Bajo', 'Padang Sappa', 'Sidrap']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    jurusan = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: jenisKendaraan,
                hint: Text('Pilih Jenis Kendaraan'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                ),
                items: ['pribadi', 'third party'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    jenisKendaraan = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarangList(
                      onSelectBarang: _addBarang,
                      formatCurrency: _formatCurrency,
                    ),
                  ),
                ),
                child: Text('Tambah Barang'),
              ),
              SizedBox(height: 16.0),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: barangList.length,
                itemBuilder: (context, index) {
                  var barang = barangList[index];
                  return Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            '${barang['NamaPenerima']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8.0),
                              Text('Jumlah: ${barang['JumlahBarang']}'),
                              Text('Harga: ${_formatCurrency(int.tryParse(barang['HargaBarang'].toString()) ?? 0)}'),
                              Text('JenisBarang: ${barang['JenisBarang']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                barangList.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Total Harga Kotor: ${_formatCurrency(_calculateTotalHargaTanpaDiskon())}',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                jenisKendaraan == 'pribadi'
                    ? 'Ongkos Jalan Mobil: ${_formatCurrency((_calculateTotalHargaTanpaDiskon() * 0.2).toInt())}'
                    : jenisKendaraan == 'third party'
                    ? 'Biaya Pengisian: ${_formatCurrency((_calculateTotalHargaTanpaDiskon() * 0.3).toInt())}'
                    : '',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Total Harga Bersih: ${_formatCurrency(_calculateTotalHarga())}',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    _addPengiriman(context);
                    Navigator.pop(context); // To pop the current screen and go back to the previous page
                  },
                  child: Text('Tambah Pengiriman'),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addBarang(Map<String, dynamic> barang) {
    setState(() {
      barangList.add(barang);
    });
  }

  void _addPengiriman(BuildContext context) async {
    final String plat = platController.text;
    final String jurusanValue = jurusan ?? '';
    final int totalHarga = _calculateTotalHarga();
    final Timestamp tanggal = Timestamp.now();
    final String street = '-';
    final String locality = '-';
    final String subLocality = '-';
    final String postalCode = '-';

    if (plat.isEmpty || jurusanValue.isEmpty || jenisKendaraan == null || barangList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon lengkapi semua field dan tambahkan barang.')),
      );
      return;
    }

    // Generate QR code and save to Firebase Storage
    try {
      final qrCode = QrPainter(
        data: pengirimanId,
        version: QrVersions.auto,
        gapless: false,
      );

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      final file = File('$tempPath/$pengirimanId.png');

      final picData = await qrCode.toImageData(300);
      await file.writeAsBytes(picData!.buffer.asUint8List());

      // Upload the QR code image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('qrcodes/$pengirimanId.png');
      await storageRef.putFile(file);

      // Get the download URL of the QR code image
      String qrCodeUrl = await storageRef.getDownloadURL();

      // Save the pengiriman data, including the QR code URL
      await FirebaseFirestore.instance.collection('pengiriman').doc(pengirimanId).set({
        'plat': plat,
        'jurusan': jurusanValue,
        'jenis_kendaraan': jenisKendaraan,
        'total_harga': totalHarga,
        'tanggal': tanggal,
        'street': street,
        'locality': locality,
        'subLocality': subLocality,
        'postalCode': postalCode,
        'qrCodeUrl': qrCodeUrl,
      });

      final CollectionReference barangKirimanRef = FirebaseFirestore.instance
          .collection('pengiriman')
          .doc(pengirimanId)
          .collection('barangKiriman');

      for (var barang in barangList) {
        await barangKirimanRef.add(barang);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data pengiriman berhasil ditambahkan.')),
      );

      platController.clear();
      jurusan = null;
      jenisKendaraan = null;
      barangList.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pengiriman: $e')),
      );
    }
  }

  int _calculateTotalHarga() {
    int total = 0;
    for (var barang in barangList) {
      total += int.tryParse(barang['HargaBarang'].toString()) ?? 0;
    }

    if (jenisKendaraan == 'pribadi') {
      total = (total * 0.8).toInt();
    } else if (jenisKendaraan == 'third party') {
      total = (total * 0.3).toInt();
    }

    return total;
  }

  int _calculateTotalHargaTanpaDiskon() {
    int total = 0;
    for (var barang in barangList) {
      total += int.tryParse(barang['HargaBarang'].toString()) ?? 0;
    }
    return total;
  }

  String _formatCurrency(int value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(value);
  }
}

class BarangList extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelectBarang;
  final String Function(int) formatCurrency;

  BarangList({required this.onSelectBarang, required this.formatCurrency});

  @override
  _BarangListState createState() => _BarangListState();
}

class _BarangListState extends State<BarangList> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Barang'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan Nama Penerima',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('barang').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Belum ada data barang.'));
                }

                // Filter data based on search query
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var namaPenerima = doc['NamaPenerima'].toString().toLowerCase();
                  return namaPenerima.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text('Tidak ada data yang sesuai dengan pencarian.'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    return Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: InkWell(
                        onTap: () {
                          widget.onSelectBarang({
                            'JenisBarang': doc['JenisBarang'],
                            'JumlahBarang': doc['JumlahBarang'],
                            'HargaBarang': doc['HargaBarang'],
                            'NamaPenerima': doc['NamaPenerima'],
                          });
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Penerima: ${doc['NamaPenerima']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text('Jumlah: ${doc['JumlahBarang']}'),
                              Text('Harga: ${widget.formatCurrency(int.tryParse(doc['HargaBarang'].toString()) ?? 0)}'),
                              Text('Jenis Barang: ${doc['JenisBarang']}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
