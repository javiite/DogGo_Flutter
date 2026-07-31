import 'package:flutter/material.dart';

import 'pets/pet_form_controller.dart';
import 'pets/widgets/pet_form_view.dart';

class RegistrarPerroScreen extends StatefulWidget {
  const RegistrarPerroScreen({super.key});

  @override
  State<RegistrarPerroScreen> createState() =>
      _RegistrarPerroScreenState();
}

class _RegistrarPerroScreenState
    extends State<RegistrarPerroScreen> {
  late final PetFormController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PetFormController()
      ..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PetFormView(
      controller: _controller,
    );
  }
}