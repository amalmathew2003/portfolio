'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"index.html": "94ef4d6ec329cd6f5e147e463d4fcd84",
"/": "94ef4d6ec329cd6f5e147e463d4fcd84",
"flutter_bootstrap.js": "3d848b7c439046f661c6184aa66b0093",
"favicon.svg": "7416944572439ccf48005df02d7a5d5f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"assets/FontManifest.json": "b740a59a6b9ace361f84e9c31f28fce9",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "c0ad29d56cfe3890223c02da3c6e0448",
"assets/NOTICES": "fe1676ae4672bfb03f416dd0ca334798",
"assets/assets/images/VN3bg.png": "483ba9612ecbb8c3bc65cf80d48ccd8d",
"assets/assets/images/VN3.png": "7adc560d944ce5735683e812d5916163",
"assets/assets/images/githublogo.png": "ddcc4556b6bbf7951d19951c7012b446",
"assets/assets/images/link.png": "6f752c087691ac4022111bc145de8d53",
"assets/assets/images/travalapp2.png": "3ad84fc210359caeb6a42cca83f5b0b0",
"assets/assets/images/VN1.png": "f0c2d29751d7bbbe245ed7f60b4f9a6b",
"assets/assets/images/vn1full.png": "f20e411568507f82235d06966aa5b9fe",
"assets/assets/images/VN2bg.png": "b545a2fdd3592382b52be091e3872b52",
"assets/assets/images/travalapp.png": "73965d3d3f7c308b01156057d0de556a",
"assets/assets/images/motion.png": "3b69f24e3860e46ab657a0d26fc17d96",
"assets/assets/images/travalappfull.png": "40ea2d39ef00b0f278f15171c5875000",
"assets/assets/images/VN2.png": "c4127414d9965dd72c927e0acee26e91",
"assets/assets/images/VN1bg.png": "c7f6256697d6ce16c5eec309805d740e",
"assets/assets/images/portfolio.png": "5500e7600e62e868cfe29d187ff25b22",
"assets/assets/images/linkedIn-logo.wine.png": "fdf771edfbebc3683ec650003c256aee",
"assets/assets/images/motion2.png": "8e1b8c62f6c71c9122ee6ed1d7043c78",
"assets/AssetManifest.bin": "b986d1f4dc6aea2fcfdcf799d7baf81d",
"assets/AssetManifest.json": "ffe439b4525be3095fb2bfd2e66d71fb",
"assets/AssetManifest.bin.json": "d2606f53aecb20bf00d1e29c77d37370",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w100.ttf": "8e0608f8746a829e6d8dc59202ccaa9e",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w400.ttf": "476bcbabc02514171899f67cd210c14c",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w200.ttf": "362890f0e6b8ba2218f8aeb0ae415d9c",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w500.ttf": "1d5b4f5545922863d2e13b114de48057",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf": "c2cfa763bfbef41496253d10130b9883",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf": "4ae4b9f87c56ae345a14559785bf0b45",
"assets/packages/lucide_icons_flutter/assets/lucide.ttf": "61eac55c5f3ea149b69ae37bc3812f5b",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"version.json": "a6748b229bce4a92b16e5d3d5319aa22",
"main.dart.js": "53c8ca3bac07c6052da812c8f337a8ce"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
