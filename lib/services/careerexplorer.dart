import 'package:flutter/material.dart';
import 'package:aipowered/services/careerinfocard.dart';

class CareerExplorerSheet extends StatefulWidget {
  final Function(String careerName) onCareerSelected;

  const CareerExplorerSheet({super.key, required this.onCareerSelected});

  @override
  State<CareerExplorerSheet> createState() => _CareerExplorerSheetState();
}

class _CareerExplorerSheetState extends State<CareerExplorerSheet> {
  // Original list of all careers
  final List<Map<String, dynamic>> _allCareers = [
    {
      'icon': Icons.design_services_outlined,
      'title': 'UI/UX Designer',
      'description': 'Craft beautiful and user-friendly digital experiences.',
    },
    {
      'icon': Icons.insights_rounded,
      'title': 'Data Scientist',
      'description': 'Uncover insights and trends from complex datasets.',
    },
    {
      'icon': Icons.code_rounded,
      'title': 'Frontend Developer',
      'description': 'Build the visual and interactive parts of websites.',
    },
    {
      'icon': Icons.storage_rounded,
      'title': 'Backend Developer',
      'description': 'Power applications with robust server-side logic.',
    },
    {
      'icon': Icons.cloud_queue_rounded,
      'title': 'Cloud Engineer',
      'description': 'Manage and scale infrastructure on the cloud.',
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Cybersecurity Analyst',
      'description': 'Protect digital assets from threats and breaches.',
    },
    {
      'icon': Icons.analytics_rounded,
      'title': 'Business Analyst',
      'description': 'Bridge the gap between business needs and technology.',
    },
    {
      'icon': Icons.gamepad_rounded,
      'title': 'Game Developer',
      'description': 'Create engaging and immersive gaming experiences.',
    },
    {
      'icon': Icons.smartphone_rounded,
      'title': 'Mobile App Developer',
      'description': 'Design and build apps for iOS and Android platforms.',
    },
  ];

  // ✨ ADDED: State management for search functionality
  late List<Map<String, dynamic>> _filteredCareers;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initially, the filtered list is the full list
    _filteredCareers = _allCareers;
    _searchController.addListener(_filterCareers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCareers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCareers = _allCareers;
      } else {
        _filteredCareers = _allCareers.where((career) {
          final title = career['title'].toString().toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✨ WRAPPED in DraggableScrollableSheet for a framed, resizable view
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Sheet starts at 70% of screen height
      minChildSize: 0.4, // Can be dragged down to 40%
      maxChildSize: 0.95, // Can be dragged up to 95%
      expand: false,
      builder: (context, scrollController) {
        // ✨ ADDED Container to provide the background color and rounded corners
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1C), // The background color of the sheet
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title, Search Bar (non-scrolling part)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Career Explorer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search careers...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable and dynamic list
              Expanded(
                child: ListView.builder(
                  // ✨ IMPORTANT: Pass the controller to the ListView
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredCareers.length,
                  itemBuilder: (context, index) {
                    final career = _filteredCareers[index];
                    return CareerInfoCard(
                      icon: career['icon'],
                      title: career['title'],
                      description: career['description'],
                      onTap: () {
                        widget.onCareerSelected(career['title']);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
