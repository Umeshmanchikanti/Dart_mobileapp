import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _billImage;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _billImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount = _amountController.text;
    final description = _descriptionController.text;

    if (amount.isEmpty || description.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('transactions').add({
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'billImage': _billImage?.path ?? '',
    });

    if (!mounted) return;
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _billImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaction saved!")),
    );
  }

  Future<void> _exportToExcel() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .get();

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Add headers
    sheetObject.appendRow(["Amount", "Description", "Date"]);

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheetObject.appendRow([
        data['amount'],
        data['description'],
        data['date'],
      ]);
    }

    // Save file locally
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/transactions.xlsx');
    await file.writeAsBytes(excel.encode()!);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excel exported to ${file.path}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BillTracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            _billImage == null
                ? const Text("No bill image selected.")
                : Image.file(_billImage!),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Capture Bill Image"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text("Save Transaction"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exportToExcel,
              child: const Text("Export to Excel"),
            ),
          ],
        ),
      ),
    );
  }
}
