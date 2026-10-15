import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MyApp());

// ===== MODEL =====
class Q {
  final String qTr;
  final String qAr;
  final List<String> oTr;
  final List<String> oAr;
  final int a;
  final String? image; // صورة اختيارية
  Q({required this.qTr, required this.qAr, required this.oTr, required this.oAr, required this.a, this.image});
}

final List<Q> qs = [
  Q(qTr: 'Kırmızı ışıkta ne yapılır?', qAr: 'ماذا تفعل عند الإشارة الحمراء؟', oTr: ['Durulur','Geçilir','Yavaşlanır','Korna'], oAr: ['تتوقف','تمر','تبطئ','تزمّر'], a: 0, image: 'assets/images/red_light.png'),
  Q(qTr: 'Dur levhası ne anlama gelir?', qAr: 'ماذا تعني إشارة قف؟', oTr: ['Geç','Dur ve kontrol et','Hızlan','Geri git'], oAr: ['مرور','قف وتأكد','أسرع','ارجع'], a: 1, image: 'assets/images/stop.png'),
  Q(qTr: 'Emniyet kemeri neden takılır?', qAr: 'لماذا نضع حزام الأمان؟', oTr: ['Süs için','Güvenlik için','Hız için','Yakıt için'], oAr: ['للزينة','للسلامة','للسرعة','للوفر'], a: 1),
  Q(qTr: 'İlkyardımda ilk adım nedir?', qAr: 'ما أول خطوة في الإسعاف الأولي؟', oTr: ['Su vermek','112 yi aramak','Yemek vermek','Uyutmak'], oAr: ['إعطاء ماء','الاتصال بـ 112','إعطاء طعام','جعله ينام'], a: 1),
  Q(qTr: 'Kalp masajı dakikada kaç?', qAr: 'كم ضغطة قلب في الدقيقة؟', oTr: ['100','10','5','200'], oAr: ['100','10','5','200'], a: 0),
  Q(qTr: 'Alkol limiti nedir?', qAr: 'ما حد الكحول المسموح؟', oTr: ['0.50 promil','1.00','2.00','Serbest'], oAr: ['0.50 بروميل','1.00','2.00','مسموح'], a: 0),
  Q(qTr: 'Şok pozisyonu nasıldır?', qAr: 'ما هي وضعية الصدمة؟', oTr: ['Ayaklar yukarı','Baş yukarı','Oturarak','Yüzüstü'], oAr: ['الأقدام للأعلى','الرأس للأعلى','جلوس','على البطن'], a: 0, image: 'assets/images/shock.png'),
  Q(qTr: 'Akü ne üretir?', qAr: 'ماذا تنتج البطارية؟', oTr: ['Elektrik','Su','Benzin','Hava'], oAr: ['كهرباء','ماء','بنزين','هواء'], a: 0),
  Q(qTr: 'Fren mesafesini ne etkiler?', qAr: 'ما الذي يؤثر على مسافة الفرملة؟', oTr: ['Yol durumu','Renk','Müzik','Koku'], oAr: ['حالة الطريق','اللون','الموسيقى','الرائحة'], a: 0),
  Q(qTr: 'Bu işaret ne anlama gelir? (Dikkat)', qAr: 'ماذا تعني هذه الإشارة؟ (انتباه)', oTr: ['Dikkat','Dur','Park yasak','Hız sınırı'], oAr: ['انتباه','قف','ممنوع الوقوف','تحديد سرعة'], a: 0, image: 'assets/images/warning.png'),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ehliyet 2026',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  bool isAr = false;
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isAr? 'رخصة القيادة 2026' : 'Ehliyet 2026 - Offline'), centerTitle: true,
        actions: [TextButton(onPressed: ()=>setState(()=>isAr=!isAr), child: Text(isAr? 'TR' : 'العربية', style: const TextStyle(fontWeight: FontWeight.bold)))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _c(context, isAr? '🚗 ابدأ الامتحان' : '🚗 Sınav Başlat', isAr? '50 سؤال - امتحان حقيقي' : '50 Soru - Gerçek sınav', Colors.blue, isAr),
        _c(context, isAr? '📚 المواضيع' : '📚 Konular', isAr? 'مرور - محرك - إسعاف' : 'Trafik Motor İlkyardım', Colors.green, isAr),
        _c(context, isAr? '⭐ اختبار سريع' : '⭐ Hızlı Test', isAr? 'اختبار 10 أسئلة' : '10 Soruluk test', Colors.orange, isAr),
      ]),
    );
  }
  Widget _c(BuildContext ctx, String t, String s, Color c, bool isAr) {
    return Card(margin: const EdgeInsets.only(bottom:12), child: ListTile(
      leading: Icon(Icons.play_circle, color: c, size:40),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(s),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: ()=>Navigator.push(ctx, MaterialPageRoute(builder: (_)=>Exam(isArabic: isAr))),
    ));
  }
}

class Exam extends StatefulWidget {
  final bool isArabic;
  const Exam({super.key, required this.isArabic});
  @override State<Exam> createState()=>_ExamState();
}
class _ExamState extends State<Exam> {
  late List<Q> q;
  int cur=0;
  List<int?> ans=[];
  late bool isAr;
  @override void initState(){
    super.initState();
    isAr=widget.isArabic;
    q=[...qs]..shuffle(Random());
    q=q.take(10).toList();
    ans=List.filled(q.length,null);
  }
  @override Widget build(BuildContext context){
    final qu=q[cur];
    return Scaffold(
      appBar: AppBar(title: Text('${cur+1}/${q.length}'), actions: [TextButton(onPressed: ()=>setState(()=>isAr=!isAr), child: Text(isAr? 'TR' : 'العربية'))]),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        if(qu.image!= null)
          Container(height: 160, width: double.infinity, margin: const EdgeInsets.only(bottom:12),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.asset(qu.image!, fit: BoxFit.contain, errorBuilder: (_,__,___)=>Icon(Icons.image, size:60, color: Colors.grey)))),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(isAr? qu.qAr : qu.qTr, style: const TextStyle(fontSize:18, fontWeight: FontWeight.bold))),
        const SizedBox(height:20),
       ...List.generate(qu.oTr.length, (i)=>Card(color: ans[cur]==i? Colors.blue.shade100 : null,
          child: RadioListTile(value: i, groupValue: ans[cur], title: Text(isAr? qu.oAr[i] : qu.oTr[i]), onChanged: (v)=>setState(()=>ans[cur]=v)))),
        const Spacer(),
        Row(children: [
          if(cur>0) Expanded(child: ElevatedButton(onPressed: ()=>setState(()=>cur--), child: Text(isAr? 'رجوع' : 'Geri'))),
          const SizedBox(width:10),
          Expanded(child: ElevatedButton(onPressed: (){
            if(cur<q.length-1){setState(()=>cur++);}else{
              int cor=0; for(int i=0;i<q.length;i++){if(ans[i]==q[i].a)cor++;}
              showDialog(context: context, builder: (_)=>AlertDialog(
                title: Text(isAr? 'انتهى!' : 'Bitti!'),
                content: Text(isAr? '$cor / ${q.length} صحيح' : '$cor / ${q.length} Doğru'),
                actions: [TextButton(onPressed: (){Navigator.pop(context); Navigator.pop(context);}, child: Text(isAr? 'حسناً' : 'Tamam'))]));
            }
          }, child: Text(cur==q.length-1? (isAr? 'إنهاء' : 'Bitir') : (isAr? 'التالي' : 'İleri'))))
        ])
      ])),
    );
  }
}