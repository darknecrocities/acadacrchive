import "package:flutter/material.dart";
import "package:acadarchivelatest/helpers/navigation_helper.dart";
import "package:acadarchivelatest/helpers/snack_bar_helper.dart";
import "package:acadarchivelatest/screens/auth/login_screen.dart";
import "package:acadarchivelatest/services/supabase_options.dart";

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  /// 🔹 Sign Up using Supabase Auth and save user info
  Future<void> _signUp() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      SnackBarHelper.show(context, "⚠️ Please fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      SnackBarHelper.show(context, "❌ Passwords do not match.");
      return;
    }

    setState(() => _loading = true);
    try {
      // Step 1: Create user in Supabase Auth
      final response = await SupabaseOptions.client.auth.signUp(
        email: email,
        password: password,
        data: {
          "full_name": fullName,
          "username": username,
        },
      );

      final user = response.user;

      if (user != null) {
        // Step 2: Store extra info in 'profiles' table
        await SupabaseOptions.client.from("profiles").insert({
          "id": user.id,
          "full_name": fullName,
          "username": username,
          "email": email,
        });

        // Step 3: Navigate to Login screen with animation
        if (mounted) {
          SnackBarHelper.show(context, "✅ Account created successfully!");
          await Future.delayed(const Duration(milliseconds: 400));
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, animation, __, child) {
                final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        }
      } else {
        SnackBarHelper.show(context, "Sign-up failed. Try again.");
      }
    } catch (e) {
      SnackBarHelper.show(context, "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storage, size: 28, color: Colors.blueAccent),
                  SizedBox(width: 6),
                  Text(
                    "AcadArchive",
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                "Create Account",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Sign up to get started",
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),

            _buildInputField("Full Name", "Enter your full name",
                controller: _fullNameController),
            const SizedBox(height: 16),

            _buildInputField("Username", "Choose a username",
                controller: _usernameController),
            const SizedBox(height: 16),

            _buildInputField("Email", "Enter your email",
                controller: _emailController),
            const SizedBox(height: 16),

            _buildInputField("Password", "Enter password",
                controller: _passwordController,
                obscure: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword)),
            const SizedBox(height: 16),

            _buildInputField("Confirm Password", "Re-enter password",
                controller: _confirmPasswordController,
                obscure: _obscureConfirm,
                toggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: Text("Already have an account?",
                  style: TextStyle(color: Colors.grey[800], fontSize: 14)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => NavigationHelper.pushReplacement(
                    context, const LoginScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.blueAccent,
                  shadowColor: Colors.transparent,
                  side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text("Sign In", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 Reusable TextField Builder
  Widget _buildInputField(String label, String hint,
      {required TextEditingController controller,
        bool obscure = false,
        VoidCallback? toggleObscure}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
            ),
            suffixIcon: toggleObscure != null
                ? IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
              onPressed: toggleObscure,
            )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }
}
