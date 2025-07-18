import 'package:flutter/material.dart';

class PalmHandZones {
  static Map<String, Map<String, dynamic>> getZones() {
    return {
      'central_palm': {
        'name': 'Central Palm',
        'description': 'Corresponds to the abdomen',
        'color': Colors.red.shade400,
      },
      'thenar_eminence': {
        'name': 'Thenar Eminence',
        'description': 'Corresponds to the chest',
        'color': Colors.yellow.shade600,
      },
      'base_thumb': {
        'name': 'Base of Thumb',
        'description': 'Corresponds to the neck',
        'color': Colors.brown.shade300,
      },
      'distal_thumb': {
        'name': 'Distal Thumb',
        'description': 'Corresponds to the head',
        'color': Colors.brown.shade500,
      },

      'base_index_finger': {
        'name': 'Base of Index Finger',
        'description': 'Corresponds to the left shoulder',
        'color': Colors.green.shade300,
      },
      'middle_index_finger': {
        'name': 'Middle of Index Finger',
        'description': 'Corresponds to the left elbow',
        'color': Colors.green.shade500,
      },
      'tip_index_finger': {
        'name': 'Tip of Index Finger',
        'description': 'Corresponds to the left wrist',
        'color': Colors.green.shade700,
      },

      'base_middle_finger': {
        'name': 'Base of Middle Finger',
        'description': 'Corresponds to the left hip',
        'color': Colors.red.shade300,
      },
      'middle_middle_finger': {
        'name': 'Middle of Middle Finger',
        'description': 'Corresponds to the left knee',
        'color': Colors.red.shade500,
      },
      'tip_middle_finger': {
        'name': 'Tip of Middle Finger',
        'description': 'Corresponds to the left ankle',
        'color': Colors.red.shade700,
      },

      'base_ring_finger': {
        'name': 'Base of Ring Finger',
        'description': 'Corresponds to the right hip',
        'color': Colors.grey.shade300,
      },
      'middle_ring_finger': {
        'name': 'Middle of Ring Finger',
        'description': 'Corresponds to the right knee',
        'color': Colors.grey.shade500,
      },
      'tip_ring_finger': {
        'name': 'Tip of Ring Finger',
        'description': 'Corresponds to the right ankle',
        'color': Colors.grey.shade700,
      },

      'base_little_finger': {
        'name': 'Base of Little Finger',
        'description': 'Corresponds to the right shoulder',
        'color': Colors.blue.shade300,
      },
      'middle_little_finger': {
        'name': 'Middle of Little Finger',
        'description': 'Corresponds to the right elbow',
        'color': Colors.blue.shade500,
      },
      'tip_little_finger': {
        'name': 'Tip of Little Finger',
        'description': 'Corresponds to the right wrist',
        'color': Colors.blue.shade700,
      },
    };
  }
}
