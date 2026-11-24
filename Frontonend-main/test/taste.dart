import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const RoomieHubApp());
}

class RoomieHubApp extends StatelessWidget {
  const RoomieHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roomie Hub Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _responseMessage = 'Presiona el botón para probar la conexión';
  bool _isLoading = false;

  /* IMPORTANTE cambia la IP segun donde corras la app
     emulador Android usa 10 0 2 2 puerto 8080
     simulador iOS web o escritorio usa localhost puerto 8080
     telefono fisico usa la IP local de tu compu puerto 8080 */
  final String backendUrl = 'http://10.0.2.2:8080/test';

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _responseMessage = 'Conectando con backend...';
    });

    try {
      final response = await http.get(Uri.parse(backendUrl));

      if (response.statusCode == 200) {
        setState(() {
          _responseMessage = '✅ Respuesta del Servidor:\n${response.body}';
        });
      } else {
        setState(() {
          _responseMessage = '⚠️ Error en servidor: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = '❌ Error de conexión:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roomie Hub - Test Conexión'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.api,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  _responseMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Probar API Backend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}