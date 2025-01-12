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

import "package:flutter/material.dart";

class MaterialTheme {
  const MaterialTheme(this.textTheme);
  final TextTheme textTheme;

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xffa00008),
      surfaceTint: Color(0xffc0000d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe30c15),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xffaf2e25),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffff7c6d),
      onSecondaryContainer: Color(0xff3b0001),
      tertiary: Color(0xff6e4400),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff9f6500),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff410002),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff291714),
      onSurfaceVariant: Color(0xff5e3f3b),
      outline: Color(0xff936e69),
      outlineVariant: Color(0xffe8bcb6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff412b28),
      inversePrimary: Color(0xffffb4aa),
      primaryFixed: Color(0xffffdad5),
      onPrimaryFixed: Color(0xff410001),
      primaryFixedDim: Color(0xffffb4aa),
      onPrimaryFixedVariant: Color(0xff930007),
      secondaryFixed: Color(0xffffdad5),
      onSecondaryFixed: Color(0xff410001),
      secondaryFixedDim: Color(0xffffb4aa),
      onSecondaryFixedVariant: Color(0xff8d1411),
      tertiaryFixed: Color(0xffffddb7),
      onTertiaryFixed: Color(0xff2a1700),
      tertiaryFixedDim: Color(0xffffb95d),
      onTertiaryFixedVariant: Color(0xff653e00),
      surfaceDim: Color(0xfff5d2cd),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ee),
      surfaceContainer: Color(0xffffe9e6),
      surfaceContainerHigh: Color(0xffffe2de),
      surfaceContainerHighest: Color(0xfffedad6),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff8c0006),
      surfaceTint: Color(0xffc0000d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe30c15),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff880f0d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffce4439),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff5f3b00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff9f6500),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff8c0009),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffda342e),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff291714),
      onSurfaceVariant: Color(0xff5a3b37),
      outline: Color(0xff795752),
      outlineVariant: Color(0xff97726d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff412b28),
      inversePrimary: Color(0xffffb4aa),
      primaryFixed: Color(0xffe81318),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xffbc000c),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xffce4439),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xffac2c23),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xffa26804),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff825100),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xfff5d2cd),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ee),
      surfaceContainer: Color(0xffffe9e6),
      surfaceContainerHigh: Color(0xffffe2de),
      surfaceContainerHighest: Color(0xfffedad6),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff4e0002),
      surfaceTint: Color(0xffc0000d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff8c0006),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff4e0002),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff880f0d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff331d00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff5f3b00),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff4e0002),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff371d1a),
      outline: Color(0xff5a3b37),
      outlineVariant: Color(0xff5a3b37),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff412b28),
      inversePrimary: Color(0xffffe7e3),
      primaryFixed: Color(0xff8c0006),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff620003),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff880f0d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff620003),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff5f3b00),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff412700),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xfff5d2cd),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ee),
      surfaceContainer: Color(0xffffe9e6),
      surfaceContainerHigh: Color(0xffffe2de),
      surfaceContainerHighest: Color(0xfffedad6),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffb4aa),
      surfaceTint: Color(0xffffb4aa),
      onPrimary: Color(0xff690003),
      primaryContainer: Color(0xffd4000f),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xffffb4aa),
      onSecondary: Color(0xff690003),
      secondaryContainer: Color(0xff840b0b),
      onSecondaryContainer: Color(0xffffc9c2),
      tertiary: Color(0xffffb95d),
      onTertiary: Color(0xff462a00),
      tertiaryContainer: Color(0xff935d00),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff200f0c),
      onSurface: Color(0xfffedad6),
      onSurfaceVariant: Color(0xffe8bcb6),
      outline: Color(0xffaf8782),
      outlineVariant: Color(0xff5e3f3b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xfffedad6),
      inversePrimary: Color(0xffc0000d),
      primaryFixed: Color(0xffffdad5),
      onPrimaryFixed: Color(0xff410001),
      primaryFixedDim: Color(0xffffb4aa),
      onPrimaryFixedVariant: Color(0xff930007),
      secondaryFixed: Color(0xffffdad5),
      onSecondaryFixed: Color(0xff410001),
      secondaryFixedDim: Color(0xffffb4aa),
      onSecondaryFixedVariant: Color(0xff8d1411),
      tertiaryFixed: Color(0xffffddb7),
      onTertiaryFixed: Color(0xff2a1700),
      tertiaryFixedDim: Color(0xffffb95d),
      onTertiaryFixedVariant: Color(0xff653e00),
      surfaceDim: Color(0xff200f0c),
      surfaceBright: Color(0xff4a3431),
      surfaceContainerLowest: Color(0xff1a0908),
      surfaceContainerLow: Color(0xff291714),
      surfaceContainer: Color(0xff2e1a18),
      surfaceContainerHigh: Color(0xff3a2522),
      surfaceContainerHighest: Color(0xff452f2c),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffbab1),
      surfaceTint: Color(0xffffb4aa),
      onPrimary: Color(0xff370001),
      primaryContainer: Color(0xffff5447),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffffbab1),
      onSecondary: Color(0xff370001),
      secondaryContainer: Color(0xfff46051),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffbf6d),
      onTertiary: Color(0xff231300),
      tertiaryContainer: Color(0xffc38327),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffbab1),
      onError: Color(0xff370001),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff200f0c),
      onSurface: Color(0xfffff9f9),
      onSurfaceVariant: Color(0xffedc0bb),
      outline: Color(0xffc29994),
      outlineVariant: Color(0xffa07a75),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xfffedad6),
      inversePrimary: Color(0xff950007),
      primaryFixed: Color(0xffffdad5),
      onPrimaryFixed: Color(0xff2d0001),
      primaryFixedDim: Color(0xffffb4aa),
      onPrimaryFixedVariant: Color(0xff740004),
      secondaryFixed: Color(0xffffdad5),
      onSecondaryFixed: Color(0xff2d0001),
      secondaryFixedDim: Color(0xffffb4aa),
      onSecondaryFixedVariant: Color(0xff740004),
      tertiaryFixed: Color(0xffffddb7),
      onTertiaryFixed: Color(0xff1c0e00),
      tertiaryFixedDim: Color(0xffffb95d),
      onTertiaryFixedVariant: Color(0xff4e2f00),
      surfaceDim: Color(0xff200f0c),
      surfaceBright: Color(0xff4a3431),
      surfaceContainerLowest: Color(0xff1a0908),
      surfaceContainerLow: Color(0xff291714),
      surfaceContainer: Color(0xff2e1a18),
      surfaceContainerHigh: Color(0xff3a2522),
      surfaceContainerHighest: Color(0xff452f2c),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffff9f9),
      surfaceTint: Color(0xffffb4aa),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffffbab1),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfffff9f9),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffffbab1),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfffffaf7),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffffbf6d),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xfffff9f9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffbab1),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff200f0c),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xfffff9f9),
      outline: Color(0xffedc0bb),
      outlineVariant: Color(0xffedc0bb),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xfffedad6),
      inversePrimary: Color(0xff5c0003),
      primaryFixed: Color(0xffffe0dc),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffffbab1),
      onPrimaryFixedVariant: Color(0xff370001),
      secondaryFixed: Color(0xffffe0dc),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffffbab1),
      onSecondaryFixedVariant: Color(0xff370001),
      tertiaryFixed: Color(0xffffe2c3),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffffbf6d),
      onTertiaryFixedVariant: Color(0xff231300),
      surfaceDim: Color(0xff200f0c),
      surfaceBright: Color(0xff4a3431),
      surfaceContainerLowest: Color(0xff1a0908),
      surfaceContainerLow: Color(0xff291714),
      surfaceContainer: Color(0xff2e1a18),
      surfaceContainerHigh: Color(0xff3a2522),
      surfaceContainerHighest: Color(0xff452f2c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });

  final Color seed;
  final Color value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
