class Project {
  const Project({
    required this.id,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.longDescription,
    required this.tags,
    required this.categories,
    required this.image,
    this.github,
    this.demo,
    required this.featured,
    required this.color,
  });

  final int id;
  final String index;
  final String title;
  final String subtitle;
  final String description;
  final String longDescription;
  final List<String> tags;
  final List<String> categories;
  final String image;
  final String? github;
  final String? demo;
  final bool featured;
  final int color;
}

const projects = <Project>[
  Project(
    id: 1,
    index: '01',
    title: 'Voice Notes',
    subtitle: 'Smart Audio & Note Management',
    description:
        'A Flutter mobile app using Hive for local storage and Groq AI for speech-to-text and AI text generation, enabling one-tap voice note creation and offline access.',
    longDescription:
        'Built with Flutter, Hive for offline-first local storage, and Groq AI for speech-to-text and AI-powered text generation. Enables users to create voice notes from keywords with real-time transcription, organized playback, and cloud sync.',
    tags: ['Flutter', 'Dart', 'Hive', 'Groq AI', 'Firebase'],
    categories: ['Flutter', 'Firebase', 'AI'],
    image: 'assets/images/vn1full.png',
    github: 'https://github.com/amalmathew2003/note-app',
    demo: null,
    featured: true,
    color: 0xFFE63946,
  ),
  Project(
    id: 2,
    index: '02',
    title: 'Travel Tracker',
    subtitle: 'Real-Time Journey & Route Logging',
    description:
        'A real-time travel logging and route tracking mobile app with background execution, Google Maps integration, and live GPS movement monitoring.',
    longDescription:
        'Engineered for continuous travel tracking, route mapping, and travel history with Google Maps API, Provider state management, permission handling, and efficient background location services.',
    tags: ['Flutter', 'Dart', 'Google Maps', 'Provider', 'REST API'],
    categories: ['Flutter', 'REST API'],
    image: 'assets/images/travalappfull.png',
    github: 'https://github.com/amalmathew2003/travelapp',
    demo: null,
    featured: false,
    color: 0xFFE63946,
  ),
  Project(
    id: 3,
    index: '03',
    title: 'Motion Detection',
    subtitle: 'Device Security & Anti-Theft Sensor App',
    description:
        'A hardware sensor-driven security app that monitors accelerometer, gyroscope, and proximity sensors in the background to detect movement and sound an alarm.',
    longDescription:
        'Implements real-time sensor processing with Sensors Plus, near-device detection with proximity sensors, AudioPlayers integration, and background service execution for theft prevention and motion alerts.',
    tags: ['Flutter', 'Dart', 'Sensors', 'Audio Players', 'Background'],
    categories: ['Flutter'],
    image: 'assets/images/motion.png',
    github: 'https://github.com/amalmathew2003/MotionDetectionApp',
    demo: null,
    featured: false,
    color: 0xFFE63946,
  ),
];

const filterTabs = <String>['All', 'Flutter', 'Firebase', 'REST API', 'AI'];
