import 'dart:convert';

import 'package:venastudio/common.dart';

class SmartServiceAssignmentResult {
  const SmartServiceAssignmentResult({
    required this.savis,
    required this.agent,
    required this.payload,
  });

  final Savis savis;
  final Agent agent;
  final Map<String, dynamic> payload;

  Map<String, String> toCartMap() {
    return {
      'agentName': agent.name,
      'agentId': '${agent.id}',
      'smartAssignment': jsonEncode(payload),
    };
  }
}
