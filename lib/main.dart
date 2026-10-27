import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int examSize = 50;
const int realExamMinutes = 45;
const int passPercent = 70;

class Question {
  const Question({
    required this.id,
    required this.soru,
    this.soruAr = '',
    required this.siklar,
    this.siklarAr = const [],
    required this.dogruIndex,
    this.resim = '',
    this.video = '',
    this.kategori = '',
    this.aciklama = '',
    this.aciklamaAr = '',
  });

  final String id;
  final String soru;
  final String soruAr;
  final List<String> siklar;
  final List<String> siklarAr;
  final int dogruIndex;
  final String resim;
  final String video;
  final String kategori;
  final String aciklama;
  final String aciklamaAr;

  factory Question.fromMap(String id, Map<String, dynamic> map) {
    final rawSiklar = map['siklar'];
    final rawSiklarAr = map['siklarAr'];
    final rawList = rawSiklar is List ? rawSiklar : const <dynamic>[];
    final rawListAr = rawSiklarAr is List ? rawSiklarAr : const <dynamic>[];

    final siklar = rawList
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final siklarAr = rawListAr.map((e) => e.toString()).toList();

    int safeIndex = 0;
    final value = map['dogruIndex'];
    if (value is num) {
      safeIndex = value.toInt();
    }
    if (safeIndex < 0) safeIndex = 0;
    if (siklar.isNotEmpty && safeIndex >= siklar.length) safeIndex = 0;

    return Question(
      id: id,
      soru: (map['soru'] ?? '').toString().trim(),
      soruAr: (map['soruAr'] ?? '').toString(),
      siklar: siklar,
      siklarAr: siklarAr,
      dogruIndex: safeIndex,
      resim: (map['resim'] ?? '').toString().trim(),
      video: (map['video'] ?? '').toString().trim(),
      kategori: (map['kategori'] ?? '').toString().trim(),
      aciklama: (map['aciklama'] ?? '').toString(),
      aciklamaAr: (map['aciklamaAr'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'soru': soru,
        'soruAr': soruAr,
        'siklar': siklar,
        'siklarAr': siklarAr,
        'dogruIndex': dogruIndex,
        'resim': resim,
        'video': video,
        'kategori': kategori,
        'aciklama': aciklama,
        'aciklamaAr': aciklamaAr,
      };
}

enum ExamMode { practice, real }

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
    'practice': 'Pratik',
    'realExam': 'Gercek sinav',
    'examMode': 'Sinav modu',
    'flag': 'Isaretle',
    'removeFlag': 'Isareti kaldir',
    'category': 'Kategori',
    'all': 'Hepsi',
    'wrongAnswers': 'Yanlislar',
    'retryWrong': 'Yanlislari tekrar et',
    'failed': 'Basarisiz',
    'passed': 'Gecti',
    'statistics': 'Istatistik',
    'favorites': 'Favoriler',
    'mistakes': 'Hatalarım',
    'avg': 'Ortalama',
    'bestShort': 'En iyi',
    'trend': 'Egilim',
    'timeLeft': 'Kalan sure',
    'confirmFinish': 'Sinavi bitirmek istiyor musunuz?',
    'explanation': 'Aciklama',
    'yourAnswer': 'Cevabiniz',
    'correctAnswer': 'Dogru cevap',
    'questionGrid': 'Soru ızgarası',
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
    'practice': 'تمرين',
    'realExam': 'امتحان حقيقي',
    'examMode': 'وضع الامتحان',
    'flag': 'علامة',
    'removeFlag': 'إزالة العلامة',
    'category': 'الفئة',
    'all': 'الكل',
    'wrongAnswers': 'الإجابات الخاطئة',
    'retryWrong': 'إعادة الإجابات الخاطئة',
    'failed': 'فشل',
    'passed': 'نجح',
    'statistics': 'الإحصاءات',
    'favorites': 'المفضلة',
    'mistakes': 'أخطائي',
    'avg': 'المتوسط',
    'bestShort': 'الأفضل',
    'trend': 'الاتجاه',
    'timeLeft': 'الوقت المتبقي',
    'confirmFinish': 'هل تريد إنهاء الامتحان؟',
    'explanation': 'التوضيح',
    'yourAnswer': 'إجابتك',
    'correctAnswer': 'الإجابة الصحيحة',
    'questionGrid': 'شبكة الأسئلة',
  },
};

String t(String k) => _t[appState.lang]?[k] ?? _t['tr']![k] ?? k;

class AppState extends ChangeNotifier {
  String lang = 'tr';
  bool dark = false;
  int best = 0;
  SharedPreferences? _p;
  List<Map<String, dynamic>> examHistory = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> favoriteQuestions = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> mistakes = <Map<String, dynamic>>[];

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    lang = _p!.getString('lang') ?? 'tr';
    dark = _p!.getBool('dark') ?? false;
    best = _p!.getInt('best') ?? 0;

    final historyJson = _p!.getString('exam_history') ?? '[]';
    final favoritesJson = _p!.getString('favorite_questions') ?? '[]';
    final mistakesJson = _p!.getString('mistakes') ?? '[]';

    try {
      final decoded = jsonDecode(historyJson);
      if (decoded is List) {
        examHistory = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      examHistory = <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(favoritesJson);
      if (decoded is List) {
        favoriteQuestions = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      favoriteQuestions = <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(mistakesJson);
      if (decoded is List) {
        mistakes = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      mistakes = <Map<String, dynamic>>[];
    }
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

  Future<void> saveExamResult(int score, int total, int durationSeconds) async {
    final record = <String, dynamic>{
      'date': DateTime.now().toIso8601String(),
      'score': score,
      'total': total,
      'durationSeconds': durationSeconds,
    };
    examHistory.add(record);
    if (examHistory.length > 30) {
      examHistory = examHistory.sublist(examHistory.length - 30);
    }
    final percent = total == 0 ? 0 : ((score * 100) / total).round();
    if (percent > best) {
      best = percent;
      _p?.setInt('best', best);
    }
    await _p?.setString('exam_history', jsonEncode(examHistory));
    notifyListeners();
  }

  double get averageScore {
    if (examHistory.isEmpty) return 0;
    int totalScore = 0;
    int totalQuestions = 0;
    for (final item in examHistory) {
      final score = item['score'];
      final total = item['total'];
      totalScore += score is num ? score.toInt() : 0;
      totalQuestions += total is num ? total.toInt() : 0;
    }
    if (totalQuestions == 0) return 0;
    return (totalScore * 100) / totalQuestions;
  }

  int get recentBest {
    if (examHistory.isEmpty) return 0;
    int maxPct = 0;
    for (final item in examHistory) {
      final score = item['score'];
      final total = item['total'];
      final percent = total is num && total != 0
          ? ((score is num ? score.toInt() : 0) * 100 / total.toInt()).round()
          : 0;
      if (percent > maxPct) maxPct = percent;
    }
    return maxPct;
  }

  Future<void> toggleFavoriteQuestion(Question question) async {
    final map = question.toMap()..['id'] = question.id;
    final index = favoriteQuestions.indexWhere((entry) => entry['id'] == question.id);
    if (index >= 0) {
      favoriteQuestions.removeAt(index);
    } else {
      favoriteQuestions.add(map);
    }
    await _p?.setString('favorite_questions', jsonEncode(favoriteQuestions));
    notifyListeners();
  }

  bool isFavoriteQuestion(String id) =>
      favoriteQuestions.any((entry) => entry['id'] == id);

  Future<void> addMistakeQuestion(Question question) async {
    if (mistakes.any((entry) => entry['id'] == question.id)) return;
    mistakes.add(question.toMap()..['id'] = question.id);
    await _p?.setString('mistakes', jsonEncode(mistakes));
    notifyListeners();
  }
}

final AppState appState = AppState();

List<String> _list(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

String _formatDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _safeCategoryLabel(String value) => value.trim().isEmpty ? 'genel' : value.trim();

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
              seedColor: Colors.red,
              brightness: Brightness.dark,
            ),
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
        title: const Text(
          'CUMA SINAV 2026',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            icon: const Icon(Icons.video_library),
            label: t('videos'),
          ),
          NavigationDestination(icon: const Icon(Icons.quiz), label: t('exam')),
          NavigationDestination(
            icon: const Icon(Icons.admin_panel_settings),
            label: t('teacher'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: t('settings'),
          ),
        ],
      ),
    );
  }
}

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
                leading: const Icon(Icons.play_circle, color: Colors.red, size: 40),
                title: Text(baslik),
                subtitle: Text((d['aciklama'] ?? '').toString()),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerEkrani(videoId: id, baslik: baslik),
                  ),
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
  const VideoPlayerEkrani({
    super.key,
    required this.videoId,
    required this.baslik,
  });

  final String videoId;
  final String baslik;

  @override
  State<VideoPlayerEkrani> createState() => _VideoPlayerEkraniState();
}

class _VideoPlayerEkraniState extends State<VideoPlayerEkrani> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.baslik)),
      body: YoutubePlayer(controller: _controller),
    );
  }
}

class SinavSayfasi extends StatefulWidget {
  const SinavSayfasi({super.key});

  @override
  State<SinavSayfasi> createState() => _SinavSayfasiState();
}

class _SinavSayfasiState extends State<SinavSayfasi> {
  String _category = 'all';
  ExamMode _mode = ExamMode.practice;

  List<Question> _filterQuestions(List<Question> all) {
    if (_category == 'all') return all;
    return all
        .where((question) => question.kategori.toLowerCase() == _category.toLowerCase())
        .toList();
  }

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
            .map((doc) => Question.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        final filtered = _filterQuestions(all);
        final categories = <String>{'all'};
        for (final q in all) {
          if (q.kategori.isNotEmpty) categories.add(q.kategori);
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${filtered.length} ${t('ready')}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                SegmentedButton<ExamMode>(
                  segments: const [
                    ButtonSegment<ExamMode>(value: ExamMode.practice, label: Text('Pratik')),
                    ButtonSegment<ExamMode>(value: ExamMode.real, label: Text('Gercek Sinav')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) => setState(() => _mode = value.first),
                ),
                const SizedBox(height: 12),
                if (categories.length > 1)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in categories)
                        ChoiceChip(
                          label: Text(
                            category == 'all' ? t('all') : _safeCategoryLabel(category),
                          ),
                          selected: _category == category,
                          onSelected: (_) => setState(() => _category = category),
                        ),
                    ],
                  ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  Text(t('noQuestions'))
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: () {
                      final qs = List<Question>.from(filtered)..shuffle(Random());
                      final questions = qs.take(examSize).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizSayfasi(sorular: questions, mode: _mode),
                        ),
                      );
                    },
                    child: Text(t('start'), style: const TextStyle(fontSize: 18)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuizSayfasi extends StatefulWidget {
  const QuizSayfasi({super.key, required this.sorular, required this.mode});

  final List<Question> sorular;
  final ExamMode mode;

  @override
  State<QuizSayfasi> createState() => _QuizSayfasiState();
}

class _QuizSayfasiState extends State<QuizSayfasi> {
  late final List<int?> _answers;
  late final List<bool> _flagged;
  int _index = 0;
  int _secondsLeft = realExamMinutes * 60;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.sorular.length, null, growable: false);
    _flagged = List<bool>.filled(widget.sorular.length, false, growable: false);
    if (widget.mode == ExamMode.real) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_finished) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_secondsLeft > 0) _secondsLeft--;
          if (_secondsLeft <= 0) {
            _finished = true;
            timer.cancel();
            _finishExam(finishedByTimer: true);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectAnswer(int optionIndex) {
    final question = widget.sorular[_index];
    setState(() {
      _answers[_index] = optionIndex;
    });

    if (widget.mode == ExamMode.practice && optionIndex != question.dogruIndex) {
      appState.addMistakeQuestion(question);
    }
  }

  void _moveTo(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.sorular.length) return;
    setState(() => _index = newIndex);
  }

  void _finishExam({bool finishedByTimer = false}) {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();

    final total = widget.sorular.length;
    int correct = 0;
    final wrong = <Question>[];

    for (int i = 0; i < total; i++) {
      final question = widget.sorular[i];
      final selected = _answers[i];
      if (selected != null && selected == question.dogruIndex) {
        correct++;
      } else if (selected != null) {
        wrong.add(question);
      }
    }

    if (widget.mode == ExamMode.real) {
      final duration = max(1, realExamMinutes * 60 - _secondsLeft);
      appState.saveExamResult(correct, total, duration);
    }

    for (final question in wrong) {
      appState.addMistakeQuestion(question);
    }

    final passed = ((correct * 100) / max(total, 1)).round() >= passPercent;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultSayfasi(
          questions: widget.sorular,
          answers: _answers,
          score: correct,
          total: total,
          durationSeconds: max(1, realExamMinutes * 60 - _secondsLeft),
          passed: passed,
          mode: widget.mode,
          finishedByTimer: finishedByTimer,
        ),
      ),
    );
  }

  void _confirmFinish() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('finish')),
        content: Text(t('confirmFinish')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('back'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishExam();
            },
            child: Text(t('finish')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sorular.length;
    final q = widget.sorular[_index];
    final selected = _answers[_index];
    final ar = appState.lang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text('${t('question')} ${_index + 1}/$total'),
        actions: [
          IconButton(
            icon: Icon(_flagged[_index] ? Icons.flag : Icons.outlined_flag),
            tooltip: _flagged[_index] ? t('removeFlag') : t('flag'),
            onPressed: () => setState(() => _flagged[_index] = !_flagged[_index]),
          ),
          if (widget.mode == ExamMode.practice)
            IconButton(
              icon: Icon(
                appState.isFavoriteQuestion(q.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
              onPressed: () => appState.toggleFavoriteQuestion(q),
            ),
          if (widget.mode == ExamMode.real)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${t('timeLeft')}: ${_formatDuration(_secondsLeft)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(value: (_index + 1) / total),
          const SizedBox(height: 16),
          if (q.kategori.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(_safeCategoryLabel(q.kategori))),
            ),
          if (q.resim.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Image.network(
                q.resim,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (q.video.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuestionVideo(
                key: ValueKey('v${q.id}'),
                videoId: YoutubePlayer.convertUrlToId(q.video) ?? q.video,
              ),
            ),
          Text(q.soru, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (ar && q.soruAr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                q.soruAr,
                style: const TextStyle(fontSize: 17, color: Colors.teal),
              ),
            ),
          const SizedBox(height: 16),
          ...List.generate(q.siklar.length, (i) {
            Color? color;
            if (selected != null && widget.mode == ExamMode.practice) {
              if (i == q.dogruIndex) {
                color = Colors.green.withOpacity(0.35);
              } else if (i == selected) {
                color = Colors.red.withOpacity(0.35);
              }
            }
            return Card(
              color: color,
              child: ListTile(
                title: Text(q.siklar[i]),
                subtitle: (ar && i < q.siklarAr.length && q.siklarAr[i].isNotEmpty)
                    ? Text(q.siklarAr[i], style: const TextStyle(color: Colors.teal))
                    : null,
                onTap: selected != null ? null : () => _selectAnswer(i),
              ),
            );
          }),
          if (widget.mode == ExamMode.practice && selected != null) ...[
            const SizedBox(height: 12),
            if (q.aciklama.isNotEmpty || q.aciklamaAr.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('explanation'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        appState.lang == 'ar' && q.aciklamaAr.isNotEmpty
                            ? q.aciklamaAr
                            : q.aciklama,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _index > 0 ? () => _moveTo(_index - 1) : null,
                  child: const Text('◀'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_index < total - 1) {
                      _moveTo(_index + 1);
                    } else if (widget.mode == ExamMode.real) {
                      _confirmFinish();
                    } else {
                      _finishExam();
                    }
                  },
                  child: Text(_index == total - 1 ? t('finish') : t('next')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(t('questionGrid'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: total,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemBuilder: (context, index) {
                      final isCurrent = index == _index;
                      final hasAnswer = _answers[index] != null;
                      final flagged = _flagged[index];
                      return InkWell(
                        onTap: () => _moveTo(index),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: flagged
                                ? Colors.amber.withOpacity(0.4)
                                : (isCurrent ? Colors.red[100] : Colors.grey[200]),
                            border: Border.all(
                              color: hasAnswer ? Colors.green : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${index + 1}'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizResultSayfasi extends StatelessWidget {
  const QuizResultSayfasi({
    super.key,
    required this.questions,
    required this.answers,
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.passed,
    required this.mode,
    required this.finishedByTimer,
  });

  final List<Question> questions;
  final List<int?> answers;
  final int score;
  final int total;
  final int durationSeconds;
  final bool passed;
  final ExamMode mode;
  final bool finishedByTimer;

  List<Question> _wrongQuestions() {
    final wrong = <Question>[];
    for (int i = 0; i < questions.length; i++) {
      final selected = answers[i];
      if (selected != null && selected != questions[i].dogruIndex) {
        wrong.add(questions[i]);
      }
    }
    return wrong;
  }

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((score * 100) / total).round();
    final wrongQuestions = _wrongQuestions();

    return Scaffold(
      appBar: AppBar(title: Text(t('result'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    '$score / $total',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '%$percent',
                    style: TextStyle(
                      fontSize: 28,
                      color: passed ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed ? t('passed') : t('failed'),
                    style: TextStyle(
                      fontSize: 16,
                      color: passed ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode == ExamMode.real && finishedByTimer
                        ? 'Süre doldu • ${_formatDuration(durationSeconds)}'
                        : _formatDuration(durationSeconds),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (wrongQuestions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Tüm sorular doğru!'),
              ),
            )
          else ...[
            Text(
              t('wrongAnswers'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final question in wrongQuestions) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.lang == 'ar' && question.soruAr.isNotEmpty
                            ? question.soruAr
                            : question.soru,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${t('yourAnswer')}: ${question.siklar[(answers[questions.indexWhere((item) => item.id == question.id)] ?? 0)]}',
                      ),
                      Text('${t('correctAnswer')}: ${question.siklar[question.dogruIndex]}'),
                      if ((appState.lang == 'ar' && question.aciklamaAr.isNotEmpty) ||
                          (appState.lang != 'ar' && question.aciklama.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${t('explanation')}: ${appState.lang == 'ar' && question.aciklamaAr.isNotEmpty ? question.aciklamaAr : question.aciklama}',
                            style: const TextStyle(color: Colors.teal),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          if (wrongQuestions.isNotEmpty)
            FilledButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizSayfasi(
                    sorular: wrongQuestions,
                    mode: ExamMode.practice,
                  ),
                ),
              ),
              child: Text(t('retryWrong')),
            ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('back')),
          ),
        ],
      ),
    );
  }
}

class QuestionVideo extends StatefulWidget {
  const QuestionVideo({super.key, required this.videoId});

  final String videoId;

  @override
  State<QuestionVideo> createState() => _QuestionVideoState();
}

class _QuestionVideoState extends State<QuestionVideo> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _controller, showVideoProgressIndicator: true);
  }
}

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
  final List<TextEditingController> _opt = List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _optAr = List.generate(4, (_) => TextEditingController());
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
        email: _email.text.trim(),
        password: _pass.text,
      );
      _pass.clear();
    } catch (_) {
      _snack(t('loginError'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _videoEkle() async {
    if (_baslik.text.trim().isEmpty || _youtube.text.trim().isEmpty) return;
    try {
      final id = YoutubePlayer.convertUrlToId(_youtube.text.trim()) ?? _youtube.text.trim();
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
      for (int i = 0; i < 4; i++) if (tr[i].isNotEmpty) i,
    ];
    if (_soru.text.trim().isEmpty || included.length < 2 || !included.contains(_dogru)) {
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
        'kategori': 'genel',
        'aciklama': '',
        'aciklamaAr': '',
        'tarih': FieldValue.serverTimestamp(),
      });
      _soru.clear();
      _soruAr.clear();
      _resim.clear();
      _video.clear();
      for (final c in _opt) c.clear();
      for (final c in _optAr) c.clear();
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
      int pending = 0;
      int count = 0;
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
          'kategori': (e['kategori'] ?? 'genel').toString(),
          'aciklama': (e['aciklama'] ?? '').toString(),
          'aciklamaAr': (e['aciklamaAr'] ?? '').toString(),
          'tarih': FieldValue.serverTimestamp(),
        });
        count ++;
        pending ++;
        if (pending == 400) {
          await batch.commit();
          batch = db.batch();
          pending = 0;
        }
      }
      if (pending > 0) await batch.commit();
      _bulk.clear();
      _snack('$count ${t('imported')}');
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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
                decoration: InputDecoration(labelText: t('videoTitle')),
              ),
              TextField(
                controller: _youtube,
                decoration: InputDecoration(labelText: t('ytLink')),
              ),
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
                decoration: InputDecoration(labelText: t('qTr')),
              ),
              TextField(
                controller: _soruAr,
                maxLines: null,
                decoration: InputDecoration(labelText: t('qAr')),
              ),
              for (int i = 0; i < 4; i++) ...[
                TextField(
                  controller: _opt[i],
                  decoration: InputDecoration(labelText: '${t('optTr')} ${i + 1}'),
                ),
                TextField(
                  controller: _optAr[i],
                  decoration: InputDecoration(labelText: '${t('optAr')} ${i + 1}'),
                ),
              ],
              TextField(
                controller: _resim,
                decoration: InputDecoration(labelText: t('imageUrl')),
              ),
              TextField(
                controller: _video,
                decoration: InputDecoration(labelText: t('videoUrl')),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _dogru,
                decoration: InputDecoration(labelText: t('correct')),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(value: i, child: Text('${i + 1}')),
                ),
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
                  hintText: t('bulkHint'),
                  border: const OutlineInputBorder(),
                ),
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
            Text(
              t('language'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
              trailing: Text(
                '%${appState.best}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              onPressed: () => appState.setBest(0),
              child: Text(t('reset')),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(t('statistics')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsSayfasi()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(t('favorites')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesSayfasi()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(t('mistakes')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MistakesSayfasi()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class StatisticsSayfasi extends StatelessWidget {
  const StatisticsSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final avg = appState.averageScore;
    final best = appState.recentBest;
    final totalExams = appState.examHistory.length;
    final trend = totalExams > 1
        ? appState.examHistory.sublist(max(0, totalExams - 3)).fold<int>(0, (sum, item) {
            final score = item['score'];
            final total = item['total'];
            final percent = total is num && total != 0
                ? ((score is num ? score.toInt() : 0) * 100 / total.toInt()).round()
                : 0;
            return sum + percent;
          })
        : 0;

    return Scaffold(
      appBar: AppBar(title: Text(t('statistics'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text(t('avg')),
                trailing: Text('${avg.toStringAsFixed(0)}%'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text(t('bestShort')),
                trailing: Text('$best%'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text(t('trend')),
                trailing: Text('${trend > 0 ? '+' : ''}${(trend / max(totalExams, 1)).round()}%'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Toplam deneme: $totalExams'),
            const SizedBox(height: 12),
            ...appState.examHistory.reversed.map((entry) {
              final score = entry['score'];
              final total = entry['total'];
              final percent = total is num && total != 0
                  ? ((score is num ? score.toInt() : 0) * 100 / total.toInt()).round()
                  : 0;
              final date = DateTime.tryParse(entry['date']?.toString() ?? '') ?? DateTime.now();
              return Card(
                child: ListTile(
                  title: Text('$score / $total'),
                  subtitle: Text('$percent% • ${date.toLocal().toString().split(' ').first}'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class FavoritesSayfasi extends StatelessWidget {
  const FavoritesSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('favorites'))),
      body: appState.favoriteQuestions.isEmpty
          ? const Center(child: Text('Favori soru yok.'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: appState.favoriteQuestions.map((entry) {
                final questionText = (entry['soru'] ?? '').toString();
                return Card(
                  child: ListTile(
                    title: Text(questionText),
                    subtitle: ((entry['kategori'] ?? '').toString()).isNotEmpty
                        ? Text((entry['kategori'] ?? '').toString())
                        : null,
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class MistakesSayfasi extends StatelessWidget {
  const MistakesSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('mistakes'))),
      body: appState.mistakes.isEmpty
          ? const Center(child: Text('Hata kaydı yok.'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: appState.mistakes.map((entry) {
                final questionText = (entry['soru'] ?? '').toString();
                final questionAr = (entry['soruAr'] ?? '').toString();
                return Card(
                  child: ListTile(
                    title: Text(questionText),
                    subtitle: questionAr.isNotEmpty ? Text(questionAr) : null,
                  ),
                );
              }).toList(),
            ),
    );
  }
}
