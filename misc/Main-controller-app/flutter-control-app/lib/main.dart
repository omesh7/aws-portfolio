import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(PortfolioControlApp());

class PortfolioControlApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portfolio Control',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ProjectListScreen(),
    );
  }
}

class ProjectListScreen extends StatefulWidget {
  @override
  _ProjectListScreenState createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final String apiUrl = 'https://YOUR_API_ID.execute-api.ap-south-1.amazonaws.com/prod/project';
  
  List<Project> projects = [
    Project('Project 1', 'Static Website S3', 'inactive'),
    Project('Project 2', 'Mass Email SES', 'inactive'),
    Project('Project 3', 'Alexa Skill', 'inactive'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Portfolio Control')),
      body: ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(project.name),
              subtitle: Text(project.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    project.status == 'active' ? Icons.check_circle : Icons.cancel,
                    color: project.status == 'active' ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => deployProject(index),
                    child: Text('Deploy'),
                  ),
                ],
              ),
              onTap: () => checkStatus(index),
            ),
          );
        },
      ),
    );
  }

  Future<void> deployProject(int index) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'deploy',
          'project': 'project${index + 1}',
        }),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deployment triggered for ${projects[index].name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> checkStatus(int index) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'status',
          'project': 'project${index + 1}',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          projects[index].status = data['status'];
        });
      }
    } catch (e) {
      print('Error checking status: $e');
    }
  }
}

class Project {
  String name;
  String description;
  String status;
  
  Project(this.name, this.description, this.status);
}