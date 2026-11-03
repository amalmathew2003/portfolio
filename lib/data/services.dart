class Service {
  const Service({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.tags,
  });
  final int id;
  final String number;
  final String title;
  final String description;
  final List<String> tags;
}

const services = <Service>[
  Service(
    id: 1,
    number: '01',
    title: 'Flutter App Development',
    description: 'End-to-end cross-platform mobile application development for Android and iOS. From architecture design to Play Store / App Store submission — I handle the entire lifecycle.',
    tags: ['Flutter', 'Dart', 'BLoC', 'Provider', 'Riverpod'],
  ),
  Service(
    id: 2,
    number: '02',
    title: 'Firebase Integration',
    description: 'Seamless Firebase backend setup — Authentication, Firestore, Realtime Database, Cloud Storage, Remote Config, Push Notifications, and Analytics.',
    tags: ['Firebase', 'Cloud Functions', 'Firestore', 'FCM'],
  ),
  Service(
    id: 3,
    number: '03',
    title: 'REST API Integration',
    description: 'Clean API consumption with proper error handling, authentication headers, token refresh flows, and offline-first caching strategies.',
    tags: ['REST APIs', 'GraphQL', 'Dio', 'Retrofit', 'Interceptors'],
  ),
  Service(
    id: 4,
    number: '04',
    title: 'App Performance Optimization',
    description: 'Profiling and optimising Flutter apps for smooth 60/120 fps rendering, reduced memory footprint, fast startup time, and minimal jank.',
    tags: ['DevTools', 'Isolates', 'Lazy Loading', 'Caching'],
  ),
  Service(
    id: 5,
    number: '05',
    title: 'UI/UX Implementation',
    description: 'Pixel-perfect implementation of Figma designs into Flutter widgets — custom animations, transitions, and platform-adaptive components.',
    tags: ['Custom Widgets', 'Animations', 'Figma', 'Responsive UI'],
  ),
];
