class SignUpScreen extends StatefulWidget {
  final String role;
  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _generatedUsername = '';
  bool _isLoading = false;
  String? _sectionId;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_generateUsername);
    // Check for invitation link
    _checkForInvitation();
  }

  void _checkForInvitation() async {
    // This would normally come from deep linking
    // For demo purposes, we'll simulate it
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('sectionId')) {
      setState(() {
        _sectionId = uri.queryParameters['sectionId'];
      });
    }
  }

  void _generateUsername() {
    if (_fullNameController.text.isEmpty) {
      setState(() {
        _generatedUsername = '';
      });
      return;
    }

    final nameParts = _fullNameController.text.trim().split(' ');
    final firstName = nameParts.first.toLowerCase();
    final lastName = nameParts.length > 1 ? nameParts.last[0].toLowerCase() : '';
    
    // Generate random ID portion
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final randomId = String.fromCharCodes(Iterable.generate(
      8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    
    setState(() {
      _generatedUsername = '${firstName}$lastName$randomId@nearcheck/${widget.role == 'teacher' ? 'teacher' : 'student'}ID-$randomId';
      if (_sectionId != null && widget.role == 'student') {
        _generatedUsername += '-$_sectionId';
      }
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create user in Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Generate random avatar color
      final random = Random();
      final avatarColor = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1,
      );

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'username': _generatedUsername,
            'role': widget.role,
            'avatarColor': avatarColor.value.toRadixString(16),
            'createdAt': FieldValue.serverTimestamp(),
            'points': 0,
            'displayIdentity': _generateInitialDisplayIdentity(),
            'lastIdentityChange': DateTime.now().toIso8601String(),
          });

      // If student and has sectionId, join the section
      if (widget.role == 'student' && _sectionId != null) {
        await _joinSection(credential.user!.uid, _sectionId!);
      }

      // Navigate to appropriate dashboard
      if (widget.role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherDashboard(
              user: credential.user!,
              userData: {
                'role': 'teacher',
                'username': _generatedUsername,
              },
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboard(
              user: credential.user!,
              userData: {
                'role': 'student',
                'username': _generatedUsername,
              },
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.message ?? 'An error occurred during sign up');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('An error occurred during sign up');
    }
  }

  Future<void> _joinSection(String userId, String sectionId) async {
    try {
      final sectionDoc = await FirebaseFirestore.instance
          .collection('sections')
          .doc(sectionId)
          .get();

      if (!sectionDoc.exists) {
        throw Exception('Section not found');
      }

      // Generate NearID+ if enabled
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      final nearId = String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length)));

      await FirebaseFirestore.instance
          .collection('sections')
          .doc(sectionId)
          .collection('students')
          .doc(userId)
          .set({
            'joinedAt': FieldValue.serverTimestamp(),
            'points': 0,
            'nearId': nearId,
          });

      // Update username with section info
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'username': '$_generatedUsername-$sectionId-$nearId',
          });
    } catch (e) {
      // Silently fail - user can join section later
    }
  }

  String _generateInitialDisplayIdentity() {
    final random = Random();
    final emojis = ['😀', '😊', '🤓', '🧑‍🎓', '👩‍🏫', '👨‍💻', '👩‍💻', '🤖', '🎯', '🌟'];
    return emojis[random.nextInt(emojis.length)];
  }

  void _showErrorDialog(String message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(message),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.role == 'teacher' ? 'Teacher Sign-Up' : 'Student Sign-Up',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a password';
              }
              if (value.trim().length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_generatedUsername.isNotEmpty) ...[
            const Text('Your username:'),
            Text(
              _generatedUsername,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This username is permanent and cannot be changed later',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
          if (widget.role == 'student') ...[
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Section ID or Invitation Link (optional)',
                prefixIcon: Icon(Icons.group),
              ),
              onChanged: (value) {
                setState(() {
                  _sectionId = value.trim().isNotEmpty ? value.trim() : null;
                });
              },
            ),
            const SizedBox(height: 20),
          ],
          FilledButton(
            onPressed: _isLoading ? null : _signUp,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Sign Up'),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: const Text('Already have an account? Sign In'),
          ),
          const SizedBox(height: 20),
          const Text(
            'By continuing to NearCheck+ you agree with our terms and privacy policy',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigation is handled by AuthWrapper
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.message ?? 'An error occurred during login');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('An error occurred during login');
    }
  }

  void _showErrorDialog(String message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(message),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign In',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email or Username',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email or username';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement password reset
              },
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Sign In'),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
              );
            },
            child: const Text("Don't have an account? Sign Up"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
