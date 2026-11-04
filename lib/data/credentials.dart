class Credential {
  const Credential({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.year,
  });

  final int id;
  final String title;
  final String subtitle;
  final String year;
}

const credentials = <Credential>[
  Credential(
    id: 1,
    title: 'Bachelor of Computer Applications (BCA)',
    subtitle: 'Mahatma Gandhi University · Degree (2021–2024)',
    year: '2024',
  ),
  Credential(
    id: 2,
    title: 'Flutter Developer Specialization',
    subtitle: 'Luminar Technolab · Professional Internship',
    year: '2024',
  ),
  Credential(
    id: 3,
    title: 'Reactive State Management Architecture',
    subtitle: 'BLoC, Provider & Riverpod · Design Patterns',
    year: '2024',
  ),
  Credential(
    id: 4,
    title: 'Firebase & Cloud Firestore Integration',
    subtitle: 'Auth, Firestore, Cloud Sync & Storage',
    year: '2024',
  ),
  Credential(
    id: 5,
    title: 'REST API & Dio Interceptors Pipeline',
    subtitle: 'Dio, JWT Token Rotation & Offline Cache',
    year: '2025',
  ),
  Credential(
    id: 6,
    title: 'Mobile Application Security & Engineering',
    subtitle: 'Avanzo Cyber Solutions · Engineering',
    year: '2025',
  ),
];
