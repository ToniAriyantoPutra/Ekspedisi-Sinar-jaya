import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dokumentasi Nota Pelanggan',
      home: DokumentasiNotaPage(),
    );
  }
}

class DokumentasiNotaPage extends StatefulWidget {
  @override
  _DokumentasiNotaPageState createState() => _DokumentasiNotaPageState();
}

class _DokumentasiNotaPageState extends State<DokumentasiNotaPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> _navigateToAddPage(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNotaPage()),
    );
  }

  Future<void> _deleteNota(BuildContext context, String notaId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus dokumentasi ini?'),
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
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection('dokumentasinota').doc(notaId).delete();
    }
  }

  Future<void> _editNota(BuildContext context, DocumentSnapshot doc) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditNotaPage(doc: doc)),
    );
  }

  Future<void> _viewDetail(BuildContext context, DocumentSnapshot doc) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailNotaPage(doc: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Nota Pelanggan'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan plat kendaraan atau tanggal kirim',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('dokumentasinota').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada data nota.'));
          }

          final filteredDocs = snapshot.data!.docs.where((doc) {
            String platKendaraan = (doc['plat_kendaraan'] ?? '').toString().toLowerCase();
            String tanggalKirim = (doc['timestamp'] != null)
                ? (doc['timestamp'] as Timestamp).toDate().toLocal().toString().toLowerCase()
                : '';
            return platKendaraan.contains(_searchQuery) || tanggalKirim.contains(_searchQuery);
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(child: Text('Tidak ada data yang cocok dengan pencarian Anda.'));
          }

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var doc = filteredDocs[index];
              var timestamp = doc['timestamp'] as Timestamp?;
              String formattedDate = timestamp != null ? timestamp.toDate().toLocal().toString() : 'Tanggal tidak tersedia';

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Plat Kendaraan: ${doc['plat_kendaraan']}'),
                  subtitle: Text('Jurusan: ${doc['jurusan'] ?? 'Tidak ada jurusan'}\nTanggal Pembuatan: $formattedDate'),
                  onTap: () => _viewDetail(context, doc),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editNota(context, doc),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNota(context, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPage(context),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddNotaPage extends StatefulWidget {
  @override
  _AddNotaPageState createState() => _AddNotaPageState();
}

class _AddNotaPageState extends State<AddNotaPage> {
  final TextEditingController _platKendaraanController = TextEditingController();
  List<File> _images = [];
  final picker = ImagePicker();

  String? _selectedLocation;
  final List<String> _locations = [
    'Siwa', 'Sengkang', 'Sidrap', 'Belopa', 'Bajo', 'Padang Sappa'
  ];

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _images.add(File(pickedFile.path));
      }
    });
  }

  Future<void> _uploadData() async {
    if (_platKendaraanController.text.isEmpty || _selectedLocation == null ||
        _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi semua data sebelum mengunggah')),
      );
      return;
    }

    try {
      String uniqueId = FirebaseFirestore.instance
          .collection('dokumentasinota')
          .doc()
          .id;
      await FirebaseFirestore.instance.collection('dokumentasinota').doc(
          uniqueId).set({
        'plat_kendaraan': _platKendaraanController.text,
        'jurusan': _selectedLocation,
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (var image in _images) {
        String fileName = '${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg';
        Reference storageReference = FirebaseStorage.instance.ref().child(
            'nota_images/$uniqueId/$fileName');
        UploadTask uploadTask = storageReference.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('dokumentasinota')
            .doc(uniqueId)
            .collection('pengiriman')
            .add({'foto_url': downloadUrl});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nota berhasil diunggah')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah nota: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Dokumentasi Nota'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered Text Field for Plat Kendaraan
              TextField(
                controller: _platKendaraanController,
                decoration: InputDecoration(
                  labelText: 'Plat Kendaraan',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Centered Dropdown (List Box)
              DropdownButton<String>(
                value: _selectedLocation,
                hint: Text('Pilih Jurusan'),
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue!;
                  });
                },
                items: _locations.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Center(child: Text(value)),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              // Image Section
              _images.isEmpty
                  ? Center(
                child: Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.grey,
                ),
              )
                  : Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _images
                    .map((image) =>
                    Image.file(image, height: 100, fit: BoxFit.cover))
                    .toList(),
              ),
              SizedBox(height: 20),

              // Centered Buttons
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _getImage,
                      child: Text('Tambahkan Foto'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _uploadData,
                      child: Text('Selesai'),
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

  class DetailNotaPage extends StatelessWidget {
  final DocumentSnapshot doc;

  DetailNotaPage({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Detail Nota Pengiriman',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plat Kendaraan: ${doc['plat_kendaraan']}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Jurusan: ${doc['jurusan'] ?? 'Tidak ada jurusan'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Unique ID: ${doc.id}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            StreamBuilder(
              stream: doc.reference.collection('pengiriman').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> fotoSnapshot) {
                if (fotoSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!fotoSnapshot.hasData || fotoSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Belum ada foto pengiriman.'));
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: fotoSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var fotoDoc = fotoSnapshot.data!.docs[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImage(imageUrl: fotoDoc['foto_url']),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8.0,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.network(
                              fotoDoc['foto_url'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gambar Pengiriman'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}


class EditNotaPage extends StatefulWidget {
  final DocumentSnapshot doc;

  EditNotaPage({required this.doc});

  @override
  _EditNotaPageState createState() => _EditNotaPageState();
}

class _EditNotaPageState extends State<EditNotaPage> {
  late TextEditingController _platKendaraanController;
  late TextEditingController _jurusanController;
  List<File> _newImages = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _platKendaraanController = TextEditingController(text: widget.doc['plat_kendaraan']);
    _jurusanController = TextEditingController(text: widget.doc['jurusan']);
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _newImages.add(File(pickedFile.path));
      }
    });
  }

  Future<void> _updateNota() async {
    try {
      await FirebaseFirestore.instance.collection('dokumentasinota').doc(widget.doc.id).update({
        'jurusan': _jurusanController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (var image in _newImages) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageReference = FirebaseStorage.instance.ref().child('nota_images/${widget.doc.id}/$fileName');
        UploadTask uploadTask = storageReference.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('dokumentasinota')
            .doc(widget.doc.id)
            .collection('pengiriman')
            .add({'foto_url': downloadUrl});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nota berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui nota: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Dokumentasi Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _platKendaraanController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Plat Kendaraan'),
            ),
            TextField(
              controller: _jurusanController,
              decoration: InputDecoration(labelText: 'Jurusan'),
            ),
            SizedBox(height: 20),
            _newImages.isEmpty
                ? Text('Tidak ada foto baru yang ditambahkan')
                : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _newImages.map((image) => Image.file(image, height: 100, fit: BoxFit.cover)).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getImage,
              child: Text('Tambahkan Foto Baru'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateNota,
              child: Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}
