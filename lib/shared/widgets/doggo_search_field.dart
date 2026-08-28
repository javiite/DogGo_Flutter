import 'package:flutter/material.dart';

import '../../theme/doggo_theme.dart';

class DogGoSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool hasValue;

  const DogGoSearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.hasValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: hintText,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: hasValue
              ? IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: DogGoTheme.card,
        ),
      ),
    );
  }
}
