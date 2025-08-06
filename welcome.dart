class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FlutterLogo(size: 60),
                const SizedBox(height: 20),
                Text(
                  'NearCheck+',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Attendance. Smarter than ever.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hi there! Let\'s get you started.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose your role to get started',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: () => _showRoleConfirmation(context, 'teacher'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Teacher'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => _showRoleConfirmation(context, 'student'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Student'),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                    Navigator.push(
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
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const FlutterLogo(size: 60),
            const SizedBox(height: 20),
            Text(
              'NearCheck+',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Attendance. Smarter than ever.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const Text(
              'Hi there! Let\'s get you started.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose your role to get started',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: () => _showRoleConfirmation(context, 'teacher'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Teacher'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _showRoleConfirmation(context, 'student'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Student'),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                Navigator.push(
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
      ),
    );
  }

  void _showRoleConfirmation(BuildContext context, String role) {
    final isTeacher = role == 'teacher';
    final title = isTeacher ? 'Teacher Age Confirmation' : 'Student Age Confirmation';
    final message = isTeacher
        ? 'To continue, please confirm that you are 20 years old or above. This helps us verify teacher accounts and maintain a safe, trusted educational environment for students and staff on NearCheck+.'
        : 'To continue, please confirm that you are 13 years old or above. This helps us maintain a safe, secure, and appropriate experience for all NearCheck+ students.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(message),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(role: role),
                  ),
                );
              },
              child: Text('I am ${isTeacher ? '20+' : '13+'} - Continue'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
