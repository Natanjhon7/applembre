import 'package:flutter/material.dart';
import 'package:lembreme_app/models/medicamento.dart';
import 'package:lembreme_app/services/api_service.dart';

class DetalhesMedicamentoScreen extends StatefulWidget {
  final Medicamento medicamento;

  const DetalhesMedicamentoScreen({super.key, required this.medicamento});

  @override
  State<DetalhesMedicamentoScreen> createState() => _DetalhesMedicamentoScreenState();
}

class _DetalhesMedicamentoScreenState extends State<DetalhesMedicamentoScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _dosagemController;
  late String _horario;
  late String _frequencia;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.medicamento.nome);
    _dosagemController = TextEditingController(text: widget.medicamento.dosagem);
    _horario = widget.medicamento.horario;
    _frequencia = widget.medicamento.frequencia;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome é obrigatório'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_dosagemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosagem é obrigatória'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.atualizarMedicamento(
        id: widget.medicamento.id,
        nome: _nomeController.text.trim(),
        dosagem: _dosagemController.text.trim(),
        horario: _horario,
        frequencia: _frequencia,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicamento atualizado!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _excluir() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir'),
        content: const Text('Tem certeza que deseja excluir este medicamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ApiService.excluirMedicamento(widget.medicamento.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicamento excluído'), backgroundColor: Colors.red),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Medicamento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _excluir,
            tooltip: 'Excluir',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Medicamento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosagemController,
              decoration: const InputDecoration(
                labelText: 'Dosagem',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.science),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Horário'),
              subtitle: Text(_horario),
              onTap: () async {
                final timeParts = _horario.split(':');
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(timeParts[0]), 
                    minute: int.parse(timeParts[1]),
                  ),
                );
                if (time != null) {
                  setState(() {
                    _horario = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Frequência'),
              subtitle: Text(_frequencia == 'diaria' ? 'Diário' : (_frequencia == 'alternados' ? 'Dias alternados' : 'Semanal')),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Diário'),
                        onTap: () {
                          setState(() => _frequencia = 'diaria');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Dias alternados'),
                        onTap: () {
                          setState(() => _frequencia = 'alternados');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Semanal'),
                        onTap: () {
                          setState(() => _frequencia = 'semanal');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Atualizar', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}