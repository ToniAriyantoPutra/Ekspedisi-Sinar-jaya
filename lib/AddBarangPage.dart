import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class AddBarangPage extends StatefulWidget {
  const AddBarangPage({Key? key}) : super(key: key);

  @override
  _AddBarangPageState createState() => _AddBarangPageState();
}

class _AddBarangPageState extends State<AddBarangPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controllerNamaPengirim = TextEditingController();
  final TextEditingController _controllerNomorPengirim = TextEditingController();
  final TextEditingController _controllerNamaPenerima = TextEditingController();
  final TextEditingController _controllerNomorPenerima = TextEditingController();
  final TextEditingController _controllerJumlahBarang = TextEditingController();
  final TextEditingController _controllerHargaBarang = TextEditingController();
  String _selectedLocation = 'Siwa';

  String _qrData = '';
  String _uniqueId = '';
  List<Map<String, dynamic>> _qrCodeData = [];
  List<TextEditingController> _jenisBarangControllers = [TextEditingController()];

  void _generateQR() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _uniqueId = const Uuid().v4();
        String jenisBarangData = _jenisBarangControllers.map((controller) => controller.text).join(', ');
        _qrData = 'ID: $_uniqueId\nData: ${_controllerNamaPenerima.text} ${_controllerNomorPenerima.text} ${_controllerNamaPengirim.text} ${_controllerNomorPengirim.text} $jenisBarangData ${_controllerJumlahBarang.text} ${_controllerHargaBarang.text} $_selectedLocation';
      });
    }
  }

  Future<void> _saveToFirebase(Uint8List qrImage) async {
    try {
      final startTime = DateTime.now(); // Waktu mulai

      DocumentReference docRef = FirebaseFirestore.instance.collection('barang').doc(_uniqueId);
      await docRef.set({
        'NamaPenerima': _controllerNamaPenerima.text,
        'NomorPenerima': _controllerNomorPenerima.text,
        'NamaPengirim': _controllerNamaPengirim.text,
        'NomorPengirim': _controllerNomorPengirim.text,
        'JenisBarang': _jenisBarangControllers.map((controller) => controller.text).toList(),
        'JumlahBarang': _controllerJumlahBarang.text,
        'HargaBarang': _controllerHargaBarang.text,
        'location': _selectedLocation,
        'status': 'Belum Dikirim',
        'created_at': FieldValue.serverTimestamp(),
        'unique_id': _uniqueId,
      });

      String qrImageName = '$_uniqueId.png';
      Reference ref = FirebaseStorage.instance.ref().child('qrcodes').child(qrImageName);
      UploadTask uploadTask = ref.putData(qrImage);
      TaskSnapshot taskSnapshot = await uploadTask;

      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      await docRef.update({'qr_image_url': imageUrl});

      final endTime = DateTime.now(); // Waktu selesai
      final duration = endTime.difference(startTime); // Hitung durasi
      print('Data Dokumentasi Nota saved successfully in ${duration.inSeconds} sec');
      print('Data Dokumentasi Nota saved successfully in ${duration.inMilliseconds} ms');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data and QR code saved successfully in ${duration.inMilliseconds} ms')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }


  Future<void> _printQRCodes() async {
    if (_qrCodeData.isNotEmpty) {
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            final doc = pw.Document();

            for (var qrData in _qrCodeData) {
              final qrImage = qrData['image'] as Uint8List;
              final image = pw.MemoryImage(qrImage);
              doc.addPage(
                pw.Page(
                  pageFormat: format,
                  build: (pw.Context context) {
                    return pw.Center(
                      child: pw.Image(image),
                    );
                  },
                ),
              );
            }

            return doc.save();
          },
        );

        setState(() {
          _qrCodeData.clear();
          _qrData = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR codes printed successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing QR codes: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR codes to print')),
      );
    }
  }

  Future<void> _addCurrentQRCode() async {
    if (_qrData.isNotEmpty) {
      final qrValidationResult = QrValidator.validate(
        data: _qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode;
        final painter = QrPainter.withQr(
          qr: qrCode!,
          color: const Color(0xFF000000),
          gapless: true,
          embeddedImageStyle: null,
          embeddedImage: null,
        );
        final picData = await painter.toImageData(200.0, format: ImageByteFormat.png);
        if (picData != null) {
          final qrImage = picData.buffer.asUint8List();

          await _saveToFirebase(qrImage);

          setState(() {
            _qrCodeData.add({
              'id': _uniqueId,
              'data': _qrData,
              'image': qrImage,
            });
            _clearForm();
          });
        }
      }
    }
  }

  void _addJenisBarangField() {
    setState(() {
      _jenisBarangControllers.add(TextEditingController());
    });
  }

  void _clearForm() {
    _controllerNamaPengirim.clear();
    _controllerNomorPengirim.clear();
    _controllerNamaPenerima.clear();
    _controllerNomorPenerima.clear();
    _controllerJumlahBarang.clear();
    _controllerHargaBarang.clear();
    for (var controller in _jenisBarangControllers) {
      controller.clear();
    }
    _qrData = '';
    setState(() {
      _jenisBarangControllers = [TextEditingController()];
      _selectedLocation = 'Siwa';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Transaksi"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTextField(_controllerNamaPengirim, "Nama Pengirim", Icons.person),
                _buildTextField(_controllerNomorPengirim, "Nomor Pengirim", Icons.phone, TextInputType.phone),
                _buildTextField(_controllerNamaPenerima, "Nama Penerima", Icons.person),
                _buildTextField(_controllerNomorPenerima, "Nomor Penerima", Icons.phone, TextInputType.phone),
                const SizedBox(height: 16),
                Text("Jenis Barang", style: Theme.of(context).textTheme.titleMedium),
                ..._jenisBarangControllers.map((controller) => _buildTextField(controller, "Jenis Barang", Icons.category)),
                ElevatedButton.icon(
                  onPressed: _addJenisBarangField,
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Jenis Barang"),
                ),
                const SizedBox(height: 16),
                _buildTextField(_controllerJumlahBarang, "Jumlah Barang", Icons.format_list_numbered, TextInputType.number),
                _buildTextField(_controllerHargaBarang, "Harga Barang", Icons.numbers, TextInputType.number),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: "Lokasi",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: ['Siwa', 'Sengkang', 'Sidrap', 'Belopa', 'Bajo', 'Padang Sappa']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _generateQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text("Generate QR Code"),
                ),
                if (_qrData.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  QrImage(
                    data: _qrData,
                    size: 200.0,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addCurrentQRCode,
                    child: const Text("Add QR Code to List and Save to Firebase"),
                  ),
                ],
                const SizedBox(height: 16),
                Text("Number of QR Codes: ${_qrCodeData.length}", style: Theme.of(context).textTheme.titleMedium),
                ElevatedButton.icon(
                  onPressed: _printQRCodes,
                  icon: const Icon(Icons.print),
                  label: const Text("Print All QR Codes"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
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

