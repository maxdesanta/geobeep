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
            // Header lebih kecil & menyatu dengan desain
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
              Container(
                decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.location_on, color: Color(0xFF1976D2), size: 22),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'GeoBeep',
                  style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1976D2),
                  ),
                ),
                Text(
                  'Smart Location-Based Alarm',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                ],
              ),
              ],
            ),
            ),
          const SizedBox(height: 20),

          // Custom Suara Alarm (Ditempatkan di atas)
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
          const SizedBox(height: 10),
          const Text(
            'Kamu bisa memilih suara alarm sendiri dari file di HP-mu. Suara akan di-upload ke cloud dan bisa digunakan di device lain.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const Divider(height: 40),

          // Tentang Aplikasi (Ditempatkan di bawah - Disederhanakan)
          const Text(
            'Tentang Aplikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GeoBeep adalah aplikasi alarm cerdas berbasis lokasi untuk pengguna KRL Commuter Line. Aplikasi ini akan membangunkan Anda tepat sebelum tiba di stasiun tujuan.',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alarm otomatis berdasarkan GPS',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peta interaktif dengan 70+ stasiun KRL',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.blue,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifikasi pintar & custom alarm',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tim Pengembang
          const Text(
            'Tim Pengembang',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mahasiswa Teknik Informatika - 2025',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  '• Maulana Hasanudin (2307411006)\n'
                  '• Marcellinus Ario Xavier S. (2307411001)\n'
                  '• Septian Junior Ananda (2307411008)\n'
                  '• M. Ilham Fahrezi (2307411002)\n'
                  '• Royyan Hamzah (2307411010)\n'
                  '• Anhar Putranto (2307411027)\n'
                  '• Nur Wahid Hidayatullah (2307411025)',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Versi Aplikasi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Versi Aplikasi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  'v1.0.0 Beta',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
