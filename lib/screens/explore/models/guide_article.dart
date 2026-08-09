import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class GuideArticle {
  final int id;
  final String title;
  final String summary;
  final String category;
  final int readMinutes;
  final IconData icon;
  final Color color;
  final Color background;
  final bool featured;
  final List<GuideSection> sections;
  final List<String> quickTips;

  const GuideArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.readMinutes,
    required this.icon,
    required this.color,
    required this.background,
    required this.sections,
    required this.quickTips,
    this.featured = false,
  });
}

class GuideSection {
  final String title;
  final String content;

  const GuideSection({
    required this.title,
    required this.content,
  });
}

const List<GuideArticle> dogGoGuideArticles = [
  GuideArticle(
    id: 1,
    title: 'Prepara el primer paseo',
    summary:
        'Ayuda a tu mascota a conocer a su paseador y comenzar con una experiencia segura.',
    category: 'Paseos',
    readMinutes: 5,
    icon: Icons.directions_walk_rounded,
    color: DogGoTheme.teal,
    background: DogGoTheme.tealLight,
    featured: true,
    sections: [
      GuideSection(
        title: 'Antes de la presentación',
        content:
            'Comparte información sobre el temperamento de tu mascota, sus miedos, nivel de energía y comportamiento frente a otros perros. Entre más información tenga el paseador, mejor podrá anticiparse.',
      ),
      GuideSection(
        title: 'Prepara su equipo',
        content:
            'Revisa que la correa, el collar o arnés estén en buenas condiciones. La placa debe incluir información de contacto actualizada. También prepara bolsas y agua suficiente.',
      ),
      GuideSection(
        title: 'El primer encuentro',
        content:
            'Permite que tu perro se acerque a su ritmo. Evita forzar el contacto y realiza una caminata corta de presentación antes de dejar que comience el paseo completo.',
      ),
    ],
    quickTips: [
      'Informa si tu perro intenta escapar.',
      'Explica qué premios puede consumir.',
      'Comparte el contacto de su veterinario.',
      'Indica las rutas o zonas que deben evitarse.',
    ],
  ),
  GuideArticle(
    id: 2,
    title: 'Paseos en días calurosos',
    summary:
        'Evita quemaduras, deshidratación y golpes de calor durante el recorrido.',
    category: 'Salud',
    readMinutes: 4,
    icon: Icons.wb_sunny_outlined,
    color: DogGoTheme.orange,
    background: DogGoTheme.orangeLight,
    sections: [
      GuideSection(
        title: 'Elige un horario adecuado',
        content:
            'Durante temporadas cálidas es preferible caminar temprano por la mañana o al atardecer. Evita las horas con mayor intensidad solar.',
      ),
      GuideSection(
        title: 'Revisa el pavimento',
        content:
            'Coloca el dorso de tu mano sobre el suelo durante algunos segundos. Si no puedes mantenerla ahí cómodamente, el pavimento puede lastimar las almohadillas.',
      ),
      GuideSection(
        title: 'Identifica señales de alerta',
        content:
            'Jadeo excesivo, debilidad, encías muy rojas, desorientación o falta de coordinación son señales para detener inmediatamente el paseo y buscar ayuda.',
      ),
    ],
    quickTips: [
      'Lleva siempre agua potable.',
      'Busca recorridos con sombra.',
      'Evita ejercicios demasiado intensos.',
      'Nunca dejes al perro dentro de un automóvil.',
    ],
  ),
  GuideArticle(
    id: 3,
    title: 'Seguridad durante el recorrido',
    summary:
        'Buenas prácticas para mantener un seguimiento responsable durante cada paseo.',
    category: 'Seguridad',
    readMinutes: 6,
    icon: Icons.verified_user_outlined,
    color: DogGoTheme.green,
    background: DogGoTheme.greenLight,
    sections: [
      GuideSection(
        title: 'Mantén la comunicación',
        content:
            'El chat del paseo debe utilizarse para informar cambios importantes, retrasos, pausas o cualquier situación que pueda preocupar al dueño.',
      ),
      GuideSection(
        title: 'Seguimiento de ubicación',
        content:
            'La ubicación permite confirmar el recorrido y detectar cambios inesperados. El paseador debe conservar activos los permisos necesarios mientras el paseo esté en curso.',
      ),
      GuideSection(
        title: 'Evidencias del servicio',
        content:
            'Las fotografías de inicio y final ayudan a comprobar las condiciones de entrega. Deben tomarse durante el servicio y representar claramente a la mascota.',
      ),
    ],
    quickTips: [
      'No retires la correa en espacios abiertos.',
      'Evita calles con tráfico intenso.',
      'Respeta la ruta acordada.',
      'Reporta cualquier incidente inmediatamente.',
    ],
  ),
  GuideArticle(
    id: 4,
    title: 'Cuidados después del paseo',
    summary:
        'Revisa a tu mascota y ayúdala a recuperarse correctamente al regresar.',
    category: 'Salud',
    readMinutes: 4,
    icon: Icons.favorite_border_rounded,
    color: DogGoTheme.red,
    background: DogGoTheme.redLight,
    sections: [
      GuideSection(
        title: 'Hidratación y descanso',
        content:
            'Ofrece agua fresca y permite que tu mascota descanse. Evita servir una gran cantidad de alimento inmediatamente después de actividad intensa.',
      ),
      GuideSection(
        title: 'Revisión rápida',
        content:
            'Observa las almohadillas, patas, uñas y pelaje. Busca pequeñas heridas, espinas, irritación o parásitos que pudiera haber recogido durante el camino.',
      ),
      GuideSection(
        title: 'Registra la experiencia',
        content:
            'Consulta la ruta y las evidencias, conversa con el paseador si tienes dudas y deja una calificación que ayude a mejorar la comunidad.',
      ),
    ],
    quickTips: [
      'Limpia sus patas si es necesario.',
      'Observa si presenta dolor o cansancio inusual.',
      'Consulta las evidencias del paseo.',
      'Califica al paseador de forma honesta.',
    ],
  ),
  GuideArticle(
    id: 5,
    title: 'Cómo elegir un buen arnés',
    summary:
        'Conoce las características que ayudan a caminar con seguridad y comodidad.',
    category: 'Equipo',
    readMinutes: 5,
    icon: Icons.health_and_safety_outlined,
    color: DogGoTheme.purple,
    background: DogGoTheme.purpleLight,
    sections: [
      GuideSection(
        title: 'Talla y ajuste',
        content:
            'El arnés debe quedar firme sin limitar el movimiento. Como referencia, deben caber aproximadamente dos dedos entre el arnés y el cuerpo.',
      ),
      GuideSection(
        title: 'Materiales',
        content:
            'Busca materiales resistentes, suaves en las zonas de contacto y fáciles de limpiar. Las costuras y broches deben soportar los movimientos del perro.',
      ),
      GuideSection(
        title: 'Punto de sujeción',
        content:
            'Los arneses pueden tener sujeción frontal o superior. La mejor opción depende de la fuerza, entrenamiento y forma de caminar de cada mascota.',
      ),
    ],
    quickTips: [
      'Revisa periódicamente costuras y broches.',
      'No utilices un arnés demasiado holgado.',
      'Adapta gradualmente al perro.',
      'Consulta a un profesional si tira demasiado.',
    ],
  ),
  GuideArticle(
    id: 6,
    title: 'Convivencia con otros perros',
    summary:
        'Aprende a reconocer señales corporales y evita encuentros problemáticos.',
    category: 'Comportamiento',
    readMinutes: 6,
    icon: Icons.pets_outlined,
    color: DogGoTheme.teal,
    background: DogGoTheme.tealLight,
    sections: [
      GuideSection(
        title: 'Observa antes de acercarte',
        content:
            'No todos los perros desean convivir. Observa la postura corporal, la cola, las orejas y la tensión de la correa antes de permitir un saludo.',
      ),
      GuideSection(
        title: 'Mantén distancia',
        content:
            'Si alguno muestra miedo, rigidez o conducta defensiva, aumenta la distancia con calma. Evita tirones bruscos o enfrentamientos frontales.',
      ),
      GuideSection(
        title: 'Encuentros breves',
        content:
            'Los primeros saludos deben ser cortos y supervisados. Continúa caminando si ambos perros se muestran tranquilos.',
      ),
    ],
    quickTips: [
      'Pregunta antes de permitir un saludo.',
      'No obligues a tu perro a acercarse.',
      'Evita correas completamente tensas.',
      'Premia el comportamiento tranquilo.',
    ],
  ),
];