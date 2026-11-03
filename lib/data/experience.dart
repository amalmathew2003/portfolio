class ExperienceEntry {
  const ExperienceEntry({
    required this.id,
    required this.role,
    required this.company,
    required this.period,
    required this.location,
    required this.type,
    required this.responsibilities,
  });

  final int id;
  final String role;
  final String company;
  final String period;
  final String location;
  final String type;
  final List<String> responsibilities;
}

const experiences = <ExperienceEntry>[
  ExperienceEntry(
    id: 1,
    role: 'Flutter Developer',
    company: 'Avanzo Cyber Security Solutions',
    period: '2024 — Present',
    location: 'Thrissur, Kerala',
    type: 'FULL-TIME',
    responsibilities: [
      'Leading mobile development for high-security applications using Flutter and Dart.',
      'Architecting secure REST API communication pipelines with Dio, JWT auto-refresh, and retry interceptors.',
      'Implementing reactive BLoC state management and real-time WebSocket communications.',
      'Synchronizing secure local caching with SQLite/Hive and Firebase Cloud Firestore.',
    ],
  ),
  ExperienceEntry(
    id: 2,
    role: 'Flutter Developer Intern',
    company: 'Luminar Technolab',
    period: '2023 — 2024',
    location: 'Kochi, Kerala',
    type: 'INTERNSHIP',
    responsibilities: [
      'Engineered modular cross-platform mobile applications using Flutter, Provider, and BLoC.',
      'Integrated Google Maps API, background geolocation services, and mobile sensors.',
      'Designed and consumed RESTful APIs with Clean Architecture (data, domain, presentation).',
      'Built responsive, accessible UI layouts with custom animations and smooth 60fps rendering.',
    ],
  ),
];
