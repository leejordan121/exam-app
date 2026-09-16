import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';

/// Emits every auth state change (sign in, sign out, token refresh).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// The currently signed-in teacher, or null if signed out.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user ?? supabase.auth.currentUser;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthRepository {
  Future<void> signUp({required String email, required String password, required String fullName}) async {
    final response = await supabase.auth.signUp(email: email, password: password);
    final userId = response.user?.id;
    if (userId != null && fullName.trim().isNotEmpty) {
      await supabase.from('mcq_teachers').update({'full_name': fullName.trim()}).eq('id', userId);
    }
  }

  Future<void> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();
}
