import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class SearchableLocationField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<T> items;
  final String? value;
  final String Function(T item) valueOf;
  final String Function(T item) labelOf;
  final ValueChanged<String?>? onChanged;
  final String? Function(String? value)? validator;

  const SearchableLocationField({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.valueOf,
    required this.labelOf,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => valueOf(item) == value).firstOrNull;

    return FormField<String>(
      key: ValueKey('$label-$value-${items.length}'),
      initialValue: value,
      validator: validator,
      builder: (field) => InkWell(
        onTap: onChanged == null
            ? null
            : () async {
                final result = await _showPicker(context);
                if (result == null) return;
                field.didChange(result);
                onChanged!(result);
              },
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          isEmpty: selected == null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
            errorText: field.errorText,
            enabled: onChanged != null,
          ),
          child: Text(
            selected == null ? 'Seleccionar' : labelOf(selected),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              color: selected == null ? DogGoTheme.muted : DogGoTheme.ink,
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showPicker(BuildContext context) {
    var query = '';
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: DogGoTheme.card,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) {
          final normalized = query.trim().toLowerCase();
          final filtered = items
              .where(
                (item) =>
                    normalized.isEmpty ||
                    labelOf(item).toLowerCase().contains(normalized),
              )
              .toList(growable: false);

          return FractionallySizedBox(
            heightFactor: .72,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DogGoTheme.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar $label',
                        style: DogGoTheme.title(size: 21),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        onChanged: (value) => update(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar $label',
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No encontramos coincidencias.',
                            style: DogGoTheme.subtitle(),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final itemValue = valueOf(item);
                            final selected = itemValue == value;
                            return ListTile(
                              title: Text(labelOf(item)),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: DogGoTheme.teal,
                                    )
                                  : null,
                              onTap: () =>
                                  Navigator.pop(sheetContext, itemValue),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
