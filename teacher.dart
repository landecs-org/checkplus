class TeacherDashboard extends StatefulWidget {
  final User user;
  final Map<String, dynamic> userData;
  
  const TeacherDashboard({
    super.key,
    required this.user,
    required this.userData,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _confettiController = ConfettiController();
  int _currentIndex = 0;
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sections')
          .where('teacherId', isEqualTo: widget.user.uid)
          .get();

      setState(() {
        _sections = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load sections');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showCreateSectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateSectionBottomSheet(),
    ).then((_) => _loadSections());
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProfileBottomSheet(
        user: widget.user,
        userData: widget.userData,
        onProfileUpdated: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('NearCheck+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showProfileBottomSheet,
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isDesktop),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showCreateSectionBottomSheet,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: isDesktop ? null : _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Color(int.parse(
                      widget.userData['avatarColor'] ?? '0xFF000000',
                      radix: 16)),
                  child: Text(
                    widget.userData['displayIdentity'] ?? 'T',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.userData['fullName'] ?? 'Teacher',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.userData['username'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            selected: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // AuthWrapper will handle the navigation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    switch (_currentIndex) {
      case 0:
        return isDesktop
            ? _buildDesktopDashboard()
            : _buildMobileDashboard();
      case 1:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildDesktopDashboard() {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: _buildDrawer(),
        ),
        Expanded(
          child: _buildDashboardContent(),
        ),
      ],
    );
  }

  Widget _buildMobileDashboard() {
    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getGreeting()}, ${widget.userData['fullName']?.split(' ').first ?? 'Teacher'}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (_sections.isEmpty)
            _buildEmptyState()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Sections',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return _buildSectionCard(section);
                    },
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Recent Attendance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildAttendanceSummary(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/empty_sections.png',
            height: 200,
          ),
          const SizedBox(height: 20),
          const Text(
            'No sections yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first section to get started with attendance tracking',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _showCreateSectionBottomSheet,
            child: const Text('Create Section'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 15),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section['name'] ?? 'Untitled Section',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                section['subject'] ?? 'No subject',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 5),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('sections')
                        .doc(section['id'])
                        .collection('students')
                        .get(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.size ?? 0;
                      return Text('$count students');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SectionDetailScreen(
                            sectionId: section['id'],
                            sectionData: section,
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text('Manage'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    // This would normally fetch real attendance data
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAttendanceSummaryItem('Today', '24', Colors.green),
                _buildAttendanceSummaryItem('This Week', '120', Colors.blue),
                _buildAttendanceSummaryItem('This Month', '480', Colors.orange),
              ],
            ),
            const SizedBox(height: 15),
            const LinearProgressIndicator(
              value: 0.85,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 5),
            const Text(
              '85% attendance rate this week',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}

class CreateSectionBottomSheet extends StatefulWidget {
  const CreateSectionBottomSheet({super.key});

  @override
  State<CreateSectionBottomSheet> createState() =>
      _CreateSectionBottomSheetState();
}

class _CreateSectionBottomSheetState extends State<CreateSectionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _radiusController = TextEditingController(text: '10');
  bool _isLoading = false;
  bool _enableNearId = true;
  bool _enablePlusPoints = false;
  Position? _currentPosition;
  bool _locationLoading = false;
  bool _locationError = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = false;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _currentPosition = position;
        _locationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationError = true;
        _locationLoading = false;
      });
      _showLocationError();
    }
  }

  void _showLocationError() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Location Access Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'NearCheck+ needs access to your location to set the check-in area for this section.',
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _getCurrentLocation();
              },
              child: const Text('Try Again'),
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

  Future<void> _createSection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      _showLocationError();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check section limit
      final sectionsCount = await FirebaseFirestore.instance
          .collection('sections')
          .where('teacherId', isEqualTo: user.uid)
          .count()
          .get();

      if (sectionsCount.count >= 9) {
        throw Exception('You can only create up to 9 sections');
      }

      await FirebaseFirestore.instance.collection('sections').add({
        'name': _nameController.text.trim(),
        'subject': _subjectController.text.trim(),
        'teacherId': user.uid,
        'teacherName': user.displayName ?? 'Teacher',
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'radius': int.parse(_radiusController.text.trim()),
        'enableNearId': _enableNearId,
        'enablePlusPoints': _enablePlusPoints,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create New Section',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Section Name',
                    prefixIcon: Icon(Icons.class_),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a section name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _radiusController,
                  decoration: const InputDecoration(
                    labelText: 'Check-in Radius (meters)',
                    prefixIcon: Icon(Icons.radar),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a radius';
                    }
                    final radius = int.tryParse(value);
                    if (radius == null || radius < 5 || radius > 150) {
                      return 'Radius must be between 5-150 meters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _currentPosition == null
                          ? _locationLoading
                              ? const Text('Getting location...')
                              : _locationError
                                  ? const Text(
                                      'Location error',
                                      style: TextStyle(color: Colors.red),
                                    )
                                  : const Text('Location not set')
                          : Text(
                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                              'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            ),
                    ),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Set Location'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Enable NearID+'),
                  subtitle: const Text(
                      'Allows students to auto check-in when near the section'),
                  value: _enableNearId,
                  onChanged: (value) => setState(() => _enableNearId = value),
                ),
                SwitchListTile(
                  title: const Text('Enable Plus Points'),
                  subtitle: const Text(
                      'Reward students for early check-ins with bonus points'),
                  value: _enablePlusPoints,
                  onChanged: (value) => setState(() => _enablePlusPoints = value),
                ),
                const SizedBox(height: 30),
                FilledButton(
                  onPressed: _isLoading ? null : _createSection,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Section'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _radiusController.dispose();
    super.dispose();
  }
}
