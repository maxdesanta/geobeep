import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _alarmSoundUrl;
  String? _alarmSoundName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadAlarmSound();
  }

  Future<void> _loadAlarmSound() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      setState(() {
        _alarmSoundUrl = doc['alarmSoundUrl'];
        _alarmSoundName = doc['alarmSoundName'];
      });
    }
  }

  Future<void> _pickAndUploadAlarmSound() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _isUploading = true;
      });
      final file = result.files.single;
      final ref = FirebaseStorage.instance.ref().child(
        'alarm_sounds/${user.uid}_${file.name}',
      );
      await ref.putFile(File(file.path!));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'alarmSoundUrl': url,
        'alarmSoundName': file.name,
      }, SetOptions(merge: true));
      setState(() {
        _alarmSoundUrl = url;
        _alarmSoundName = file.name;
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suara alarm berhasil di-upload!')),
        );
      }
    }
  }

  Future<void> _deleteAlarmSound() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _alarmSoundUrl == null) return;
    setState(() {
      _isUploading = true;
    });
    try {
      // Hapus file dari Firebase Storage
      final ref = FirebaseStorage.instance.refFromURL(_alarmSoundUrl!);
      await ref.delete();
    } catch (e) {
      // Jika file tidak ada di storage, lanjutkan saja
    }
    // Hapus field di Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'alarmSoundUrl': FieldValue.delete(),
      'alarmSoundName': FieldValue.delete(),
    }, SetOptions(merge: true));
    setState(() {
      _alarmSoundUrl = null;
      _alarmSoundName = null;
      _isUploading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suara alarm custom dihapus. Kembali ke default.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Tentang Aplikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'GeoBeep adalah aplikasi alarm berbasis lokasi untuk pengguna KRL dan komuter di Jabodetabek.',
          ),
          const Divider(height: 40),
          const Text(
            'Custom Suara Alarm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.music_note),
                  label: Text(
                    _isUploading ? 'Uploading...' : 'Pilih/Upload Suara Alarm',
                  ),
                  onPressed: _isUploading ? null : _pickAndUploadAlarmSound,
                ),
              ),
              const SizedBox(width: 10),
              if (_alarmSoundUrl != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Hapus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isUploading ? null : _deleteAlarmSound,
                ),
            ],
          ),
          if (_alarmSoundName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Suara alarm aktif: $_alarmSoundName',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          if (_alarmSoundUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'URL: $_alarmSoundUrl',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Kamu bisa memilih suara alarm sendiri dari file di HP-mu. Suara akan di-upload ke cloud dan bisa digunakan di device lain.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
