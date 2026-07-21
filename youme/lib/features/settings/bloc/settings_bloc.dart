import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class SettingsEvent extends Equatable {
  @override List<Object?> get props => [];
}
class SettingsLoadRequested extends SettingsEvent {}
class SettingsThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  SettingsThemeChanged(this.themeMode);
  @override List<Object?> get props => [themeMode];
}
class SettingsAiToggled extends SettingsEvent {
  final bool enabled;
  SettingsAiToggled(this.enabled);
}
class SettingsNotificationsToggled extends SettingsEvent {
  final bool enabled;
  SettingsNotificationsToggled(this.enabled);
}

// State
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool aiEnabled;
  final bool notificationsEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.aiEnabled = true,
    this.notificationsEnabled = true,
  });

  SettingsState copyWith({ThemeMode? themeMode, bool? aiEnabled, bool? notificationsEnabled}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        aiEnabled: aiEnabled ?? this.aiEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  @override List<Object?> get props => [themeMode, aiEnabled, notificationsEnabled];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const _themeKey = 'theme_mode';
  static const _aiKey = 'ai_enabled';
  static const _notifKey = 'notifications_enabled';

  SettingsBloc() : super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsAiToggled>(_onAiToggled);
    on<SettingsNotificationsToggled>(_onNotifToggled);
  }

  Future<void> _onLoad(SettingsLoadRequested e, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.dark.index;
    final ai = prefs.getBool(_aiKey) ?? true;
    final notif = prefs.getBool(_notifKey) ?? true;
    emit(state.copyWith(
      themeMode: ThemeMode.values[themeIndex],
      aiEnabled: ai,
      notificationsEnabled: notif,
    ));
  }

  Future<void> _onThemeChanged(SettingsThemeChanged e, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, e.themeMode.index);
    emit(state.copyWith(themeMode: e.themeMode));
  }

  Future<void> _onAiToggled(SettingsAiToggled e, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiKey, e.enabled);
    emit(state.copyWith(aiEnabled: e.enabled));
  }

  Future<void> _onNotifToggled(SettingsNotificationsToggled e, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, e.enabled);
    emit(state.copyWith(notificationsEnabled: e.enabled));
  }
}
