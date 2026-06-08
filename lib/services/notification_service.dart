import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Inicializa timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Configurações Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configurações iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    
    // Cria o canal de notificação
    await _createNotificationChannel();
    
    // Solicita permissões
    await _requestPermissions();
  }

  Future<void> _createNotificationChannel() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Cria o canal para Android 8+
      await androidPlugin.createNotificationChannel(AndroidNotificationChannel(
        'medication_channel',
        'Lembretes de Medicamentos',
        description: 'Canal para lembretes de horário de medicamentos',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ));
    }
  }

  Future<void> _requestPermissions() async {
    // Para Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // Para Android 12+ (exact alarms)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
    
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> agendarLembrete({
    required int id,
    required String nome,
    required String dosagem,
    required int hora,
    required int minuto,
    required String frequencia,
  }) async {
    final dataAgendada = _proximoHorario(hora, minuto);
    
    const androidDetalhes = AndroidNotificationDetails(
      'medication_channel',
      'Lembretes de Medicamentos',
      channelDescription: 'Canal para lembretes de horário de medicamentos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
    );
    
    const iosDetalhes = DarwinNotificationDetails();
    
    const detalhes = NotificationDetails(
      android: androidDetalhes,
      iOS: iosDetalhes,
    );
    
    try {
      switch (frequencia.toLowerCase()) {
        case 'diario':
        case 'diariamente':
          await _notifications.zonedSchedule(
            id,
            '💊 Hora do medicamento',
            '$nome - $dosagem',
            dataAgendada,
            detalhes,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'medicamento_$id',
          );
          print('✅ Notificação DIÁRIA agendada para $hora:$minuto');
          break;
          
        case 'alternado':
        case 'dias alternados':
          await _agendarAlternado(
            id: id,
            nome: nome,
            dosagem: dosagem,
            hora: hora,
            minuto: minuto,
            dataInicial: dataAgendada,
            detalhes: detalhes,
          );
          print('✅ Notificação em DIAS ALTERNADOS agendada para $hora:$minuto');
          break;
          
        case 'semanal':
          await _notifications.zonedSchedule(
            id,
            '💊 Hora do medicamento',
            '$nome - $dosagem',
            dataAgendada,
            detalhes,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'medicamento_$id',
          );
          print('✅ Notificação SEMANAL agendada para $hora:$minuto');
          break;
          
        default:
          await _notifications.zonedSchedule(
            id,
            '💊 Hora do medicamento',
            '$nome - $dosagem',
            dataAgendada,
            detalhes,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'medicamento_$id',
          );
          print('✅ Notificação agendada para $hora:$minuto');
      }
    } catch (e) {
      print('❌ Erro ao agendar: $e');
    }
  }

  Future<void> _agendarAlternado({
    required int id,
    required String nome,
    required String dosagem,
    required int hora,
    required int minuto,
    required tz.TZDateTime dataInicial,
    required NotificationDetails detalhes,
  }) async {
    // Agendar a primeira notificação
    await _notifications.zonedSchedule(
      id,
      '💊 Hora do medicamento',
      '$nome - $dosagem',
      dataInicial,
      detalhes,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'medicamento_$id',
    );
    
    // Agendar as próximas notificações para dias alternados (próximos 60 dias)
    for (int i = 2; i <= 60; i += 2) {
      final proximaData = dataInicial.add(Duration(days: i));
      final novoId = (id * 1000 + i) % 2147483647;
      
      await _notifications.zonedSchedule(
        novoId,
        '💊 Hora do medicamento',
        '$nome - $dosagem',
        proximaData,
        detalhes,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'medicamento_$id',
      );
    }
  }

  // Adicione este método no NotificationService
Future<void> listarNotificacoesAgendadas() async {
  final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  
  if (androidPlugin != null) {
    final pending = await androidPlugin.pendingNotificationRequests();
    print('📋 Total de notificações agendadas: ${pending.length}');
    for (var notification in pending) {
      print('  - ID: ${notification.id}, Título: ${notification.title}');
    }
  }
}

  Future<void> cancelarNotificacoesMedicamento(int idBase) async {
    await _notifications.cancel(idBase);
    
    for (int i = 2; i <= 60; i += 2) {
      await _notifications.cancel(idBase * 1000 + i);
    }
    
    print('❌ Todas notificações do medicamento $idBase canceladas');
  }

  Future<void> cancelarNotificacao(int id) async {
    await _notifications.cancel(id);
    print('❌ Notificação cancelada ID: $id');
  }

  Future<void> cancelarTodas() async {
    await _notifications.cancelAll();
    print('❌ Todas notificações canceladas');
  }

  // Método para testar notificação em 10 segundos
  Future<void> testarNotificacaoImediata() async {
    final dataAgendada = tz.TZDateTime.now(tz.local).add(Duration(seconds: 10));
    
    const androidDetalhes = AndroidNotificationDetails(
      'medication_channel',
      'Lembretes de Medicamentos',
      channelDescription: 'Canal para lembretes de horário de medicamentos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    
    const detalhes = NotificationDetails(android: androidDetalhes);
    
    await _notifications.zonedSchedule(
      999999,
      '🔔 Teste de Notificação',
      'Esta é uma notificação de teste!',
      dataAgendada,
      detalhes,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    
    print('✅ Notificação de teste agendada para 10 segundos');
  }

  tz.TZDateTime _proximoHorario(int hora, int minuto) {
    final agora = tz.TZDateTime.now(tz.local);
    var agendado = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );
    
    if (agendado.isBefore(agora)) {
      agendado = agendado.add(const Duration(days: 1));
    }
    return agendado;
  }
}