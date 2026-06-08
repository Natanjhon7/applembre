import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicamento.dart';

class ApiService {
  static const String baseUrl = 'https://lembreme-backend.onrender.com/api';

  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('📦 Token recuperado: ${token != null ? "Existe" : "Não existe"}');
      return token;
    } catch (e) {
      print('❌ Erro ao recuperar token: $e');
      return null;
    }
  }

  static Future<void> salvarToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      print('✅ Token salvo com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar token: $e');
    }
  }

  static Future<void> removerToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      print('❌ Token removido');
    } catch (e) {
      print('❌ Erro ao remover token: $e');
    }
  }

  static Future<String?> pegarToken() async {
    return await _getToken();
  }

  static Future<void> definirToken(String token) async {
    await salvarToken(token);
  }

  static Future<void> recuperarSenha(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/recuperar-senha'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Erro ao recuperar senha');
      }
    } catch (e) {
      print('📧 Simulando envio de e-mail para: $email');
      throw Exception('Funcionalidade em desenvolvimento. Contate o suporte.');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String senha) async {
  print('📡 [LOGIN] Iniciando - Email: $email');
  
  try {
    final url = Uri.parse('$baseUrl/auth/login');
    print('📡 [LOGIN] URL: $url');
    
    final body = jsonEncode({'email': email, 'senha': senha});
    print('📡 [LOGIN] Body: $body');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(Duration(seconds: 30));
    
    print('📡 [LOGIN] Status code: ${response.statusCode}');
    print('📡 [LOGIN] Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      String errorMsg = 'E-mail ou senha incorretos';
      try {
        final errorData = jsonDecode(response.body);
        print('📡 [LOGIN] Error data: $errorData');
        if (errorData.containsKey('error')) {
          errorMsg = errorData['error'].toString();
        }
      } catch (e) {
        print('📡 [LOGIN] Erro ao decodificar erro: $e');
      }
      throw Exception(errorMsg);
    }
    
    final Map<String, dynamic> data = jsonDecode(response.body);
    print('📡 [LOGIN] Dados decodificados: $data');
    print('📡 [LOGIN] Token existe? ${data.containsKey('token')}');
    
    if (data.containsKey('token')) {
      final token = data['token'];
      if (token != null && token.toString().isNotEmpty) {
        await salvarToken(token.toString());
        print('✅ [LOGIN] Token salvo com sucesso');
      } else {
        print('⚠️ [LOGIN] Token é nulo ou vazio');
      }
    } else {
      print('⚠️ [LOGIN] Resposta não contém token');
    }
    
    print('✅ [LOGIN] Login finalizado com sucesso');
    return data;
    
  } catch (e) {
    print('❌ [LOGIN] Erro capturado: $e');
    print('❌ [LOGIN] Tipo do erro: ${e.runtimeType}');
    rethrow;
  }
}

  static Future<Map<String, dynamic>> register(String nome, String email, String senha) async {
    print('📡 Tentando cadastro: $email');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
      ).timeout(Duration(seconds: 30));
      
      print('📡 Status code cadastro: ${response.statusCode}');
      print('📡 Resposta cadastro: ${response.body}');
      
      if (response.statusCode != 201) {
        String errorMsg = 'Erro no cadastro';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey('error')) {
            errorMsg = errorData['error'];
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
      
      return jsonDecode(response.body);
      
    } catch (e) {
      print('❌ Erro no cadastro: $e');
      throw Exception('Erro de conexão: Verifique sua internet e tente novamente');
    }
  }

  static Future<List<Medicamento>> getMedicamentos() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Não autenticado. Faça login novamente.');
    }
    
    print('🔑 Enviando token...');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicamentos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));
      
      print('📡 Status code getMedicamentos: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        await removerToken();
        throw Exception('Sessão expirada, faça login novamente');
      }
      
      if (response.statusCode != 200) {
        throw Exception('Erro ao carregar medicamentos: ${response.statusCode}');
      }
      
      final List data = jsonDecode(response.body);
      return data.map((json) => Medicamento.fromJson(json)).toList();
      
    } catch (e) {
      print('❌ Erro ao buscar medicamentos: $e');
      throw Exception('Erro ao carregar medicamentos');
    }
  }

  static Future<void> criarMedicamento({
    required String nome,
    required String dosagem,
    required String horario,
    required String frequencia,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Não autenticado. Faça login novamente.');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medicamentos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nome': nome,
          'dosagem': dosagem,
          'horario': horario,
          'frequencia': frequencia,
        }),
      ).timeout(Duration(seconds: 30));
      
      print('📡 Status code criarMedicamento: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        await removerToken();
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      
      if (response.statusCode != 201) {
        throw Exception('Erro ao criar medicamento');
      }
      
      print('✅ Medicamento criado com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao criar medicamento: $e');
      throw Exception('Erro ao criar medicamento');
    }
  }

  static Future<void> atualizarMedicamento({
    required String id,
    required String nome,
    required String dosagem,
    required String horario,
    required String frequencia,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Não autenticado');
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/medicamentos/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nome': nome,
          'dosagem': dosagem,
          'horario': horario,
          'frequencia': frequencia,
        }),
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 401) {
        await removerToken();
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      
    } catch (e) {
      throw Exception('Erro ao atualizar medicamento');
    }
  }

  static Future<void> marcarTomado(String id) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Não autenticado');
    
    try {
      await http.patch(
        Uri.parse('$baseUrl/medicamentos/$id/tomar'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 30));
    } catch (e) {
      print('❌ Erro ao marcar como tomado: $e');
    }
  }

  static Future<void> atualizarStatus(String id, String status) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Não autenticado');
    
    try {
      await http.patch(
        Uri.parse('$baseUrl/medicamentos/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      ).timeout(Duration(seconds: 30));
    } catch (e) {
      print('❌ Erro ao atualizar status: $e');
    }
  }

  static Future<void> excluirMedicamento(String id) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Não autenticado');
    
    try {
      await http.delete(
        Uri.parse('$baseUrl/medicamentos/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 30));
    } catch (e) {
      print('❌ Erro ao excluir medicamento: $e');
    }
  }
}