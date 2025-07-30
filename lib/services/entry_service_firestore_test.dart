import 'package:cloud_firestore/cloud_firestore.dart';

class EntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  EntryService();
  
  void test() {
    print('test');
  }
}