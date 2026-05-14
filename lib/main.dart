import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Task {
  String title;
  String deadline;
  bool done;
  String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse("$baseUrl/todos"));

    // Sprawdzenie kodu statusu [cite: 43, 240]
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); // Parsowanie body [cite: 110, 243]
      final List todos = data["todos"];
      
      final random = Random();
      final priorities = ["niski", "średni", "wysoki"]; // Opcjonalne rozszerzenie [cite: 308-311]

      // Mapowanie danych z JSON na model Task [cite: 227-228, 244-255]
      return todos.map((todo) {
        return Task(
          title: todo["todo"], // Pole "todo" z API [cite: 223]
          deadline: "${random.nextInt(28) + 1}.05.2026", // Losowanie daty [cite: 308]
          done: todo["completed"], // Pole "completed" z API [cite: 224]
          priority: priorities[random.nextInt(priorities.length)], // Losowanie priorytetu [cite: 312]
        );
      }).toList();
    } else {
      // Obsługa błędu serwera [cite: 257]
      throw Exception("Błąd pobierania danych: ${response.statusCode}");
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    // Inicjalizacja Future w initState zapobiega ponownym zapytaniom przy build() [cite: 279-282, 304]
    tasksFuture = TaskApiService.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KrakFlow")),
      body: FutureBuilder<List<Task>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          // Zadanie 3: Obsługa wizualna stanów [cite: 356-363]
          
          // 1. Stan ładowania (waiting) [cite: 322, 358-359]
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          // 2. Stan błędu (error) [cite: 341, 360-361]
          else if (snapshot.hasError) {
            return Center(
              child: Text("Błąd: ${snapshot.error}", textAlign: TextAlign.center),
            );
          } 
          
          // 3. Stan danych (data) [cite: 362-363]
          else if (snapshot.hasData) {
            final tasks = snapshot.data!;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onChanged: (value) => setState(() => task.done = value!),
                );
              },
            );
          }

          return const Center(child: Text("Brak danych"));
        },
      ),
    );
  }
}

// Widget pomocniczy do wyświetlania zadania
class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?>? onChanged;

  const TaskCard({super.key, required this.task, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Checkbox(value: task.done, onChanged: onChanged),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text("Priorytet: ${task.priority} | Termin: ${task.deadline}"),
      ),
    );
  }
}