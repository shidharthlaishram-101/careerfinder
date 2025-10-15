import 'package:flutter/material.dart';
import 'package:aipowered/careerchatbot.dart';
import 'package:aipowered/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _workDescriptionController =
      TextEditingController();
  String? _selectedStream;
  String? _educationLevel;
  String? _selectedDegree;
  String? _selectedBranch;
  bool _isWorking = false;
  bool _isLoading = false;

  final List<String> streams = ["Science", "Commerce", "Arts"];

  final List<String> educationLevels = [
    "High School",
    "Undergraduate",
    "Postgraduate",
    "PhD",
  ];

  // Degrees based on education level
  List<String> _getDegrees(String? level) {
    switch (level) {
      case "Undergraduate":
        return ["B.Tech", "B.Sc", "B.Com", "B.A", "BBA"];
      case "Postgraduate":
        return ["M.Tech", "M.Sc", "MBA", "M.A", "M.Com"];
      case "PhD":
        return [
          "Doctorate in Engineering",
          "Doctorate in Science",
          "Doctorate in Arts",
        ];
      default:
        return [];
    }
  }

  // Branches/Specializations based on selected degree
  List<String> getDegreeSpecializations(String? degree) {
    switch (degree) {
      case "B.Tech":
      case "M.Tech":
        return ["CSE", "ECE", "EEE", "CIVIL", "MECHANICAL"];
      case "B.Sc":
      case "M.Sc":
        return [
          "Physics",
          "Chemistry",
          "Mathematics",
          "Biology",
          "Computer Science",
        ];
      case "B.A":
      case "M.A":
        return [
          "English",
          "History",
          "Political Science",
          "Economics",
          "Psychology",
        ];
      case "B.Com":
      case "M.Com":
        return ["Accounting", "Finance", "Taxation", "Marketing"];
      case "BBA":
      case "MBA":
        return ["HR", "Finance", "Marketing", "Operations", "IT Management"];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _workDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar("User not authenticated. Please login again.");
        return;
      }

      await UserService.saveDetailedUserInfo(
        userId: currentUser.uid,
        age: int.parse(_ageController.text.trim()),
        stream: _selectedStream!,
        educationLevel: _educationLevel!,
        degree: _selectedDegree,
        specialization: _selectedBranch,
        isWorking: _isWorking,
        workDescription: _workDescriptionController.text.trim().isEmpty
            ? null
            : _workDescriptionController.text.trim(),
      );

      _showSuccessSnackBar("User info saved successfully!");

      // Navigate to chatbot screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CareerChatbotPage()),
      );
    } catch (e) {
      _showErrorSnackBar("Failed to save user info: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Tell us about yourself",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3C74FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // AGE
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your age" : null,
              ),
              const SizedBox(height: 20),

              // STREAM
              DropdownButtonFormField<String>(
                value: _selectedStream,
                items: streams
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStream = val),
                decoration: InputDecoration(
                  labelText: "Stream of Study",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                dropdownColor: Colors.white,
              ),
              const SizedBox(height: 20),

              // EDUCATION LEVEL
              DropdownButtonFormField<String>(
                value: _educationLevel,
                items: educationLevels
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _educationLevel = val;
                    _selectedDegree = null;
                    _selectedBranch = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Education Level",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                dropdownColor: Colors.white,
              ),
              const SizedBox(height: 20),

              // DEGREE (based on education level)
              if (_educationLevel == "Undergraduate" ||
                  _educationLevel == "Postgraduate" ||
                  _educationLevel == "PhD")
                DropdownButtonFormField<String>(
                  value: _selectedDegree,
                  items: _getDegrees(_educationLevel)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDegree = val;
                      _selectedBranch = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Degree",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                ),
              const SizedBox(height: 20),

              // SPECIALIZATION (based on degree)
              if (getDegreeSpecializations(_selectedDegree).isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedBranch,
                  items: getDegreeSpecializations(_selectedDegree)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedBranch = val),
                  decoration: InputDecoration(
                    labelText: "Specialization / Branch",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                ),
              const SizedBox(height: 20),

              // WORKING STATUS
              SwitchListTile(
                title: const Text("Currently Working?"),
                value: _isWorking,
                onChanged: (val) => setState(() => _isWorking = val),
              ),
              const SizedBox(height: 20),

              if (_isWorking)
                TextFormField(
                  controller: _workDescriptionController,
                  decoration: InputDecoration(
                    labelText: "What are you working on?",
                    hintText:
                        "e.g., Software Engineer at XYZ / Freelance Designer",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (_isWorking && (value == null || value.isEmpty)) {
                      return "Please mention your work or job role";
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C74FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _saveUserInfo,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
