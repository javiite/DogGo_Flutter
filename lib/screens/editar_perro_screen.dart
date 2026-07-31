import 'package:flutter/material.dart';

import 'pets/pet_form_controller.dart';
import 'pets/widgets/pet_form_view.dart';

class EditarPerroScreen extends StatefulWidget {
  final Map<String, dynamic> perro;

  const EditarPerroScreen({
    super.key,
    required this.perro,
  });

  @override
  State<EditarPerroScreen> createState() =>
      _EditarPerroScreenState();
}

class _EditarPerroScreenState
    extends State<EditarPerroScreen> {
  late final PetFormController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PetFormController(
      initialData: widget.perro,
    )..initialize();
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