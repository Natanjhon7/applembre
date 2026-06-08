import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lembreme_app/screens/detalhes_medicamento_screen.dart';
import 'package:lembreme_app/screens/historico_screen.dart';
import 'package:lembreme_app/screens/novo_medicamento_screen.dart';
import 'package:lembreme_app/services/api_service.dart';
import 'package:lembreme_app/models/medicamento.dart';
import 'package:lembreme_app/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Medicamento> _medicamentos = [];
  bool _isLoading = true;
  String _filter = 'todos';

  @override
  void initState() {
    super.initState();
    _carregarMedicamentos();
    _verificarEsquecidos();

     WidgetsBinding.instance.addPostFrameCallback((_) async {
    final notificationService = NotificationService();
    await notificationService.listarNotificacoesAgendadas();
  });
  }

  

  Future<void> _carregarMedicamentos() async {
    setState(() => _isLoading = true);
    try {
      final medicamentos = await ApiService.getMedicamentos();
      setState(() => _medicamentos = medicamentos);
      print('✅ Carregados ${medicamentos.length} medicamentos');
    } catch (e) {
      print('❌ Erro ao carregar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarEsquecidos() async {
    try {
      final medicamentos = await ApiService.getMedicamentos();
      final agora = DateTime.now();
      
      for (var med in medicamentos) {
        if (med.status == 'tomado') continue;
        
        final horarioParts = med.horario.split(':');
        final horarioMed = DateTime(
          agora.year, agora.month, agora.day,
          int.parse(horarioParts[0]), int.parse(horarioParts[1])
        );
        
        if (horarioMed.isBefore(agora) && med.status == 'pendente') {
          await ApiService.atualizarStatus(med.id, 'esqueceu');
          print('⚠️ ${med.nome} marcado como esquecido');
        }
      }
      _carregarMedicamentos();
    } catch (e) {
      print('Erro ao verificar esquecidos: $e');
    }
  }

  

  Future<void> _configurarNotificacoes() async {
    // Verificar permissão
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificações ativadas!'), backgroundColor: Colors.green),
        );
      } else {
        // Abrir configurações do app
        await openAppSettings();
      }
    } else if (await Permission.notification.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificações já estão ativadas'), backgroundColor: Colors.green),
      );
    } else {
      await openAppSettings();
    }
  }

  List<Medicamento> get _medicamentosFiltrados {
    switch (_filter) {
      case 'pendentes':
        return _medicamentos.where((m) => m.isPendente).toList();
      case 'tomados':
        return _medicamentos.where((m) => m.isTomado).toList();
      default:
        return _medicamentos;
    }
  }

  Future<void> _marcarTomado(Medicamento medicamento) async {
    try {
      await ApiService.marcarTomado(medicamento.id);
      await _carregarMedicamentos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicamento marcado como tomado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _excluirMedicamento(String id) async {
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
    
    if (confirm == true) {
      try {
        await ApiService.excluirMedicamento(id);
        await _carregarMedicamentos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicamento excluído!'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      await ApiService.removerToken();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LEMBRE-ME'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _configurarNotificacoes,
            tooltip: 'Configurar notificações',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todos', child: Text('Todos')),
              const PopupMenuItem(value: 'pendentes', child: Text('Pendentes')),
              const PopupMenuItem(value: 'tomados', child: Text('Tomados')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoricoScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicamentosFiltrados.isEmpty
              ? const Center(child: Text('Nenhum medicamento cadastrado'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _medicamentosFiltrados.length,
                  itemBuilder: (context, index) {
                    final medicamento = _medicamentosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: medicamento.getStatusColor(),
                          child: Icon(
                            medicamento.isTomado ? Icons.check : Icons.access_time,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          medicamento.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${medicamento.dosagem} • ${medicamento.horario}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (medicamento.isPendente)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _marcarTomado(medicamento),
                                tooltip: 'Marcar como tomado',
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalhesMedicamentoScreen(medicamento: medicamento),
                                  ),
                                );
                                if (result == true) _carregarMedicamentos();
                              },
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _excluirMedicamento(medicamento.id),
                              tooltip: 'Excluir',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botão de teste de notificação
          FloatingActionButton.small(
            heroTag: "test_notification",
            onPressed: () async {
              final notificationService = NotificationService();
              await notificationService.testarNotificacaoImediata();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Notificação de teste em 10 segundos!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Icon(Icons.notifications_active),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          // Botão principal de adicionar
          FloatingActionButton(
            heroTag: "add_medication",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovoMedicamentoScreen()),
              );
              if (result == true) _carregarMedicamentos();
            },
            child: const Icon(Icons.add),
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }
  
  
  Future<void> openAppSettings() async {}
}