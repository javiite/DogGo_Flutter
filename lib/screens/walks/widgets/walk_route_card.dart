import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/doggo_theme.dart';
import '../../routes/route_selection_screen.dart';
import '../models/pickup_location.dart';
import '../models/walk_route_selection.dart';

class WalkRouteCard extends StatelessWidget {
  final PickupLocation? pickupLocation;
  final WalkRouteSelection? selection;
  final ValueChanged<WalkRouteSelection?>
      onChanged;

  const WalkRouteCard({
    super.key,
    required this.pickupLocation,
    required this.selection,
    required this.onChanged,
  });

  Future<void> _openSelector(
    BuildContext context,
  ) async {
    final location = pickupLocation;

    if (location == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Primero selecciona el punto '
              'de recogida.',
            ),
          ),
        );

      return;
    }

    final result =
        await Navigator.push<
            WalkRouteSelection>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RouteSelectionScreen(
          initialCenter: LatLng(
            location.latitude,
            location.longitude,
          ),
        ),
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = selection;

    if (current == null) {
      return Material(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(22),
        child: InkWell(
          onTap: () =>
              _openSelector(context),
          borderRadius:
              BorderRadius.circular(22),
          child: Container(
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: DogGoTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:
                        DogGoTheme.tealLight,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: DogGoTheme.teal,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Elegir recorrido',
                        style:
                            DogGoTheme.title(
                          size: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usa una ruta guardada '
                        'o dibuja una nueva.',
                        style:
                            DogGoTheme.subtitle(
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DogGoTheme.muted,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isArea =
        current.controlMode
                .toLowerCase() ==
            'area';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: DogGoTheme.teal,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: DogGoTheme.teal,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Icon(
                  isArea
                      ? Icons
                          .pentagon_outlined
                      : Icons.route_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            current.name,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                DogGoTheme.title(
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          Icons
                              .check_circle_rounded,
                          color:
                              DogGoTheme.teal,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${current.pointCount} puntos'
                      ' · '
                      '${current.checkpointCount} avisos'
                      ' · '
                      '${current.allowedRadiusMeters} m',
                      style:
                          DogGoTheme.caption(
                        size: 10.5,
                        color:
                            DogGoTheme.tealDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openSelector(context),
                  style:
                      OutlinedButton.styleFrom(
                    backgroundColor:
                        DogGoTheme.card,
                  ),
                  icon: const Icon(
                    Icons.edit_road_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Cambiar',
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.outlined(
                tooltip: 'Quitar recorrido',
                onPressed: () =>
                    onChanged(null),
                icon: const Icon(
                  Icons.close_rounded,
                  color: DogGoTheme.red,
                ),
              ),
            ],
          ),
          if (current.saveAsTemplate) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons
                      .bookmark_added_outlined,
                  color: DogGoTheme.teal,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'También se guardará en '
                    'Mis rutas.',
                    style:
                        DogGoTheme.caption(
                      color:
                          DogGoTheme.tealDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}