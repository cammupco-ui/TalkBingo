'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "1e95fffedac5a39c6386efa07bcea6f7",
"guide_bingo.html": "4590b6fd44b5a1f538a00ba4339cb50f",
"version.json": "c9ed1de31c87368f5631be426d8223cf",
"index.html": "4672a25fd581f979901a90cb13408598",
"/": "4672a25fd581f979901a90cb13408598",
"CNAME": "6a833849f699a4a5a3da962b67295abb",
"main.dart.js": "12c69a79df0d0bdbba7ef5736a5c4a07",
"privacy_en.html": "08c85510f8f610dd19c375026a085285",
"terms.html": "cab06bd8337b0e69168be7666ba58e69",
"404.html": "884fdd4b6255e9108cf9ee9a2432abba",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"favicon.png": "1969fb60d3b8cc823fed21cd431dd72d",
"guide_points.html": "0704ed65ce01aca2dc4478177af94d69",
"icons/Icon-192.png": "b1d0fb005db1f12b5ce1c317d678ab17",
"icons/Icon-maskable-192.png": "b1d0fb005db1f12b5ce1c317d678ab17",
"icons/Icon-maskable-512.png": "219427107deba332c079c717bcd6c4d7",
"icons/Icon-512.png": "219427107deba332c079c717bcd6c4d7",
"guide_points_en.html": "f9888e3630dc930d437eb8e470d8a56c",
"manifest.json": "094d26e493534907192ff6d154462c09",
".git/config": "e12743892846ddb7b3abdffa91108a20",
".git/objects/92/54b7fdc6c8ae52c2882be959d47ec64bcbcef1": "a570151ebd47a49b6521313e576917f3",
".git/objects/66/fd193d46b728b2188369d1bc4116dc23959792": "cb580b672fbe95112473af0e41e6d748",
".git/objects/3e/19d63a62d044c2fac7cc7392bc1243525e3d7f": "8b127e4df48d1fb34bb90eab8fbd11fc",
".git/objects/3b/5222cddea2a41fd78134c8987bea555ef1e903": "a8dfa399179218752b319d6f59b8cca8",
".git/objects/04/952ca6488ee2a246e26f7d55df3b248766be30": "278b22179f73be1ab18316688e54036f",
".git/objects/69/59410fd790779effd00ea98dbf76dd94a7dd43": "fddc53eef2ea9863b762e6810dba611e",
".git/objects/3d/eac5f5dda489394f8980d66231f3ef2ad9bcb0": "fb3acec8830d0e0860af8b657cc36d89",
".git/objects/58/ffff61c1341643d89f29b87862de1f930a627b": "ce28da1ee8f6f8e1891e3beec04490e8",
".git/objects/93/4e891242e232f2f609ba5c3d721220539e6fed": "c7511362e302ba68d7fe5bcc56b88983",
".git/objects/0e/bd1df8bae64d4dcc19181c18d4836df6da4240": "46ca9f87f66b0441aede1a1cd3bed8ce",
".git/objects/34/007f7cd296a54a8df5acac14c53e3d1e2974f2": "885661c47dfe64f8a9d60b426d591e10",
".git/objects/33/21cd24a9921c4e93f41c673b00c3761c5a36f6": "8d8075d79b08900e3c6d2af365417ba2",
".git/objects/9d/a07a512eda04b40d5b1b4cee15543dcf32644d": "3fa2e122b0abbf784cf95f9a1f3db7d2",
".git/objects/d9/c94f841aa5c99b9815e8d128d0f9b2d4f95361": "9aba748370a29785f681876e13ec17d5",
".git/objects/da/fc64f368d883af4d0f7f36092cf595344d0fe3": "24331ae8cdac8feb5d41568cb67382a7",
".git/objects/b4/ce6d4d2511890b5af57657ad27f37dd5aa0d95": "6551221f7fe4bd2d661cdb486e25b213",
".git/objects/a5/b420f49a337d4c1316f68a654fc3af4be58c11": "4f0fdc6cfa7bdb814961dbd2940436b7",
".git/objects/a5/1f5e75e0e714d2a7b57604cbcda913ea506090": "0ed3fca1e65a00d21286b823ee13f528",
".git/objects/a5/682a82cbda482fea704ec0e9b646af1eb4a7a2": "2761b18304651044c57285e61230c54c",
".git/objects/bc/e9a50f29da510cb9c1aab58e95b9a5404eae81": "4055856e3eb38c8397da7562bffc830a",
".git/objects/e5/dea9a8cc14782f28bad3731f88519efcca6c8e": "3cf91cbb88311f1e0a620b553d54ae4a",
".git/objects/e2/b1f51b2ddaa14977be1e5150756f2ebc604941": "9ea95ebcc6469c304e95acd151648243",
".git/objects/ee/af67c4a70a9bc30fb7ba3c4ecfcfb9d7419c93": "757318d172705e6f48c0f05b3b179298",
".git/objects/fd/5f9ac29c98f2514a2e8f8608d646e7eb58270b": "f72b4bb98d8724643b8e1327b6164e72",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/e4/0ae51a9ad8d226c72a079655597568cb341ecf": "3029f764267fc7a6c3d530fe918708a1",
".git/objects/e4/2403107c20cdd1b6d46d50071018f832fc72e4": "93260c962a252e93df247abec3c6a274",
".git/objects/c8/1a64cced1042318de3588f4362a3020931f3c4": "5c66208dce293591feb4685027719797",
".git/objects/ed/3bd4a6a2e59eea6e8bd157616086f6dbfaaf37": "9a7b6817a593e41cd3f8170a03dc2535",
".git/objects/c6/06caa16378473a4bb9e8807b6f43e69acf30ad": "ed187e1b169337b5fbbce611844136c6",
".git/objects/ec/361605e9e785c47c62dd46a67f9c352731226b": "d1eafaea77b21719d7c450bcf18236d6",
".git/objects/27/a297abdda86a3cbc2d04f0036af1e62ae008c7": "51d74211c02d96c368704b99da4022d5",
".git/objects/4b/250aafad214c146ae9daf0c8bbd6bc3caf57ac": "31fcb9d0f09c3d9a59eae061db7c5c22",
".git/objects/45/f5657f46fd4f7be5fa000ec436c547065da814": "822dac0e6baed3fe8e198c35de5b69e2",
".git/objects/1f/5bb6080891812faccc590ac9e7084d3f70eba1": "38715cefca577b349f7779791416124d",
".git/objects/1f/45b5bcaac804825befd9117111e700e8fcb782": "7a9d811fd6ce7c7455466153561fb479",
".git/objects/73/7f149c855c9ccd61a5e24ce64783eaf921c709": "1d813736c393435d016c1bfc46a6a3a6",
".git/objects/28/40989de1beab7accdd297207770d0cef28fa0f": "ae5b685e0bef1c40b5a5309ce08be26a",
".git/objects/7b/a601372a67905ec32a81c19294b7c909525f30": "70b47a0572ce568b466d059f3396b8df",
".git/objects/8a/e1bc4aeff5d063e1a9da8b830eb427a9856f2e": "50a805873ab94203715551d372c07f7a",
".git/objects/4c/16ffa3849a32c5554f0858eadd0f517afc2dac": "e69b535b4c73770803917b0abc60c7a3",
".git/objects/2f/54d4b8193ed0f7074255129776d19310581e95": "915868ef8faafb5d1e663b227f8a1ede",
".git/objects/43/8a687dc99db3ff8f14b33b94cfe732c9f8863a": "7abd699fe0fe344624b87b1de47664b7",
".git/objects/07/8326e604e1568902a7c483c8441c935a0a5f68": "2564cb37697254fe02788c9f0492675e",
".git/objects/38/da43dabffd2a12bab61c0bb4e3ac289bccd336": "0089e4262edb07b612cf2be0d9f6b595",
".git/objects/09/1f92c82997f903f6c0523e278c5c1a78c044b8": "fe66e134a37cb29de1c3f9f2d41ef303",
".git/objects/09/c5811aea5fe16567c74df4f145349ef0585bcb": "7327174418e838edbbc79437ec348eb1",
".git/objects/91/62bd508b61ba40fe04d8fb3dc4df1fc629f975": "c88ded2e55071c741ac5cfb52c9b23cd",
".git/objects/91/6cafa2b48158d05cf599ebfa6a1665cfac9e09": "04f567137d4b2c4550716efb7a3b50ab",
".git/objects/91/6a42f3dc21c8bf493d442240d0f3914eef100f": "6a43d7b82e58bce60af289587aaa7236",
".git/objects/65/7dc167fb87d07ce626459663c9684ec4471ca7": "818941c506efa379ca5ba0c1bdbede2b",
".git/objects/30/3d5f923f53681eb69afcb2aa83583b87bd6d2b": "c2fd706ec654fcd2d65f46636c44546b",
".git/objects/37/a9ae53cf59d40e403689bab941b9121701841f": "36d39c3b5c3a992fceb71788591da6c8",
".git/objects/6d/5f0fdc7ccbdf7d01fc607eb818f81a0165627e": "2b2403c52cb620129b4bbc62f12abd57",
".git/objects/6d/14267011d5db9f502bf88626badf7264c002c5": "b2487e27baa88cb7f78ffd89627ac962",
".git/objects/01/59d9fe30ed73801e0ebbc96eadf5b19c829e57": "c169834dc7d4b3b1e05b7392d9d4e648",
".git/objects/39/e24b81a2ddb6581f15df7660f851eb5a3202d9": "2948475e45f0f8a2c8b1b5b3eec73641",
".git/objects/99/c09da512aba363e661fe4a8dce55ce9129060a": "0a9bbdf1873b8875604a3a481c3c37a8",
".git/objects/99/819b66d3fb567bf042f712bbc5165c269e9af8": "8e9c39b8dcd08b2250e570db4bd634a6",
".git/objects/55/b97c62a534441e506f67ffcba3a8aff1442d6f": "fa67c773a7eae3c9a95dc8b25ab3480b",
".git/objects/97/d992cd8c03f2f0eec8f2eb932954ae02c8c124": "9fa4d191bbe7d34672fe2ef1547c7b77",
".git/objects/97/8a4d89de1d1e20408919ec3f54f9bba275d66f": "dbaa9c6711faa6123b43ef2573bc1457",
".git/objects/63/6931bcaa0ab4c3ff63c22d54be8c048340177b": "8cc9c6021cbd64a862e0e47758619fb7",
".git/objects/63/cf5db0316c3bdcefc3f7aaea8e1b7d76a6816b": "6e5829533692b0706d2abb45dfc0981e",
".git/objects/0f/16c7d99f60406d1c259d62755136f4c7f90412": "19fb007e7efad0fed0b81837e7f01a2b",
".git/objects/64/c0271d16bd052ec0c2213b179f9782284957b4": "698b9a27773cf8f64353ed2c3941e2ea",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/3200d2d5beae98d620fd5ce1da0db731d869d9": "d79c109340aa348ffa51554ebb9e0653",
".git/objects/ba/0ee60efad8e6c613d0e51d3ed7abd8d69c8407": "049ea33bc3228a197f75aad8be5c57ab",
".git/objects/ba/5317db6066f0f7cfe94eec93dc654820ce848c": "9b7629bf1180798cf66df4142eb19a4e",
".git/objects/b1/5ad935a6a00c2433c7fadad53602c1d0324365": "8f96f41fe1f2721c9e97d75caa004410",
".git/objects/b1/afd5429fbe3cc7a88b89f454006eb7b018849a": "e4c2e016668208ba57348269fcb46d7b",
".git/objects/d5/b0b3b153810a3364a31cd5bb2de2586b4f2962": "e250ecbaf90480a21e06fd6b362b7fcf",
".git/objects/d5/b3a3154613a393c7989eb4e10f20d421c36709": "67ad9589c56aaaf812e2966f5e29e70e",
".git/objects/d5/60061909c038726190f9ad51691d99056c5883": "5542f240a8c842c152650b85171510e2",
".git/objects/af/31ef4d98c006d9ada76f407195ad20570cc8e1": "a9d4d1360c77d67b4bb052383a3bdfd9",
".git/objects/af/b0690db0ddadadd08ecbcc2f4be0fa7b1742f3": "6088715ac6f0707a639e37b772a43acd",
".git/objects/af/92843978cd0202b6a2e76cc4dc5ec5115d31bd": "eb186ee7c6822aab6a335d2e48029379",
".git/objects/db/b3cc60226b8c1009f34dd6d0533e1e23f98651": "15af9524d664e39a6f548412b724c2e3",
".git/objects/a6/bcc3ce0d8379965480378ea7ec9ee00245d6f1": "52b16513b1aa0fdbe67657265c30a5a4",
".git/objects/c3/e81f822689e3b8c05262eec63e4769e0dea74c": "8c6432dca0ea3fdc0d215dcc05d00a66",
".git/objects/ea/12e0d2dcbfe3a4e05c8fa6521c1941b975ff3a": "2e499acf8abf4526bb42812836cf8762",
".git/objects/ff/8097b84a2b0b70566545b177b244cc701c6858": "419e4c5ae60badf124088f8891e276c8",
".git/objects/ff/781f97f361a76278a78940c0479ee0678f3c75": "f05c610762adede16aa72a2b3786dfff",
".git/objects/f6/e2c11fa5e58020877e364c22855a7cdeb44c87": "2cc3653c04ff7874e88bc3fe8f2d2944",
".git/objects/2c/34cb1323316791f3f89614909c4b935d367e04": "e75ba2beff9e651d90538e4b92fa5aa0",
".git/objects/79/46974767f465cefc79c121b88a498e8592fe30": "07f9784bacbcd09a068722084839408c",
".git/objects/2d/fcdbe9f2df0332cee24295b9c0a4cdbf2478b7": "b40637ed7a305a7a7296f4f96b139cc1",
".git/objects/83/ae873009e64ce43e3e16bb830b80f335023659": "ca305e0cb86205505064863970fe9f72",
".git/objects/48/3806126a1de0259dd93b7c3f1d88ecfac27842": "018687f5f9f86fa409e95d3534bd3e51",
".git/objects/1e/7f5ea5f0146d58da77a97697704aca0b319878": "7619fcfc9984545a24726de9b5601dd0",
".git/objects/4f/346c3e43f95e778d7cef3cb6ceede9cd2bf1c8": "99981890f1649c8ef95c28d9e5a27d4e",
".git/objects/85/423de5276480edd6aa11ba91204da48443e822": "765f9c2c1bab938ec3a71b7d1e34a976",
".git/objects/85/724016ba744ee0aacbd06d16f5a3f40743ba70": "73cc8bacdfe02fb32675c953b77acafc",
".git/objects/85/6a39233232244ba2497a38bdd13b2f0db12c82": "eef4643a9711cce94f555ae60fecd388",
".git/objects/40/48b74d2101847835dc08f270213e84ae2f2a4e": "733b96b3183cf33641b1cc74fe527617",
".git/objects/40/f31994107a484fc9cb63634ac7040b3791377e": "a169eb7c714186571743c4ad0cb04d9c",
".git/objects/2e/c2592d56da1c41fface59f7e09d62e10e34331": "018532f56f6428be1d426c57b75a72b6",
".git/objects/2b/b12257439020a8b416b36c8bf483f5e47dcc86": "178d0525f5b0a92e4ffba687919bf4ad",
".git/objects/78/b1426ddc9486cef4fe64a2cf1f5cc1649b0fe3": "8b85f0f6a8d7163a81b45023f37366d4",
".git/objects/25/7426539865e47cec42669b5f809b7a1acda052": "639448c3182bfd3244d13bceb8f7a480",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "2e4f41793d122be50b8f3658380a52f8",
".git/logs/refs/heads/gh-pages": "dbeaac70b3dfce623cd9349c697992c9",
".git/logs/refs/remotes/origin/gh-pages": "7b84d0654f28fa7599016ab703917b25",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/gh-pages": "495bb7bfd743c2adcb17a7581979099b",
".git/refs/remotes/origin/gh-pages": "495bb7bfd743c2adcb17a7581979099b",
".git/index": "883dc51a17ee3831f6ef1faf448aaaff",
".git/COMMIT_EDITMSG": "b0413b7058a117fc3675f62d4aab623d",
"assets/AssetManifest.json": "5f734c22a2c61e44b4ae0a066411ba65",
"assets/NOTICES": "73950ad1a0764a68a61dc305605d159c",
"assets/FontManifest.json": "f690e1ef038dbabb7823f9ae7f907d48",
"assets/AssetManifest.bin.json": "5b8aee04a1a4249daf363639f550c4cc",
"assets/packages/iamport_flutter/assets/images/iamport-logo.png": "2face5c40217bba082ef64aa5c66e9b6",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "5c59ce0074204d60aca5db4889ade752",
"assets/fonts/MaterialIcons-Regular.otf": "f8befe3f07edf1c8211d0ae10f74eaaf",
"assets/assets/images/arrow.svg": "9c40fdf9fc952852c19163d29243d36e",
"assets/assets/images/soccerball.svg": "24756ae2df7fc700c8adff43b8ddec90",
"assets/assets/images/Restart_icon.svg": "e6e43d74e86d6427e02ebcb6cb821b58",
"assets/assets/images/HomeMainButton.svg": "9a2ac381595d2133fe3f99d5a201e2c1",
"assets/assets/images/AppIcon_talkbingo.png": "121c06bf3f49bbe3b9b7a10dfed2bc7b",
"assets/assets/images/logo_36.png": "0ea564b60545bb5caaff7aead58633e2",
"assets/assets/images/HomeMainButton2.svg": "e9251ef0382f08769e00e7ca4dd2342e",
"assets/assets/images/Targetboard.svg": "78c289c274cd70b7f201e52b0bf54ebc",
"assets/assets/images/logo_24.png": "cd7ebbefdcc46325b854cfb4357a7416",
"assets/assets/images/Bow.svg": "10f3e6232ce0808cb2177b2053d27137",
"assets/assets/images/Goalkeeper.svg": "8d8a743cdd113534b65c75b54df3711b",
"assets/assets/images/open_icon.svg": "1ff995078412cb1bea44c43b8ac6b43a",
"assets/assets/images/Setting.svg": "afa85022424c54129464f04aacb70429",
"assets/assets/images/save_icon.svg": "d947c806e90b798f3125515d1f9febc0",
"assets/assets/images/Bow_2.svg": "688ad265ac84c7fc6f56f26d9565b7da",
"assets/assets/images/Notice.svg": "ba9d9be78ce95680cf4dc93bc8d25fb0",
"assets/assets/images/TalkBingo_AppIcon.png": "d87c7cef3052f0d0253bb0ab951aad2f",
"assets/assets/images/End_icon.svg": "f2f95de57ec31bd1c4b6079ad7a40f7d",
"assets/assets/images/logo_vector.svg": "84e9d3fc5105ea4c5d7944ca23279b16",
"assets/assets/images/logo_48.png": "5aaccc33ab2b71199169c1106fd878e7",
"assets/assets/images/pause_icon.svg": "dbe0d9d917a5c90da411b5198ddc1115",
"assets/assets/images/google_logo.svg": "9d1505ce71a16305b4c5d68511fe463c",
"assets/assets/images/PointPlus.svg": "a99c37f782179c793688688d8385ac32",
"assets/assets/images/open_icon.png": "3de7736ff83a4ea9b09931f42c4b4e72",
"assets/assets/images/play_icon.svg": "56c46b0acb1b60acf8e793506c7bc1d4",
"assets/assets/audio/thock_mid.wav": "2ee27b2d2f285fa795dc4f413e8eb835",
"assets/assets/audio/thock_low.wav": "df1076a3ec9abbbe7aa7361fa04291b1",
"assets/assets/audio/typing_high.wav": "31e1803e3ecaeecc56f05be133a29247",
"assets/assets/audio/thock_high.wav": "e27e5c2e177dec6ae619eb941b528220",
"assets/assets/audio/typing_mid.wav": "dd54b5b28e322597d72ecdb008a9900e",
"assets/assets/audio/disabled.wav": "6dc8fc17062320dc77973472cdc7169f",
"assets/assets/fonts/Nura%2520Normal.ttf": "e711293a5915f25961d14f286c8d81e7",
"assets/assets/fonts/Nura%2520ExtraBold.ttf": "c4d6d8ac4490b402c8b4b150f74fd123",
"assets/assets/fonts/EliceDigitalBaeum_Bold.ttf": "59af972a5ac77204d2c382b09180ab60",
"assets/assets/fonts/Nura%2520Bold.ttf": "b1f4e04d3b2e90ffec5acee63290e57d",
"assets/assets/fonts/Nura%2520Light.ttf": "71f3e878e878c01fb4bf0ff018d03870",
"assets/assets/fonts/EliceDigitalBaeum_Regular.ttf": "281cb68d44cde40dea399119199cfc67",
"privacy.html": "171f03bcc95a2e73c3b4e9f54c4c7e82",
"terms_en.html": "c5ab5a81e46273dea0ffc72b9554efa0",
"guide_bingo_en.html": "93b798048a1aabf41ab42c0864272e80",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c"};
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
