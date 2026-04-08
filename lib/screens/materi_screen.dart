import 'package:flutter/material.dart';
import '../models/materi.dart';
import '../services/api_service.dart';

class MateriScreen extends StatelessWidget {
  const MateriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Materi')),
      body: FutureBuilder<List<Materi>>(
        future: ApiService.fetchMateri(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data[i].judul),
                  subtitle: Text(data[i].deskripsi),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
