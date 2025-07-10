import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CekBarangPage extends StatefulWidget {
  const CekBarangPage({Key? key}) : super(key: key);

  @override
  _CekBarangPageState createState() => _CekBarangPageState();
}

class _CekBarangPageState extends State<CekBarangPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isLoading = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (result == null || result!.code != scanData.code) {
        setState(() {
          result = scanData;
          isLoading = true;
        });

        if (result != null) {
          String qrText = result!.code!;
          List<String> parts = qrText.split('\n');
          if (parts.isNotEmpty && parts[0].startsWith('ID: ')) {
            String uniqueId = parts[0].replaceFirst('ID: ', '');
            await _processUniqueId(uniqueId);
          } else {
            _showErrorMessage("QR code format not recognized.");
          }
        }
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<void> _processUniqueId(String uniqueId) async {
    Map<String, dynamic>? firestoreData = await _fetchDataFromFirestore(uniqueId);
    if (firestoreData != null) {
      _showResultDialog(uniqueId, firestoreData);
    } else {
      _showErrorMessage("No data found for the given ID.");
    }
  }

  Future<Map<String, dynamic>?> _fetchDataFromFirestore(String uniqueId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('barang').doc(uniqueId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      _showErrorMessage("Error fetching data: $e");
    }
    return null;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showResultDialog(String uniqueId, Map<String, dynamic> firestoreData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Package Details", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildInfoRow("Unique ID", uniqueId),
                _buildInfoRow("Recipient", firestoreData['NamaPenerima']),
                _buildInfoRow("Recipient's Number", firestoreData['NomorPenerima']),
                _buildInfoRow("Sender", firestoreData['NamaPengirim']),
                _buildInfoRow("Sender's Number", firestoreData['NomorPengirim']),
                _buildInfoRow("Item Type", (firestoreData['JenisBarang'] as List<dynamic>?)?.join(', ')),
                _buildInfoRow("Quantity", firestoreData['JumlahBarang']?.toString()),
                _buildInfoRow("Price", firestoreData['HargaBarang']?.toString()),
                _buildInfoRow("Shipping Location", firestoreData['location']),
                _buildInfoRow("Status", firestoreData['status']),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    String? uniqueId;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Unique ID"),
          content: TextField(
            onChanged: (value) => uniqueId = value,
            decoration: InputDecoration(hintText: "Enter the unique ID"),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Submit"),
              onPressed: () {
                Navigator.of(context).pop();
                if (uniqueId != null && uniqueId!.isNotEmpty) {
                  _processUniqueId(uniqueId!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.input),
            onPressed: _showManualInputDialog,
            tooltip: 'Manual Input',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.green,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: 300,
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Align QR code within the frame',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: (result != null)
                      ? Text('Scanned Data: ${result!.code}')
                      : Text('Scan a QR code'),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

