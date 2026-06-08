import 'package:flutter/material.dart';

class Medicamento {
  final String id;
  final String nome;
  final String dosagem;
  final String horario;
  final String frequencia;
  final String status;
  final DateTime dataCriacao;
  final DateTime? ultimaDose;

  Medicamento({
    required this.id,
    required this.nome,
    required this.dosagem,
    required this.horario,
    required this.frequencia,
    required this.status,
    required this.dataCriacao,
    this.ultimaDose,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      id: json['_id'],
      nome: json['nome'],
      dosagem: json['dosagem'],
      horario: json['horario'],
      frequencia: json['frequencia'],
      status: json['status'] ?? 'pendente',
      dataCriacao: DateTime.parse(json['dataCriacao']),
      ultimaDose: json['ultimaDose'] != null 
          ? DateTime.parse(json['ultimaDose']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'dosagem': dosagem,
      'horario': horario,
      'frequencia': frequencia,
    };
  }

  bool get isTomado => status == 'tomado';
  bool get isPerdido => status == 'perdido';
  bool get isPendente => status == 'pendente';

  Color getStatusColor() {
    switch (status) {
      case 'tomado':
        return Colors.green;
      case 'perdido':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String getStatusText() {
    switch (status) {
      case 'tomado':
        return 'Tomado';
      case 'perdido':
        return 'Perdido';
      default:
        return 'Pendente';
    }
  }
}