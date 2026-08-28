import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Catálogo semántico de iconos de DogGo.
///
/// Las pantallas consumen conceptos del producto en lugar de depender
/// directamente de los nombres de la librería visual elegida.
abstract final class DogGoIcons {
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData homeActive = PhosphorIconsFill.house;
  static const IconData pets = PhosphorIconsRegular.pawPrint;
  static const IconData petsActive = PhosphorIconsFill.pawPrint;
  static const IconData dog = PhosphorIconsRegular.dog;
  static const IconData dogEmphasis = PhosphorIconsBold.dog;
  static const IconData walks = PhosphorIconsRegular.path;
  static const IconData walksEmphasis = PhosphorIconsBold.path;
  static const IconData walking = PhosphorIconsRegular.personSimpleWalk;
  static const IconData calendar = PhosphorIconsRegular.calendarDots;
  static const IconData calendarActive = PhosphorIconsFill.calendarDots;
  static const IconData calendarConfirmed = PhosphorIconsRegular.calendarCheck;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData timer = PhosphorIconsRegular.timer;
  static const IconData repeat = PhosphorIconsRegular.repeat;
  static const IconData location = PhosphorIconsRegular.mapPin;
  static const IconData map = PhosphorIconsRegular.mapTrifold;
  static const IconData navigation = PhosphorIconsRegular.navigationArrow;
  static const IconData explore = PhosphorIconsRegular.compass;
  static const IconData exploreActive = PhosphorIconsFill.compass;
  static const IconData conversations = PhosphorIconsRegular.chatsCircle;
  static const IconData chat = PhosphorIconsRegular.chatCircleDots;
  static const IconData profile = PhosphorIconsRegular.person;
  static const IconData price = PhosphorIconsRegular.currencyCircleDollar;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData filter = PhosphorIconsRegular.funnel;
  static const IconData refresh = PhosphorIconsRegular.arrowsClockwise;
  static const IconData view = PhosphorIconsRegular.eye;
  static const IconData add = PhosphorIconsRegular.plus;
  static const IconData accept = PhosphorIconsBold.check;
  static const IconData accepted = PhosphorIconsFill.checkCircle;
  static const IconData reject = PhosphorIconsBold.x;
  static const IconData cancelled = PhosphorIconsRegular.xCircle;
  static const IconData start = PhosphorIconsFill.play;
  static const IconData finish = PhosphorIconsRegular.flagCheckered;
  static const IconData safety = PhosphorIconsRegular.shieldCheck;
  static const IconData warning = PhosphorIconsRegular.warningCircle;
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData favorite = PhosphorIconsRegular.heart;
  static const IconData favoriteActive = PhosphorIconsFill.heart;
  static const IconData rating = PhosphorIconsFill.star;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData image = PhosphorIconsRegular.image;
  static const IconData details = PhosphorIconsRegular.listChecks;
  static const IconData forward = PhosphorIconsRegular.arrowRight;
}
