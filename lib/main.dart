import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  runApp(const RetailBridgeApp());
}

class RetailBridgeApp extends StatelessWidget {
  const RetailBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Bridge Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF001F3F), // Azul marino profesional
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007BFF)),
        useMaterial3: true,
      ),
      home: const InventoryScreen(),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Comunicación con el código JAVA
  static const platform = MethodChannel('bolivia.hansel/retail');
  
  List _products = [];
  String _batteryLevel = "Consultando...";
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _getBatteryStatus();
  }

  // LLAMADA AL CÓDIGO NATIVO (JAVA)
  Future<void> _getBatteryStatus() async {
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = '$result%';
    } on PlatformException catch (e) {
      batteryLevel = "Error: ${e.message}";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  // CARGA DE JSON LOCAL
  Future<void> _loadProducts() async {
    final String response = await rootBundle.loadString('assets/products.json');
    final data = await json.decode(response);
    setState(() {
      _products = data;
    });
  }

  // SIMULACIÓN DE SINCRONIZACIÓN (RETAIL STYLE)
  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulación de red
    setState(() => _isSyncing = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventario sincronizado con éxito')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retail Inventory Pro', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF001F3F),
        actions: [
          IconButton(
            icon: const Icon(Icons.battery_std, color: Colors.white),
            onPressed: _getBatteryStatus,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header de estado del dispositivo (BRIDGE NATIVO)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Estado del Dispositivo:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Batería: $_batteryLevel", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Lista de Productos
          Expanded(
            child: _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF007BFF), child: Icon(Icons.inventory, color: Colors.white)),
                          title: Text(_products[index]['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Stock: ${_products[index]['stock']} unidades"),
                          trailing: Text("\$${_products[index]['precio']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
          
          // Botón de Sincronización
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncData,
                icon: _isSyncing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? "Sincronizando..." : "Sincronizar Inventario"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}