import 'package:app_projekskripsi/theme/app_theme.dart';
import 'package:app_projekskripsi/widgets/animated_search_bar.dart';
import 'package:app_projekskripsi/widgets/barang_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchBarangPage extends StatefulWidget {
  const SearchBarangPage({Key? key}) : super(key: key);

  @override
  _SearchBarangPageState createState() => _SearchBarangPageState();
}

class _SearchBarangPageState extends State<SearchBarangPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = true;
  bool _isAscending = true;
  String _sortBy = 'time';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchBarang);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Tambahkan baris ini untuk langsung mengurutkan berdasarkan waktu
    _toggleSortOrder('time');

    // Fetch all data immediately when page loads
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchBarang);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('barang')
          .get();

      setState(() {
        _searchResults = querySnapshot.docs;
        _sortResults();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching initial data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchBarang() async {
    String searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isEmpty) {
      await _fetchInitialData();
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('barang')
          .get();

      List<DocumentSnapshot> matchingDocs = querySnapshot.docs.where((doc) {
        String namaPenerima = (doc['NamaPenerima'] ?? '').toString().toLowerCase();
        String location = (doc['location'] ?? '').toString().toLowerCase();
        return namaPenerima.contains(searchText) || location.contains(searchText);
      }).toList();

      setState(() {
        _searchResults = matchingDocs;
        _sortResults();
      });
    } catch (e) {
      print("Error searching barang: $e");
    }
  }

  void _sortResults() {
    _searchResults.sort((a, b) {
      if (_sortBy == 'name') {
        String nameA = (a['NamaPenerima'] ?? '').toString().toLowerCase();
        String nameB = (b['NamaPenerima'] ?? '').toString().toLowerCase();
        return _isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
      } else if (_sortBy == 'time') {
        Timestamp timeA = a['created_at'] ?? Timestamp(0, 0);
        Timestamp timeB = b['created_at'] ?? Timestamp(0, 0);
        return _isAscending ? timeA.compareTo(timeB) : timeB.compareTo(timeA);
      }
      return 0;
    });
  }

  void _toggleSortOrder(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _isAscending = !_isAscending;
      } else {
        _sortBy = sortBy;
        _isAscending = true;
      }
      _sortResults();
    });
    _animationController.forward(from: 0);
  }

  void _onCardTap(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarangDetailPage(doc: doc),
      ),
    );
  }

  void _deleteBarang(DocumentSnapshot doc) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('barang').doc(doc.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Barang deleted successfully')));
        await _fetchInitialData(); // Refresh data after deletion
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete barang: $e')));
      }
    }
  }

  void _editBarang(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBarangPage(doc: doc),
      ),
    ).then((_) => _fetchInitialData()); // Refresh data after editing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Barang'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _toggleSortOrder(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name ${_isAscending && _sortBy == 'name' ? '(A-Z)' : '(Z-A)'}'),
              ),
              PopupMenuItem(
                value: 'time',
                child: Text('Sort by Time ${_isAscending && _sortBy == 'time' ? '(Newest First)' : '(Oldest First)'}'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: AnimatedSearchBar(
              controller: _searchController,
              onChanged: (value) => _searchBarang(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(child: Text('No data available'))
                : AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = _searchResults[index];
                    return FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                            begin: Offset(0, 0.05),
                            end: Offset.zero
                        ).animate(_animation),
                        child: BarangCard(
                          doc: doc,
                          onTap: () => _onCardTap(doc),
                          onEdit: () => _editBarang(doc),
                          onDelete: () => _deleteBarang(doc),
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




class EditBarangPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditBarangPage({required this.doc, Key? key}) : super(key: key);

  @override
  _EditBarangPageState createState() => _EditBarangPageState();
}

class _EditBarangPageState extends State<EditBarangPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _nomorPenerimaController = TextEditingController();
  final TextEditingController _namaPengirimController = TextEditingController();
  final TextEditingController _nomorPengirimController = TextEditingController();
  List<TextEditingController> _jenisBarangControllers = [];
  final TextEditingController _jumlahBarangController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _hargaBarangController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _namaPenerimaController.text = widget.doc['NamaPenerima'] ?? '';
    _nomorPenerimaController.text = widget.doc['NomorPenerima'] ?? '';
    _namaPengirimController.text = widget.doc['NamaPengirim'] ?? '';
    _nomorPengirimController.text = widget.doc['NomorPengirim'] ?? '';
    _jumlahBarangController.text = widget.doc['JumlahBarang'] ?? '';
    _locationController.text = widget.doc['location'] ?? '';
    _statusController.text = widget.doc['status'] ?? '';
    _hargaBarangController.text = widget.doc['HargaBarang'] ?? '';

    List jenisBarang = widget.doc['JenisBarang'] ?? [];
    _jenisBarangControllers = jenisBarang.map((jenis) => TextEditingController(text: jenis)).toList();
  }

  void _addJenisBarangField() {
    setState(() {
      _jenisBarangControllers.add(TextEditingController());
    });
  }

  void _removeJenisBarangField(int index) {
    setState(() {
      _jenisBarangControllers.removeAt(index);
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('barang').doc(widget.doc.id).update({
          'NamaPenerima': _namaPenerimaController.text,
          'NomorPenerima': _nomorPenerimaController.text,
          'NamaPengirim': _namaPengirimController.text,
          'NomorPengirim': _nomorPengirimController.text,
          'JenisBarang': _jenisBarangControllers.map((controller) => controller.text).toList(),
          'JumlahBarang': _jumlahBarangController.text,
          'location': _locationController.text,
          'status': _statusController.text,
          'HargaBarang': _hargaBarangController.text,
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Changes saved successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Barang'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildSection('Informasi Penerima', [
              _buildTextFormField(_namaPenerimaController, 'Nama Penerima'),
              _buildTextFormField(_nomorPenerimaController, 'Nomor Penerima'),
            ]),
            _buildSection('Informasi Pengirim', [
              _buildTextFormField(_namaPengirimController, 'Nama Pengirim'),
              _buildTextFormField(_nomorPengirimController, 'Nomor Pengirim'),
            ]),
            _buildSection('Informasi Barang', [
              ..._jenisBarangControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                var controller = entry.value;
                return Row(
                  children: [
                    Expanded(child: _buildTextFormField(controller, 'Jenis Barang ${idx + 1}')),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeJenisBarangField(idx),
                      color: Colors.red,
                    ),
                  ],
                );
              }).toList(),
              ElevatedButton.icon(
                onPressed: _addJenisBarangField,
                icon: Icon(Icons.add),
                label: Text('Tambah Jenis Barang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
              _buildTextFormField(_jumlahBarangController, 'Jumlah Barang'),
              _buildTextFormField(_hargaBarangController, 'Harga Barang'),
            ]),
            _buildSection('Informasi Pengiriman', [
              _buildTextFormField(_locationController, 'Lokasi Pengiriman'),
              _buildTextFormField(_statusController, 'Status'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        ...children,
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}

class BarangDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;

  const BarangDetailPage({required this.doc, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Barang'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Center(
                child: Text(
                  doc['NamaPenerima'] ?? 'N/A',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Informasi Penerima', [
                    _buildInfoRow('Nama', doc['NamaPenerima']),
                    _buildInfoRow('Nomor', doc['NomorPenerima']),
                  ]),
                  _buildInfoSection('Informasi Pengirim', [
                    _buildInfoRow('Nama', doc['NamaPengirim']),
                    _buildInfoRow('Nomor', doc['NomorPengirim']),
                  ]),
                  _buildInfoSection('Informasi Barang', [
                    _buildInfoRow('Jenis', (doc['JenisBarang'] as List<dynamic>?)?.join(', ')),
                    _buildInfoRow('Jumlah', doc['JumlahBarang']),
                    _buildInfoRow('Harga', doc['HargaBarang']),
                  ]),
                  _buildInfoSection('Informasi Pengiriman', [
                    _buildInfoRow('Lokasi', doc['location']),
                    _buildInfoRow('Status', doc['status']),
                  ]),
                ],
              ),
            ),
            if (doc['qr_image_url'] != null && doc['qr_image_url'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            doc['qr_image_url'],
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                              return Text('Failed to load QR image');
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        ...children,
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}