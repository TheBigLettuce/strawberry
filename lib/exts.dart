/*
  Strawberry, a music player
  Copyright (C) 2024  Bob

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import "dart:ui";

extension BrightnessFlipExt on Brightness {
  Brightness get flip =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}

extension ColorValueAlphaExt on Color {
  Color valueAlpha(double alpha) => withValues(alpha: alpha);
}

extension ChineseRuneIntExt on int {
  bool get isChineseRune {
    if (this == 0x3007 ||
        (this >= 0x3400 && this <= 0x4DBF) ||
        (this >= 0x4E00 && this <= 0x9FEF) ||
        (this >= 0x20000 && this <= 0x2EBFF)) {
      return true;
    }

    return false;
  }
}

extension DurationIntFormattedExt on int {
  String get durationMilisFormatted {
    var microseconds = Duration(milliseconds: this).inMicroseconds;

    final minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

    final seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

    return "$minutes:${seconds < 10 ? "0" : ""}$seconds";
  }
}
