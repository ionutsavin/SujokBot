import 'package:flutter/material.dart';

class BackHandZones {
  static Map<String, Map<String, dynamic>> getZones() {
    return {
      'base_index_finger': {
        'name': 'Base of Index Finger',
        'description': 'Corresponds to the left shoulder joint',
        'color': Colors.green.shade300,
      },
      'middle_index_finger': {
        'name': 'Middle of Index Finger',
        'description': 'Corresponds to the left elbow joint',
        'color': Colors.green.shade500,
      },
      'tip_index_finger': {
        'name': 'Tip of Index Finger',
        'description': 'Corresponds to the left wrist joint',
        'color': Colors.green.shade700,
      },

      'base_middle_finger': {
        'name': 'Base of Middle Finger',
        'description': 'Corresponds the left hip joint',
        'color': Colors.red.shade300,
      },
      'middle_middle_finger': {
        'name': 'Middle of Middle Finger',
        'description': 'Corresponds to the left knee joint',
        'color': Colors.red.shade500,
      },
      'tip_middle_finger': {
        'name': 'Tip of Middle Finger',
        'description': 'Corresponds to the left ankle joint',
        'color': Colors.red.shade700,
      },

      'base_ring_finger': {
        'name': 'Base of Ring Finger',
        'description': 'Corresponds to the right hip joint',
        'color': Colors.grey.shade400,
      },
      'middle_ring_finger': {
        'name': 'Middle of Ring Finger',
        'description': 'Corresponds to the right knee joint',
        'color': Colors.grey.shade600,
      },
      'tip_ring_finger': {
        'name': 'Tip of Ring Finger',
        'description': 'Corresponds to the right ankle joint',
        'color': Colors.grey.shade800,
      },

      'base_little_finger': {
        'name': 'Base of Little Finger',
        'description': 'Corresponds to the right shoulder joint',
        'color': Colors.blue.shade300,
      },
      'middle_little_finger': {
        'name': 'Middle of Little Finger',
        'description': 'Corresponds to the right elbow joint',
        'color': Colors.blue.shade500,
      },
      'tip_little_finger': {
        'name': 'Tip of Little Finger',
        'description': 'Corresponds to the right wrist joint',
        'color': Colors.blue.shade700,
      },
    };
  }
}
