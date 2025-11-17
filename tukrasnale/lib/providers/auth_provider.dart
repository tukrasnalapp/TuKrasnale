import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = SupabaseService.instance.currentUser;
    
    SupabaseService.instance.authStateChanges.listen((AuthState data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await SupabaseService.instance.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await SupabaseService.instance.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}