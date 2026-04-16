class StateNormalizer {
  static const _stateMap = {
    'on_hold': 'paused',
    'onhold': 'paused',
    'complete': 'completed',
    'plan': 'plan_to_read',
    'planned': 'plan_to_read',
    'planning': 'plan_to_read',
    'to_read': 'plan_to_read',
  };

  static String normalize(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return _stateMap[normalized] ?? normalized;
  }
}