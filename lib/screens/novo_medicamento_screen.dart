import 'package:flutter/material.dart';
import 'package:lembreme_app/services/api_service.dart';
import 'package:lembreme_app/services/notification_service.dart';

class NovoMedicamentoScreen extends StatefulWidget {
  const NovoMedicamentoScreen({super.key});

  @override
  State<NovoMedicamentoScreen> createState() => _NovoMedicamentoScreenState();
}

class _NovoMedicamentoScreenState extends State<NovoMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dosagemController = TextEditingController();
  TimeOfDay _horario = const TimeOfDay(hour: 8, minute: 0);
  String _frequencia = 'diário';
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isLoading = true);
  
  final nome = _nomeController.text.trim();
  final dosagem = _dosagemController.text.trim();
  final horarioString = '${_horario.hour.toString().padLeft(2, '0')}:${_horario.minute.toString().padLeft(2, '0')}';
  
  try {
    print('📤 Enviando medicamento: $nome, $dosagem, $horarioString, $_frequencia');
    
    await ApiService.criarMedicamento(
      nome: nome,
      dosagem: dosagem,
      horario: horarioString,
      frequencia: _frequencia,
    );
    
    // ⬇️ CORRIGIDO: ID dentro do limite de 32 bits
    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;
    
    String freqAjustada = _frequencia;
    if (_frequencia == 'diaria') freqAjustada = 'diario';
    if (_frequencia == 'alternados') freqAjustada = 'alternado';
    if (_frequencia == 'semanal') freqAjustada = 'semanal';
    
    final notificationService = NotificationService();
    await notificationService.agendarLembrete(
      id: id,  // ✅ Agora o ID está correto
      nome: nome,
      dosagem: dosagem,
      hora: _horario.hour,
      minuto: _horario.minute,
      frequencia: freqAjustada,
    );
    
    print('✅ Notificação agendada com ID: $id');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento salvo e notificação agendada!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  } catch (e) {
    print('❌ Erro ao salvar: $e');
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
        title: const Text('Novo Medicamento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Medicamento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosagemController,
                decoration: const InputDecoration(
                  labelText: 'Dosagem (ex: 500mg, 1 comprimido)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.science),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Dosagem obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Horário'),
                subtitle: Text(_horario.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _horario,
                  );
                  if (time != null) {
                    setState(() => _horario = time);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.repeat),
                title: const Text('Frequência'),
                subtitle: Text(_frequencia),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('diário'),
                          onTap: () {
                            setState(() => _frequencia = 'diaria');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('dias alternados'),
                          onTap: () {
                            setState(() => _frequencia = 'alternados');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('semanal'),
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
                      : const Text('Salvar', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}