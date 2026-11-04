class SkillCategory {
  const SkillCategory(this.label, this.skills);
  final String label;
  final List<String> skills;
}

class MarqueeItem {
  const MarqueeItem(this.name, this.icon);
  final String name;
  final String icon;
}

const skillCategories = <SkillCategory>[
  SkillCategory('Flutter', ['Flutter', 'Dart', 'OOP']),
  SkillCategory('State Management', ['BLoC', 'Provider', 'GetX', 'Riverpod']),
  SkillCategory('Backend & Data', ['Firebase', 'Firestore', 'REST APIs (Dio)', 'Hive', 'Sqflite', 'Supabase']),
  SkillCategory('Tools & Other', ['Git / GitHub', 'Razorpay', 'UI/UX Implementation', 'Clean Architecture']),
];

const marqueeItems = <MarqueeItem>[
  MarqueeItem('Flutter', '⚡'),
  MarqueeItem('Dart', '🎯'),
  MarqueeItem('Firebase', '🔥'),
  MarqueeItem('Supabase', '⚙️'),
  MarqueeItem('BLoC', '🧱'),
  MarqueeItem('GetX', '🔄'),
  MarqueeItem('Provider', '📦'),
  MarqueeItem('Dio', '🌐'),
  MarqueeItem('WebSockets', '🔌'),
  MarqueeItem('Git', '🌿'),
  MarqueeItem('Clean Architecture', '🏛️'),
  MarqueeItem('REST APIs', '⚡'),
];
