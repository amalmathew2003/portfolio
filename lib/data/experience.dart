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
    company: 'Avanzo Cyber Solutions',
    period: '2025 — Present',
    location: 'Thrissur, Kerala',
    type: 'FULL-TIME',
    responsibilities: [
      'Developed and maintained cross-platform mobile applications using Flutter and Dart, integrating REST APIs and Firebase services (Auth, Firestore).',
      'Implemented scalable state management architecture using Provider and BLoC, improving code maintainability and reducing bugs.',
      'Built responsive, high-performance UI for both mobile and web platforms, optimizing rendering and load times.',
      'Collaborated cross-functionally with backend and UI/UX teams to deliver high-quality applications on schedule.',
    ],
  ),
  ExperienceEntry(
    id: 2,
    role: 'Flutter Developer Intern',
    company: 'Luminar Technolab',
    period: 'Aug 2024 — Jan 2025',
    location: 'Kochi, Kerala',
    type: 'INTERNSHIP',
    responsibilities: [
      'Built cross-platform mobile applications using Flutter and Dart following modular MVC/MVVM architecture for long-term scalability.',
      'Implemented efficient state management with Provider and BLoC, improving application performance and maintainability.',
      'Integrated REST APIs and Firebase services (Auth, Firestore) to enable secure authentication and real-time data synchronization.',
      'Performed debugging, testing, and performance optimization, improving app responsiveness and stability.',
    ],
  ),
];
