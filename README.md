# Amal Mathew — Flutter Portfolio

Flutter port of the React/Vite portfolio (same sections, layout, colours, fonts and animations).

## Run

```bash
flutter create . --project-name amal_portfolio --platforms=web,android,ios,windows,macos,linux
# (keep this project's lib/, pubspec.yaml, analysis_options.yaml and web/index.html when asked to overwrite)
flutter pub get
flutter run -d chrome          # or any device
flutter build web --release
```

Android needs `<uses-permission android:name="android.permission.INTERNET"/>` (fonts) and, for `url_launcher`
on Android 11+, a `<queries>` entry for `https`/`mailto` (see the url_launcher docs).

## Structure

```
lib/
  main.dart / app.dart        app shell: layers, smooth wheel scroll (Lenis), preloader gate
  core/                       theme tokens, text styles, breakpoints, painters, widget toolkit
  components/                 preloader, navbar + mobile menu, footer, cursor, grain, scroll progress, floating cursors
  sections/                   hero, work, tech_marquee, credentials, statement, about, experience, services, contact
  data/                       projects / credentials / services / skills / experience (edit here)
```
