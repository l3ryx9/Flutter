import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/error_logger.dart';
import '../../../models/user_model.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}
class AuthCheckRequested extends AuthEvent {}
class AuthSignInRequested extends AuthEvent {
  final String email, password;
  AuthSignInRequested(this.email, this.password);
  @override List<Object?> get props => [email];
}
class AuthSignUpRequested extends AuthEvent {
  final String email, password, displayName;
  AuthSignUpRequested(this.email, this.password, this.displayName);
  @override List<Object?> get props => [email];
}
class AuthSignOutRequested extends AuthEvent {}
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  AuthPasswordResetRequested(this.email);
  @override List<Object?> get props => [email];
}
class AuthPasswordUpdateRequested extends AuthEvent {
  final String newPassword;
  AuthPasswordUpdateRequested(this.newPassword);
}

// States
abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user.id];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
class AuthPasswordResetSent extends AuthState {}
class AuthPasswordUpdated extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthPasswordUpdateRequested>(_onPasswordUpdate);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      await _emitAuthenticated(emit, session.user);
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignIn(AuthSignInRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await SupabaseService.signIn(email: e.email, password: e.password);
      if (res.user != null) {
        await _emitAuthenticated(emit, res.user!);
      } else {
        emit(AuthError('Identifiants incorrects.'));
      }
    } on AuthException catch (ex) {
      ErrorLogger.log('AuthBloc.signIn', ex.message);
      emit(AuthError(_mapAuthError(ex.message)));
    } catch (ex) {
      ErrorLogger.log('AuthBloc.signIn', ex.toString());
      emit(AuthError('Erreur de connexion. Réessayez.'));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await SupabaseService.signUp(email: e.email, password: e.password);
      if (res.user != null) {
        await SupabaseService.client.from('profiles').upsert({
          'id': res.user!.id,
          'email': e.email,
          'display_name': e.displayName,
          'created_at': DateTime.now().toIso8601String(),
        });
        await _emitAuthenticated(emit, res.user!);
      } else {
        emit(AuthError('Inscription incomplète. Vérifiez vos emails.'));
      }
    } on AuthException catch (ex) {
      ErrorLogger.log('AuthBloc.signUp', ex.message);
      emit(AuthError(_mapAuthError(ex.message)));
    } catch (ex) {
      ErrorLogger.log('AuthBloc.signUp', ex.toString());
      emit(AuthError('Erreur lors de l\'inscription.'));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await SupabaseService.signOut();
      emit(AuthUnauthenticated());
    } catch (ex) {
      ErrorLogger.log('AuthBloc.signOut', ex.toString());
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onPasswordReset(AuthPasswordResetRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await SupabaseService.resetPassword(e.email);
      emit(AuthPasswordResetSent());
    } catch (ex) {
      ErrorLogger.log('AuthBloc.resetPassword', ex.toString());
      emit(AuthError('Impossible d\'envoyer le lien de réinitialisation.'));
    }
  }

  Future<void> _onPasswordUpdate(AuthPasswordUpdateRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await SupabaseService.updatePassword(e.newPassword);
      emit(AuthPasswordUpdated());
    } catch (ex) {
      ErrorLogger.log('AuthBloc.updatePassword', ex.toString());
      emit(AuthError('Impossible de mettre à jour le mot de passe.'));
    }
  }

  Future<void> _emitAuthenticated(Emitter<AuthState> emit, User user) async {
    try {
      final profile = await SupabaseService.getProfile(user.id);
      final userModel = profile != null
          ? UserModel.fromJson(profile)
          : UserModel(id: user.id, email: user.email ?? '', createdAt: DateTime.now());
      emit(AuthAuthenticated(userModel));
    } catch (ex) {
      ErrorLogger.log('AuthBloc._emitAuthenticated', ex.toString());
      emit(AuthAuthenticated(UserModel(id: user.id, email: user.email ?? '', createdAt: DateTime.now())));
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) return 'Email ou mot de passe incorrect.';
    if (message.contains('Email not confirmed')) return 'Confirmez votre email avant de vous connecter.';
    if (message.contains('User already registered')) return 'Ce compte existe déjà.';
    if (message.contains('Password should be at least')) return 'Le mot de passe doit contenir au moins 6 caractères.';
    return message;
  }
}
