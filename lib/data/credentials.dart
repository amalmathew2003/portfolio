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
    subtitle: 'Computer Science Fundamentals · Degree',
    year: '2023',
  ),
  Credential(
    id: 2,
    title: 'Flutter Developer Specialization',
    subtitle: 'Luminar Technolab · Professional Internship',
    year: '2024',
  ),
  Credential(
    id: 3,
    title: 'Mobile Application Security & Architecture',
    subtitle: 'Avanzo Cyber Security Solutions · Engineering',
    year: '2024',
  ),
  Credential(
    id: 4,
    title: 'Reactive State Management (BLoC & Provider)',
    subtitle: 'Enterprise Architecture & Design Patterns',
    year: '2023',
  ),
  Credential(
    id: 5,
    title: 'Firebase & Cloud Firestore Integration',
    subtitle: 'Real-Time Sync, Auth & Mobile Backend',
    year: '2023',
  ),
  Credential(
    id: 6,
    title: 'REST API & Dio Interceptors Pipeline',
    subtitle: 'JWT Rotation, Offline Cache & Resilient Networking',
    year: '2024',
  ),
];
