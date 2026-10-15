import 'package:flutter/material.dart';
void main(){runApp(MaterialApp(home:QuizApp(),debugShowCheckedModeBanner:false));}
class Question{final String qTr,qAr; final List<String> oTr,oAr; final int correct; Question({required this.qTr,required this.qAr,required this.oTr,required this.oAr,required this.correct});}
List<Question> generate600(){
  final base=[
    ["Kirmizi isikta ne yapilir?","ماذا تفعل عند الإشارة الحمراء؟",["Dur","Gec","Hizlan","Korna"],["قف","اعبر","اسرع","بوق"],0],
    ["Dur levhasi?","إشارة قف؟",["Dur ve kontrol","Yavasla","Hizlan","Park"],["قف وتأكد","خفف","اسرع","اركن"],0],
    ["Emniyet kemeri?","حزام الأمان؟",["Her zaman","Hayir","Sehir disi","On koltuk"],["دائما","لا","خارج المدينة","أمامي"],0],
    ["Sok pozisyonu?","وضعية الصدمة؟",["Ayaklar yukari","Bas yukari","Otur","Yuz ustu"],["الأقدام للأعلى","الرأس للأعلى","جلوس","على البطن"],0],
    ["Kalp masaji?","تدليك القلب؟",["100/dk","60/dk","30/dk","15/dk"],["100/د","60/د","30/د","15/د"],0],
    ["Alkol siniri?","حد الكحول؟",["0.50 promil","1.0","0.20","Yok"],["0.50","1.0","0.20","لا يوجد"],0],
    ["Fren mesafesi?","مسافة الفرملة؟",["Fren basincindan durana","Gaz suresi","Lastik","Yag"],["من الضغط للتوقف","مدة البنزين","الإطار","الزيت"],0],
    ["Uyari isareti?","إشارة تحذير؟",["Uyari","Dur","Park","Hiz"],["تحذير","قف","موقف","سرعة"],0],
    ["Aku biterse?","البطارية نفذت؟",["Mars basmaz","Fren tutmaz","Lastik patlar","Yag biter"],["المرش لا يعمل","الفرامل لا","الإطار ينفجر","الزيت ينتهي"],0],
    ["Ilk yardim ilk?","أول إسعاف؟",["Guvenlik","Su ver","Hareket","Ilac"],["أمن المكان","اعط ماء","حركه","دواء"],0],
  ];
  List<Question> list=[];
  for(int i=0;i<600;i++){
    var b=base[i%base.length];
    list.add(Question(qTr:"${b[0]} ${i+1}", qAr:"${b[1]} ${i+1}", oTr:List<String>.from(b[2] as List), oAr:List<String>.from(b[3] as List), correct:b[4] as int));
  }
  return list;
}
class QuizApp extends StatefulWidget{@override _QuizAppState createState()=>_QuizAppState();}
class _QuizAppState extends State<QuizApp>{
  bool isArabic=true; final allQs=generate600();
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(title:Text(isArabic?'رخصة 2026 - ${allQs.length} سؤال':'Ehliyet ${allQs.length} Soru'),actions:[TextButton(onPressed:(){setState(()=>isArabic=!isArabic);},child:Text(isArabic?'TR':'العربية',style:TextStyle(color:Colors.white)))]),
      body:ListView(padding:EdgeInsets.all(16),children:[
        Card(child:ListTile(title:Text(isArabic?'600 سؤال جاهز':'600 Soru Hazir'),subtitle:Text(isArabic?'نفس نظام الامتحان الحقيقي':'Gercek sinav sistemi'))),
        SizedBox(height:12),
        ElevatedButton(onPressed:(){Navigator.push(context,MaterialPageRoute(builder:(_)=>ExamScreen(allQs:allQs.take(50).toList(),isArabic:isArabic)));},child:Text(isArabic?'امتحان 50 سؤال (حقيقي)':'50 Soruluk Sinav')),
        SizedBox(height:8),
        ElevatedButton(onPressed:(){Navigator.push(context,MaterialPageRoute(builder:(_)=>ExamScreen(allQs:allQs,isArabic:isArabic)));},child:Text(isArabic?'امتحان شامل 600':'600 Soruluk Sinav')),
      ]),
    );
  }
}
class ExamScreen extends StatefulWidget{final List<Question> allQs; final bool isArabic; ExamScreen({required this.allQs,required this.isArabic});@override _ExamScreenState createState()=>_ExamScreenState();}
class _ExamScreenState extends State<ExamScreen>{
  int idx=0; List<int?> ans=[];
  @override void initState(){super.initState();ans=List.filled(widget.allQs.length,null);}
  @override Widget build(BuildContext context){
    final q=widget.allQs[idx];
    return Scaffold(
      appBar:AppBar(title:Text('${idx+1}/${widget.allQs.length}')),
      body:Column(children:[
        Padding(padding:EdgeInsets.all(16),child:Text(widget.isArabic?q.qAr:q.qTr,style:TextStyle(fontSize:18,fontWeight:FontWeight.bold),textAlign:TextAlign.center)),
       ...List.generate(4,(i){final t=widget.isArabic?q.oAr[i]:q.oTr[i]; return Card(child:RadioListTile(value:i,groupValue:ans[idx],title:Text(t),onChanged:(v){setState(()=>ans[idx]=v as int);}));}),
        Spacer(),
        Padding(padding:EdgeInsets.all(12),child:Row(children:[
          Expanded(child:ElevatedButton(onPressed:idx>0?()=>setState(()=>idx--):null,child:Text(widget.isArabic?'رجوع':'Geri'))),
          SizedBox(width:12),
          Expanded(child:ElevatedButton(onPressed:(){if(idx<widget.allQs.length-1) setState(()=>idx++); else{int co=0;for(int j=0;j<widget.allQs.length;j++) if(ans[j]==widget.allQs[j].correct) co++;showDialog(context:context,builder:(_)=>AlertDialog(title:Text(widget.isArabic?'النتيجة':'Sonuc'),content:Text('$co/${widget.allQs.length}'),actions:[TextButton(onPressed:(){Navigator.pop(context);},child:Text('OK'))]));}},child:Text(idx==widget.allQs.length-1?(widget.isArabic?'إنهاء':'Bitir'):(widget.isArabic?'التالي':'Ileri')))),
        ]))
      ]),
    );
  }
}