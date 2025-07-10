import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarangCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function onTap;
  final Function onEdit;
  final Function onDelete;

  const BarangCard({
    Key? key,
    required this.doc,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc['NamaPenerima'] ?? 'N/A',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(doc['status'] ?? 'N/A'),
                ],
              ),
              SizedBox(height: 8),
              Text('Lokasi: ${doc['location'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Jenis Barang: ${(doc['JenisBarang'] as List<dynamic>?)?.join(', ') ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Jumlah Barang: ${doc['JumlahBarang'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Nama Pengirim: ${doc['NamaPengirim'] ?? 'N/A'}'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => onEdit(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDelete(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Sedang Dikirim':
        chipColor = Colors.green;
        break;
      case 'Belum Dikirim':
        chipColor = Colors.orange;
        break;
      case 'pending':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
    );
  }
}

