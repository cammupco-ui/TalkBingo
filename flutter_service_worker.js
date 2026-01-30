'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"manifest.json": "1cd11bf99530f3011cd8078e2ced17ef",
"index.html": "c0f3660158cca6bf9b090c6fd1a86ba4",
"/": "c0f3660158cca6bf9b090c6fd1a86ba4",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "f24f801ed83e1f1655d80124eae4ed43",
"assets/assets/images/google_logo.svg": "9d1505ce71a16305b4c5d68511fe463c",
"assets/assets/images/arrow.svg": "200c28f2bed51b956cbb719542de1b3a",
"assets/assets/images/logo_36.png": "0ea564b60545bb5caaff7aead58633e2",
"assets/assets/images/soccerball.svg": "a73f4f6db6412eaa3f8eea2b283d3018",
"assets/assets/images/Setting.svg": "afa85022424c54129464f04aacb70429",
"assets/assets/images/Bow_2.svg": "989a5f7afc8184370ab377b8c8f47dbc",
"assets/assets/images/save_icon.svg": "d947c806e90b798f3125515d1f9febc0",
"assets/assets/images/open_icon.svg": "1ff995078412cb1bea44c43b8ac6b43a",
"assets/assets/images/HomeMainButton.svg": "9a2ac381595d2133fe3f99d5a201e2c1",
"assets/assets/images/pause_icon.svg": "dbe0d9d917a5c90da411b5198ddc1115",
"assets/assets/images/Goalkeeper.svg": "6da784883b2ecab66459966af479f551",
"assets/assets/images/logo_24.png": "cd7ebbefdcc46325b854cfb4357a7416",
"assets/assets/images/logo_48.png": "5aaccc33ab2b71199169c1106fd878e7",
"assets/assets/images/End_icon.svg": "f2f95de57ec31bd1c4b6079ad7a40f7d",
"assets/assets/images/Restart_icon.svg": "e6e43d74e86d6427e02ebcb6cb821b58",
"assets/assets/images/Bow.svg": "ce966b86e4be540eb721952ed9ef507b",
"assets/assets/images/PointPlus.svg": "a99c37f782179c793688688d8385ac32",
"assets/assets/images/play_icon.svg": "56c46b0acb1b60acf8e793506c7bc1d4",
"assets/assets/images/Notice.svg": "ba9d9be78ce95680cf4dc93bc8d25fb0",
"assets/assets/images/HomeMainButton2.svg": "e9251ef0382f08769e00e7ca4dd2342e",
"assets/assets/images/Targetboard.svg": "41157fbec510723a13ece8925d0efce3",
"assets/assets/images/open_icon.png": "3de7736ff83a4ea9b09931f42c4b4e72",
"assets/assets/images/Logo%2520Vector.svg": "84e9d3fc5105ea4c5d7944ca23279b16",
"assets/assets/fonts/EliceDigitalBaeum_Bold.ttf": "59af972a5ac77204d2c382b09180ab60",
"assets/assets/fonts/EliceDigitalBaeum_Regular.ttf": "281cb68d44cde40dea399119199cfc67",
"assets/assets/fonts/Nura%2520Normal.ttf": "e711293a5915f25961d14f286c8d81e7",
"assets/assets/fonts/Nura%2520Light.ttf": "71f3e878e878c01fb4bf0ff018d03870",
"assets/assets/fonts/Nura%2520ExtraBold.ttf": "c4d6d8ac4490b402c8b4b150f74fd123",
"assets/assets/fonts/Nura%2520Bold.ttf": "b1f4e04d3b2e90ffec5acee63290e57d",
"assets/assets/audio/typing_mid.wav": "dd54b5b28e322597d72ecdb008a9900e",
"assets/assets/audio/typing_high.wav": "31e1803e3ecaeecc56f05be133a29247",
"assets/assets/audio/disabled.wav": "6dc8fc17062320dc77973472cdc7169f",
"assets/assets/audio/thock_low.wav": "df1076a3ec9abbbe7aa7361fa04291b1",
"assets/assets/audio/thock_mid.wav": "2ee27b2d2f285fa795dc4f413e8eb835",
"assets/assets/audio/thock_high.wav": "e27e5c2e177dec6ae619eb941b528220",
"assets/fonts/MaterialIcons-Regular.otf": "0c25d9daf6f47daa6a3a67be7a9dc261",
"assets/NOTICES": "115abd975752ddbf4e8c83afb9c88f5b",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/iamport_flutter/assets/images/iamport-logo.png": "2face5c40217bba082ef64aa5c66e9b6",
"assets/FontManifest.json": "f690e1ef038dbabb7823f9ae7f907d48",
"assets/AssetManifest.bin": "1e9c641e0ff22f4a83e171b51eb8db2d",
"assets/AssetManifest.json": "eee59a9979a23a37bd4f171378c81479",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter_bootstrap.js": "101afce5cabbe2480e491c110d0c88cf",
"version.json": "f9aa6766728426972c163d8bcff05030",
"main.dart.js": "eb07b134b73f64a6d0ead208c0ff6c24"};
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
