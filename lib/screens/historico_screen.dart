import 'package:flutter/material.dart';
import 'package:lembreme_app/services/api_service.dart';
import 'package:lembreme_app/models/medicamento.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<Medicamento> _medicamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final todos = await ApiService.getMedicamentos();
      setState(() => _medicamentos = todos.where((m) => m.isTomado || m.isPerdido).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicamentos.isEmpty
              ? const Center(child: Text('Nenhum medicamento registrado no histórico'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _medicamentos.length,
                  itemBuilder: (context, index) {
                    final medicamento = _medicamentos[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: medicamento.isTomado ? Colors.green : Colors.red,
                          child: Icon(
                            medicamento.isTomado ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(medicamento.nome),
                        subtitle: Text('${medicamento.dosagem} • ${medicamento.horario}'),
                        trailing: Text(
                          medicamento.getStatusText(),
                          style: TextStyle(
                            color: medicamento.getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}