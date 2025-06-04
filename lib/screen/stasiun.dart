import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gobeap/screen/map.dart';

class StasiunPage extends StatefulWidget {
  const StasiunPage({super.key});

  @override
  State<StasiunPage> createState() => _StasiunPageState();
}

class _StasiunPageState extends State<StasiunPage> {
  bool isLoggedIn = false; // status login user
  Map<String, bool> isFavorite = {};
  List<String> selectedStasiun = [];

  void tambahStasiun(String stasiun) {
    if (selectedStasiun.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maaf, hanya bisa memilih 3 stasiun')),
      );
      return;
    }
    setState(() {
      if (!selectedStasiun.contains(stasiun)) {
        selectedStasiun.add(stasiun);
      }
    });
  }

  void hapusStasiun(String stasiun) {
    setState(() {
      selectedStasiun.remove(stasiun);
    });
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Perlu Login'),
          content: Text('Anda harus login untuk menggunakan fitur ini.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
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
        title: Text(
          "Stasiun",
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stasiun').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final dokumen = snapshot.data!.docs;
          if (dokumen.isEmpty) {
            return Center(child: Text('Tidak ada stasiun yang tersedia'));
          }

          for (var doc in dokumen) {
            String id = doc.id;
            if (!isFavorite.containsKey(id)) {
              isFavorite[id] = false;
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: dokumen.length,
                  itemBuilder: (context, index) {
                    var doc = dokumen[index];
                    var dataStasiun = doc.data()! as Map<String, dynamic>;
                    String idStasiun = doc.id;
                    String namaStasiun = dataStasiun["nama_stasiun"];

                    bool sudahDipilih = selectedStasiun.contains(namaStasiun);
                    bool favorit = isFavorite[idStasiun]!;

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 21),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            namaStasiun,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (!isLoggedIn) {
                                    _showLoginDialog();
                                    return;
                                  }
                                  setState(() {
                                    isFavorite[idStasiun] = !isFavorite[idStasiun]!;
                                  });
                                },
                                child: Icon(
                                  favorit ? Icons.star : Icons.star_border,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  if (!sudahDipilih) {
                                    tambahStasiun(namaStasiun);
                                  }
                                },
                                child: Icon(
                                  Icons.add,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (selectedStasiun.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Alarm Stasiun Terpilih',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Divider(color: Colors.white),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: selectedStasiun.length,
                        itemBuilder: (context, selectedIdx) {
                          String namaDipilih = selectedStasiun[selectedIdx];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    namaDipilih,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    hapusStasiun(namaDipilih);
                                  },
                                  child: Icon(
                                    Icons.remove_circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

