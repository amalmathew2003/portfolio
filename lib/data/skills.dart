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
  SkillCategory('Flutter', ['Flutter', 'Dart']),
  SkillCategory('State Management', ['Provider', 'BLoC', 'GetX']),
  SkillCategory('Backend Integration', ['Dio', 'REST APIs', 'Firebase Auth', 'Cloud Firestore', 'WebSockets']),
  SkillCategory('Tools & Architecture', ['Git / GitHub', 'Clean Architecture']),
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
