import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(CumaSinavApp());
}

class CumaSinavApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUMA SINAV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red, fontFamily: 'Roboto'),
      home: AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    VideoSayfasi(),
    SinavSayfasi(),
    AdminSayfasi(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CUMA SINAV 2026', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.red[700],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Dersler'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Sinav'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Ogretmen'),
        ],
      ),
    );
  }
}

// 1. VIDEO SAYFASI - Firestore'dan cekiyor
class VideoSayfasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videolar').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Henuz video eklenmedi. Ogretmen panelinden ekleyin.'));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(Icons.play_circle, color: Colors.red, size: 40),
                title: Text(doc['baslik']),
                subtitle: Text(doc['aciklama']?? ''),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VideoPlayerEkrani(videoId: doc['youtubeId'], baslik: doc['baslik'])
                  ));
                },
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
  VideoPlayerEkrani({required this.videoId, required this.baslik});
  @override
  _VideoPlayerEkraniState createState() => _VideoPlayerEkraniState();
}

class _VideoPlayerEkraniState extends State<VideoPlayerEkrani> {
  late YoutubePlayerController _controller;
  @override
  void initState() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(autoPlay: true, mute: false),
    );
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.baslik)),
      body: YoutubePlayer(controller: _controller),
    );
  }
}

// 2. SINAV SAYFASI
class SinavSayfasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sorular').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${snapshot.data!.docs.length} Soru Hazir', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SinavBaslat(sorular: snapshot.data!.docs)));
                },
                child: Text('SINAVI BASLAT', style: TextStyle(fontSize: 18, color: Colors.white)),
              )
            ],
          ),
        );
      },
    );
  }
}

class SinavBaslat extends StatefulWidget {
  final List<QueryDocumentSnapshot> sorular;
  SinavBaslat({required this.sorular});
  @override
  _SinavBaslatState createState() => _SinavBaslatState();
}

class _SinavBaslatState extends State<SinavBaslat> {
  int index = 0;
  int dogru = 0;
  @override
  Widget build(BuildContext context) {
    if (index >= widget.sorular.length) {
      return Scaffold(appBar: AppBar(title: Text('Sonuc')), body: Center(child: Text('Sonuc: $dogru / ${widget.sorular.length}', style: TextStyle(fontSize: 30))));
    }
    var soru = widget.sorular[index];
    return Scaffold(
      appBar: AppBar(title: Text('Soru ${index+1}/${widget.sorular.length}')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(soru['soru'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
           ...List.generate((soru['siklar'] as List).length, (i) {
              return Card(
                child: ListTile(
                  title: Text(soru['siklar'][i]),
                  onTap: () {
                    if (i == soru['dogruIndex']) dogru++;
                    setState(() => index++);
                  },
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}

// 3. OGRETMEN PANELI
class AdminSayfasi extends StatefulWidget {
  @override
  _AdminSayfasiState createState() => _AdminSayfasiState();
}

class _AdminSayfasiState extends State<AdminSayfasi> {
  final _baslik = TextEditingController();
  final _youtube = TextEditingController();

  void videoEkle() async {
    if (_baslik.text.isEmpty || _youtube.text.isEmpty) return;
    // youtube linkinden ID al
    String id = YoutubePlayer.convertUrlToId(_youtube.text)?? _youtube.text;
    await FirebaseFirestore.instance.collection('videolar').add({
      'baslik': _baslik.text,
      'youtubeId': id,
      'aciklama': 'Ehliyet Dersi',
      'tarih': FieldValue.serverTimestamp(),
    });
    _baslik.clear();
    _youtube.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video eklendi!')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Ogretmen Paneli', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          TextField(controller: _baslik, decoration: InputDecoration(labelText: 'Video Basligi (orn: Ilk Yardim)')),
          TextField(controller: _youtube, decoration: InputDecoration(labelText: 'Youtube Link veya ID')),
          SizedBox(height: 10),
          ElevatedButton(onPressed: videoEkle, child: Text('VIDEO EKLE')),
          Divider(height: 40),
          Text('Istersen bana de, ben sana soru ekleme paneli de yaparim!'),
        ],
      ),
    );
  }
}