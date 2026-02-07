import 'package:flutter/material.dart';

class KeyboardAwareFormContainer extends StatelessWidget {
  final Widget child;

  const KeyboardAwareFormContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}
