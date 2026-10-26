import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// عدد أسئلة الامتحان الواحد
const int examSize = 50;

// ---------------- اللغات ----------------
const Map<String, Map<String, String>> _t = {
  'tr': {
    'videos': 'Dersler',
    'exam': 'Sinav',
    'teacher': 'Ogretmen',
    'settings': 'Ayarlar',
    'noVideo': 'Henuz video eklenmedi.',
    'ready': 'Soru Hazir',
    'start': 'SINAVI BASLAT',
    'noQuestions': 'Henuz soru eklenmedi.',
    'question': 'Soru',
    'next': 'SONRAKI',
    'finish': 'BITIR',
    'result': 'Sonuc',
    'back': 'GERI DON',
    'language': 'Dil',
    'dark': 'Karanlik mod',
    'best': 'En iyi sonuc',
    'reset': 'Sonucu sifirla',
    'email': 'E-posta',
    'password': 'Sifre',
    'login': 'GIRIS YAP',
    'logout': 'Cikis',
    'loginError': 'Giris basarisiz',
    'addVideo': 'Video ekle',
    'videoTitle': 'Video basligi',
    'ytLink': 'Youtube link veya ID',
    'add': 'EKLE',
    'added': 'Eklendi!',
    'addQuestion': 'Soru ekle',
    'qTr': 'Soru (Turkce)',
    'qAr': 'Soru (Arapca) - istege bagli',
    'optTr': 'Sik',
    'optAr': 'Sik (Arapca)',
    'correct': 'Dogru sik',
    'imageUrl': 'Resim linki (istege bagli)',
    'videoUrl': 'Video linki veya ID (istege bagli)',
    'bulk': 'Toplu soru aktar (JSON)',
    'bulkHint': 'JSON listesini buraya yapistirin',
    'import': 'AKTAR',
    'imported': 'soru aktarildi',
    'error': 'Hata',
    'fillMore': 'Soru ve en az 2 sik gerekli',
  },
  'ar': {
    'videos': 'الدروس',
    'exam': 'الامتحان',
    'teacher': 'المدرّس',
    'settings': 'الإعدادات',
    'noVideo': 'لم تتم إضافة فيديوهات بعد.',
    'ready': 'سؤال جاهز',
    'start': 'ابدأ الامتحان',
    'noQuestions': 'لم تتم إضافة أسئلة بعد.',
    'question': 'سؤال',
    'next': 'التالي',
    'finish': 'إنهاء',
    'result': 'النتيجة',
    'back': 'رجوع',
    'language': 'اللغة',
    'dark': 'الوضع الداكن',
    'best': 'أفضل نتيجة',
    'reset': 'تصفير النتيجة',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'login': 'تسجيل الدخول',
    'logout': 'خروج',
    'loginError': 'فشل تسجيل الدخول',
    'addVideo': 'إضافة فيديو',
    'videoTitle': 'عنوان الفيديو',
    'ytLink': 'رابط يوتيوب أو المعرّف',
    'add': 'إضافة',
    'added': 'تمت الإضافة!',
    'addQuestion': 'إضافة سؤال',
    'qTr': 'السؤال (تركي)',
    'qAr': 'السؤال (عربي) - اختياري',
    'optTr': 'الخيار',
    'optAr': 'الخيار (عربي)',
    'correct': 'الخيار الصحيح',
    'imageUrl': 'رابط الصورة (اختياري)',
    'videoUrl': 'رابط فيديو يوتيوب أو المعرّف (اختياري)',
    'bulk': 'استيراد أسئلة دفعة واحدة (JSON)',
    'bulkHint': 'الصق قائمة JSON هنا',
    'import': 'استيراد',
    'imported': 'سؤال تم استيراده',
    'error': 'خطأ',
    'fillMore': 'السؤال وخياران على الأقل مطلوبة',
  },
};

String t(String k) => _t[appState.lang]?[k] ?? _t['tr']![k] ?? k;

// ---------------- الحالة العامة ----------------
class AppState extends ChangeNotifier {
  String lang = 'tr';
  bool dark = false;
  int best = 0;
  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    lang = _p!.getString('lang') ?? 'tr';
    dark = _p!.getBool('dark') ?? false;
    best = _p!.getInt('best') ?? 0;
  }

  void setLang(String v) {
    lang = v;
    _p?.setString('lang', v);
    notifyListeners();
  }

  void setDark(bool v) {
    dark = v;
    _p?.setBool('dark', v);
    notifyListeners();
  }

  void setBest(int v) {
    best = v;
    _p?.setInt('best', v);
    notifyListeners();
  }
}

final AppState appState = AppState();

List<String> _list(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

// ---------------- main ----------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await appState.load();
  runApp(const CumaSinavApp());
}

class CumaSinavApp extends StatelessWidget {
  const CumaSinavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'CUMA SINAV',
          debugShowCheckedModeBanner: false,
          themeMode: appState.dark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.red, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          builder: (context, child) => Directionality(
            textDirection:
                appState.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: const AnaSayfa(),
        );
      },
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});
  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const VideoSayfasi(),
      const SinavSayfasi(),
      const AdminSayfasi(),
      const AyarlarSayfasi(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUMA SINAV 2026',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.video_library), label: t('videos')),
          NavigationDestination(icon: const Icon(Icons.quiz), label: t('exam')),
          NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings),
              label: t('teacher')),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: t('settings')),
        ],
      ),
    );
  }
}

// ---------------- 1. الدروس ----------------
class VideoSayfasi extends StatelessWidget {
  const VideoSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videolar').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${t('error')}: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) return Center(child: Text(t('noVideo')));
        return ListView(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final baslik = (d['baslik'] ?? '').toString();
            final id = (d['youtubeId'] ?? '').toString();
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading:
                    const Icon(Icons.play_circle, color: Colors.red, size: 40),
                title: Text(baslik),
                subtitle: Text((d['aciklama'] ?? '').toString()),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          VideoPlayerEkrani(videoId: id, baslik: baslik)),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class VideoPlayerEkrani extends StatefulWidget {
  final String videoId;
  final String baslik;
  const VideoPlayerEkrani(
      {super.key, required this.videoId, required this.baslik});
  @override
  State<VideoPlayerEkrani> createState() => _VideoPlayerEkraniState();
}

class _VideoPlayerEkraniState extends State<VideoPlayerEkrani> {
  late YoutubePlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.baslik)),
      body: YoutubePlayer(controller: _c),
    );
  }
}

// ---------------- 2. الامتحان ----------------
class SinavSayfasi extends StatelessWidget {
  const SinavSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sorular').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${t('error')}: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${all.length} ${t('ready')}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (all.isEmpty)
                Text(t('noQuestions'))
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15)),
                  onPressed: () {
                    final qs = List<Map<String, dynamic>>.from(all)
                      ..shuffle(Random());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              QuizSayfasi(sorular: qs.take(examSize).toList())),
                    );
                  },
                  child: Text(t('start'), style: const TextStyle(fontSize: 18)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class QuizSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> sorular;
  const QuizSayfasi({super.key, required this.sorular});
  @override
  State<QuizSayfasi> createState() => _QuizSayfasiState();
}

class _QuizSayfasiState extends State<QuizSayfasi> {
  int index = 0;
  int score = 0;
  int? selected;

  void _next() {
    setState(() {
      index++;
      selected = null;
    });
    if (index >= widget.sorular.length) {
      final pct = (score * 100 / widget.sorular.length).round();
      if (pct > appState.best) appState.setBest(pct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sorular.length;

    if (index >= total) {
      final pct = (score * 100 / total).round();
      return Scaffold(
        appBar: AppBar(title: Text(t('result'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$score / $total', style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text('%$pct',
                  style: TextStyle(
                      fontSize: 28,
                      color: pct >= 70 ? Colors.green : Colors.red)),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('back'))),
            ],
          ),
        ),
      );
    }

    final q = widget.sorular[index];
    final soru = (q['soru'] ?? '').toString();
    final soruAr = (q['soruAr'] ?? '').toString();
    final siklar = _list(q['siklar']);
    final siklarAr = _list(q['siklarAr']);
    final dogru = (q['dogruIndex'] as num?)?.toInt() ?? 0;
    final resim = (q['resim'] ?? '').toString();
    final videoRaw = (q['video'] ?? '').toString().trim();
    final videoId = videoRaw.isEmpty
        ? ''
        : (YoutubePlayer.convertUrlToId(videoRaw) ?? videoRaw);
    final ar = appState.lang == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text('${t('question')} ${index + 1}/$total')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(value: (index + 1) / total),
          const SizedBox(height: 16),
          if (resim.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Image.network(
                resim,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (videoId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuestionVideo(key: ValueKey('v$index'), videoId: videoId),
            ),
          Text(soru,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (ar && soruAr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(soruAr,
                  style: const TextStyle(fontSize: 17, color: Colors.teal)),
            ),
          const SizedBox(height: 16),
          ...List.generate(siklar.length, (i) {
            Color? color;
            if (selected != null) {
              if (i == dogru) {
                color = Colors.green.withOpacity(0.35);
              } else if (i == selected) {
                color = Colors.red.withOpacity(0.35);
              }
            }
            return Card(
              color: color,
              child: ListTile(
                title: Text(siklar[i]),
                subtitle: (ar && i < siklarAr.length && siklarAr[i].isNotEmpty)
                    ? Text(siklarAr[i],
                        style: const TextStyle(color: Colors.teal))
                    : null,
                onTap: selected != null
                    ? null
                    : () {
                        setState(() {
                          selected = i;
                          if (i == dogru) score++;
                        });
                      },
              ),
            );
          }),
          const SizedBox(height: 12),
          if (selected != null)
            FilledButton(
              onPressed: _next,
              child: Text(index == total - 1 ? t('finish') : t('next')),
            ),
        ],
      ),
    );
  }
}

class QuestionVideo extends StatefulWidget {
  final String videoId;
  const QuestionVideo({super.key, required this.videoId});
  @override
  State<QuestionVideo> createState() => _QuestionVideoState();
}

class _QuestionVideoState extends State<QuestionVideo> {
  late YoutubePlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _c, showVideoProgressIndicator: true);
  }
}

// ---------------- 3. لوحة المدرّس ----------------
class AdminSayfasi extends StatefulWidget {
  const AdminSayfasi({super.key});
  @override
  State<AdminSayfasi> createState() => _AdminSayfasiState();
}

class _AdminSayfasiState extends State<AdminSayfasi> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  final _baslik = TextEditingController();
  final _youtube = TextEditingController();

  final _soru = TextEditingController();
  final _soruAr = TextEditingController();
  final List<TextEditingController> _opt =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _optAr =
      List.generate(4, (_) => TextEditingController());
  final _resim = TextEditingController();
  final _video = TextEditingController();
  int _dogru = 0;

  final _bulk = TextEditingController();

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text);
      _pass.clear();
    } catch (e) {
      _snack(t('loginError'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _videoEkle() async {
    if (_baslik.text.trim().isEmpty || _youtube.text.trim().isEmpty) return;
    try {
      final id =
          YoutubePlayer.convertUrlToId(_youtube.text.trim()) ?? _youtube.text.trim();
      await FirebaseFirestore.instance.collection('videolar').add({
        'baslik': _baslik.text.trim(),
        'youtubeId': id,
        'aciklama': 'Ehliyet Dersi',
        'tarih': FieldValue.serverTimestamp(),
      });
      _baslik.clear();
      _youtube.clear();
      _snack(t('added'));
    } catch (e) {
      _snack('${t('error')}: $e');
    }
  }

  Future<void> _soruEkle() async {
    final tr = _opt.map((c) => c.text.trim()).toList();
    final ar = _optAr.map((c) => c.text.trim()).toList();
    final included = <int>[
      for (int i = 0; i < 4; i++)
        if (tr[i].isNotEmpty) i
    ];
    if (_soru.text.trim().isEmpty ||
        included.length < 2 ||
        !included.contains(_dogru)) {
      _snack(t('fillMore'));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('sorular').add({
        'soru': _soru.text.trim(),
        'soruAr': _soruAr.text.trim(),
        'siklar': included.map((i) => tr[i]).toList(),
        'siklarAr': included.map((i) => ar[i]).toList(),
        'dogruIndex': included.indexOf(_dogru),
        'resim': _resim.text.trim(),
        'video': _video.text.trim(),
        'tarih': FieldValue.serverTimestamp(),
      });
      _soru.clear();
      _video.clear();
      _soruAr.clear();
      _resim.clear();
      for (final c in _opt) {
        c.clear();
      }
      for (final c in _optAr) {
        c.clear();
      }
      _snack(t('added'));
    } catch (e) {
      _snack('${t('error')}: $e');
    }
  }

  Future<void> _import() async {
    try {
      final data = jsonDecode(_bulk.text);
      if (data is! List) throw 'JSON list expected';
      final db = FirebaseFirestore.instance;
      var batch = db.batch();
      int pending = 0, n = 0;
      for (final e in data) {
        if (e is! Map) continue;
        final siklar = _list(e['siklar']);
        final soru = (e['soru'] ?? '').toString().trim();
        if (soru.isEmpty || siklar.length < 2) continue;
        batch.set(db.collection('sorular').doc(), {
          'soru': soru,
          'soruAr': (e['soruAr'] ?? '').toString(),
          'siklar': siklar,
          'siklarAr': _list(e['siklarAr']),
          'dogruIndex': (e['dogruIndex'] as num?)?.toInt() ?? 0,
          'resim': (e['resim'] ?? '').toString(),
          'video': (e['video'] ?? '').toString(),
          'tarih': FieldValue.serverTimestamp(),
        });
        n++;
        pending++;
        if (pending == 400) {
          await batch.commit();
          batch = db.batch();
          pending = 0;
        }
      }
      if (pending > 0) await batch.commit();
      _bulk.clear();
      _snack('$n ${t('imported')}');
    } catch (e) {
      _snack('${t('error')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data == null) return _loginForm();
        return _panel(snap.data!);
      },
    );
  }

  Widget _loginForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: t('email')),
          ),
          TextField(
            controller: _pass,
            obscureText: true,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: t('password')),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t('login')),
          ),
        ],
      ),
    );
  }

  Widget _panel(User user) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ListTile(
          leading: const Icon(Icons.verified_user),
          title: Text(user.email ?? ''),
          trailing: TextButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: Text(t('logout')),
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text(t('addVideo')),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              TextField(
                  controller: _baslik,
                  decoration: InputDecoration(labelText: t('videoTitle'))),
              TextField(
                  controller: _youtube,
                  decoration: InputDecoration(labelText: t('ytLink'))),
              const SizedBox(height: 10),
              FilledButton(onPressed: _videoEkle, child: Text(t('add'))),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text(t('addQuestion')),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              TextField(
                  controller: _soru,
                  maxLines: null,
                  decoration: InputDecoration(labelText: t('qTr'))),
              TextField(
                  controller: _soruAr,
                  maxLines: null,
                  decoration: InputDecoration(labelText: t('qAr'))),
              for (int i = 0; i < 4; i++) ...[
                TextField(
                    controller: _opt[i],
                    decoration:
                        InputDecoration(labelText: '${t('optTr')} ${i + 1}')),
                TextField(
                    controller: _optAr[i],
                    decoration: InputDecoration(
                        labelText: '${t('optAr')} ${i + 1}')),
              ],
              TextField(
                  controller: _resim,
                  decoration: InputDecoration(labelText: t('imageUrl'))),
              TextField(
                  controller: _video,
                  decoration: InputDecoration(labelText: t('videoUrl'))),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _dogru,
                decoration: InputDecoration(labelText: t('correct')),
                items: List.generate(
                    4,
                    (i) => DropdownMenuItem(
                        value: i, child: Text('${i + 1}'))),
                onChanged: (v) => setState(() => _dogru = v ?? 0),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: _soruEkle, child: Text(t('add'))),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text(t('bulk')),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              TextField(
                controller: _bulk,
                maxLines: 8,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                    hintText: t('bulkHint'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: _import, child: Text(t('import'))),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- 4. الإعدادات ----------------
class AyarlarSayfasi extends StatelessWidget {
  const AyarlarSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t('language'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tr', label: Text('Türkçe')),
                ButtonSegment(value: 'ar', label: Text('العربية')),
              ],
              selected: {appState.lang},
              onSelectionChanged: (s) => appState.setLang(s.first),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t('dark')),
              value: appState.dark,
              onChanged: appState.setDark,
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t('best')),
              trailing: Text('%${appState.best}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton(
              onPressed: () => appState.setBest(0),
              child: Text(t('reset')),
            ),
          ],
        );
      },
    );
  }
}