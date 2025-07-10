import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SearchBarangUserPage extends StatefulWidget {
  const SearchBarangUserPage({Key? key}) : super(key: key);

  @override
  _SearchBarangUserPageState createState() => _SearchBarangUserPageState();
}

class _SearchBarangUserPageState extends State<SearchBarangUserPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isAscending = true;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchBarang);
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchBarang);
    _searchController.dispose();
    super.dispose();
  }


  void _searchBarang() async {
    String searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isEmpty) {
      setState(() {
        _searchResults = [];
      });
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
        Timestamp timeA = a['createdAt'] ?? Timestamp(0, 0);
        Timestamp timeB = b['createdAt'] ?? Timestamp(0, 0);
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
  }

  void _onCardTap(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarangDetailPage(doc: doc),
      ),
    );
  }

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
              title: Text('Search Barang'),
              background: Image.network(
                'https://sinarjaya-exp.com/assets/img/dakwa-about.png',
                fit: BoxFit.cover,
              ),
            ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Nama Penerima atau Tujuan',
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('barang').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(child: Text('No data available')),
                );
              }

              List<DocumentSnapshot> allData = snapshot.data!.docs;
              List<DocumentSnapshot> displayedData =
              _searchResults.isEmpty ? allData : _searchResults;

              displayedData.sort((a, b) {
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

              return SliverAnimatedList(
                initialItemCount: displayedData.length,
                itemBuilder: (context, index, animation) {
                  DocumentSnapshot doc = displayedData[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () => _onCardTap(doc),
                          child: Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  doc['NamaPenerima']?[0] ?? 'N',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                doc['NamaPenerima'] ?? 'N/A',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text('Jenis: ${doc['JenisBarang'] ?? 'N/A'}'),
                                  Text('Lokasi: ${doc['location'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: _buildStatusIcon(doc['status'] ?? 'N/A'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'Sedang Dikirim':
        icon = Icons.local_shipping;
        color = Colors.blue;
        break;
      case 'Belum Dikirim':
        icon = Icons.pending;
        color = Colors.orange;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color),
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
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(context),
              SizedBox(height: 20),
              _buildQRCode(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Penerima: ${doc['NamaPenerima'] ?? 'N/A'}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            SizedBox(height: 10),
            _buildInfoRow(Icons.phone, 'Nomor Penerima: ${doc['NomorPenerima'] ?? 'N/A'}'),
            _buildInfoRow(Icons.category, 'Jenis Barang: ${doc['JenisBarang'] ?? 'N/A'}'),
            _buildInfoRow(Icons.format_list_numbered, 'Jumlah Barang: ${doc['JumlahBarang'] ?? 'N/A'}'),
            _buildInfoRow(Icons.location_on, 'Lokasi Pengiriman: ${doc['location'] ?? 'N/A'}'),
            _buildStatusRow(doc['status'] ?? 'N/A'),
            _buildInfoRow(Icons.attach_money, 'Harga Barang: ${doc['HargaBarang'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status) {
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case 'Sedang Dikirim':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'Belum Dikirim':
        statusIcon = Icons.local_shipping;
        statusColor = Colors.orange;
        break;
      default:
        statusIcon = Icons.info;
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          SizedBox(width: 10),
          Text(
            'Status: $status',
            style: TextStyle(fontSize: 16, color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    if (doc['qr_image_url'] != null && doc['qr_image_url'].isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QR Code:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          SizedBox(height: 10),
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
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
                    return Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }
}




