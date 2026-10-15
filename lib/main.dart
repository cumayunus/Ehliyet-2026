import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
void main(){runApp(MaterialApp(home:QuizApp(),debugShowCheckedModeBanner:false));}
class Question{
  final int id; final String qTr,qAr; final List<String> oTr,oAr; final int correct; final String image;
  Question({required this.id,required this.qTr,required this.qAr,required this.oTr,required this.oAr,required this.correct,required this.image});
  factory Question.fromJson(Map<String,dynamic> j){return Question(id:j['id'],qTr:j['q_tr'],qAr:j['q_ar'],oTr:List<String>.from(j['options_tr']),oAr:List<String>.from(j['options_ar']),correct:j['correct'],image:j['image']??"");}
}
class QuizApp extends StatefulWidget{@override _QuizAppState createState()=>_QuizAppState();}
class _QuizAppState extends State<QuizApp>{
  bool isArabic=true; List<Question> allQs=[]; bool loading=true;
  @override void initState(){super.initState();loadQs();}
  Future<void> loadQs() async {final d=await rootBundle.loadString('assets/questions.json'); final List l=jsonDecode(d); setState((){allQs=l.map((e)=>Question.fromJson(e)).toList();loading=false;});}
  @override Widget build(BuildContext context){
    if(loading) return Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(
      appBar:AppBar(title:Text(isArabic?'رخصة 2026 - ${allQs.length} سؤال':'Ehliyet ${allQs.length} Soru'),actions:[TextButton(onPressed:(){setState(()=>isArabic=!isArabic);},child:Text(isArabic?'TR':'العربية',style:TextStyle(color:Colors.white)))]),
      body:ListView(padding:EdgeInsets.all(16),children:[
        Card(child:ListTile(title:Text(isArabic?'عدد الاسئلة: ${allQs.length}':'Soru: ${allQs.length}'))),
        SizedBox(height:12),
        ElevatedButton(onPressed:(){Navigator.push(context,MaterialPageRoute(builder:(_)=>ExamScreen(allQs:allQs.take(50).toList(),isArabic:isArabic)));},child:Text(isArabic?'امتحان 50 سؤال':'50 Soruluk Sinav')),
        ElevatedButton(onPressed:(){Navigator.push(context,MaterialPageRoute(builder:(_)=>ExamScreen(allQs:allQs,isArabic:isArabic)));},child:Text(isArabic?'الكل 600 سؤال':'600 Soruluk Sinav')),
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
        if(q.image.isNotEmpty) Container(height:170,margin:EdgeInsets.all(12),width:double.infinity,child:Image.asset('assets/images/${q.image}',errorBuilder:(c,e,s)=>Container(color:Colors.grey[200],child:Icon(Icons.image,size:50)))),
        Padding(padding:EdgeInsets.all(12),child:Text(widget.isArabic?q.qAr:q.qTr,style:TextStyle(fontSize:18,fontWeight:FontWeight.bold),textAlign:TextAlign.center)),
       ...List.generate(4,(i){final t=widget.isArabic?q.oAr[i]:q.oTr[i]; return Card(child:RadioListTile(value:i,groupValue:ans[idx],title:Text(t),onChanged:(v){setState(()=>ans[idx]=v as int);}));}),
        Spacer(),
        Padding(padding:EdgeInsets.all(12),child:Row(children:[
          Expanded(child:ElevatedButton(onPressed:idx>0?()=>setState(()=>idx--):null,child:Text(widget.isArabic?'رجوع':'Geri'))),
          SizedBox(width:12),
          Expanded(child:ElevatedButton(onPressed:(){if(idx<widget.allQs.length-1) setState(()=>idx++); else{int co=0;for(int j=0;j<widget.allQs.length;j++) if(ans[j]==widget.allQs[j].correct) co++;showDialog(context:context,builder:(_)=>AlertDialog(title:Text(widget.isArabic?'النتيجة':'Sonuc'),content:Text('$co/${widget.allQs.length}'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text('OK'))]));}},child:Text(idx==widget.allQs.length-1?(widget.isArabic?'إنهاء':'Bitir'):(widget.isArabic?'التالي':'Ileri')))),
        ]))
      ]),
    );
  }
}