import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==========================================
// 1. DATA MODELS
// ==========================================

enum TaskPriority { urgent, high, medium, low }
enum TaskStatus { todo, inProgress, blocked, completed }
enum TaskCategory { irrigation, spraying, planting, harvesting, maintenance, soilTest }
enum SprayCondition { good, fair, unfavorable }

@immutable
class Task {
  final String id;
  final String title;
  final TaskCategory category;
  final String fieldName;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;

  const Task({
    required this.id,
    required this.title,
    required this.category,
    required this.fieldName,
    required this.priority,
    required this.status,
    required this.dueDate,
  });

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != TaskStatus.completed;

  Task copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    String? fieldName,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      fieldName: fieldName ?? this.fieldName,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class WeatherSummary {
  final double temp;
  final double windSpeed;
  final double humidity;
  final double rainChance;

  const WeatherSummary({
    required this.temp,
    required this.windSpeed,
    required this.humidity,
    required this.rainChance,
  });

  SprayCondition get sprayCondition {
    if (windSpeed > 15.0 || rainChance > 40.0) return SprayCondition.unfavorable;
    if (windSpeed > 10.0 || rainChance > 20.0) return SprayCondition.fair;
    return SprayCondition.good;
  }
}

// ==========================================
// 2. STATE MANAGEMENT (RIVERPOD)
// ==========================================

enum TaskFilter { all, overdue, highPriority }
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier() : super([
    Task(
      id: '1',
      title: 'Spray Fungicide on Sector 4',
      category: TaskCategory.spraying,
      fieldName: 'North Field',
      priority: TaskPriority.high,
      status: TaskStatus.todo,
      dueDate: DateTime.now(),
    ),
    Task(
      id: '2',
      title: 'Main Drip Irrigation System Check',
      category: TaskCategory.irrigation,
      fieldName: 'East Orchard',
      priority: TaskPriority.urgent,
      status: TaskStatus.todo,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ]);

  void addTask(Task task) => state = [...state, task];

  void toggleTaskCompletion(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(status: t.status == TaskStatus.completed ? TaskStatus.todo : TaskStatus.completed)
        else
          t,
    ];
  }
}

final taskListProvider = StateNotifierProvider<TaskListNotifier, List<Task>>((ref) => TaskListNotifier());

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);

  switch (filter) {
    case TaskFilter.overdue:
      return tasks.where((t) => t.isOverdue).toList();
    case TaskFilter.highPriority:
      return tasks.where((t) => t.priority == TaskPriority.high || t.priority == TaskPriority.urgent).toList();
    case TaskFilter.all:
    default:
      return tasks;
  }
});

final weatherProvider = Provider<WeatherSummary>((ref) {
  return const WeatherSummary(temp: 29.5, windSpeed: 8.5, humidity: 62.0, rainChance: 15.0);
});

// ==========================================
// 3. ENTRY POINT & APP ROOT
// ==========================================

void main() {
  runApp(const ProviderScope(child: AgriApp()));
}

class AgriApp extends StatelessWidget {
  const AgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriTask Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ==========================================
// 4. USER INTERFACE (DASHBOARD)
// ==========================================

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(filteredTasksProvider);
    final allTasks = ref.watch(taskListProvider);
    final weather = ref.watch(weatherProvider);
    final activeFilter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('AgriTask Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Weather Card
            Card(
              color: const Color(0xFF1E3A2B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Local Field Weather', style: TextStyle(color: Colors.white70)),
                        Chip(
                          label: Text('Spray: ${weather.sprayCondition.name.toUpperCase()}'),
                          backgroundColor: Colors.green.shade800,
                          labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('${weather.temp}°C', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('Wind: ${weather.windSpeed} km/h\nRain: ${weather.rainChance.toInt()}%', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks Overview Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pending Tasks Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: activeFilter == TaskFilter.all,
                          onSelected: (_) => ref.read(taskFilterProvider.notifier).state = TaskFilter.all,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Overdue'),
                          selected: activeFilter == TaskFilter.overdue,
                          onSelected: (_) => ref.read(taskFilterProvider.notifier).state = TaskFilter.overdue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (ctx, idx) {
                        final task = tasks[idx];
                        final isDone = task.status == TaskStatus.completed;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: isDone,
                            onChanged: (_) => ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id),
                          ),
                          title: Text(task.title, style: TextStyle(decoration: isDone ? TextDecoration.lineThrough : null)),
                          subtitle: Text(task.fieldName),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: () {
          final newTask = Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'New Scheduled Task',
            category: TaskCategory.irrigation,
            fieldName: 'Main Field',
            priority: TaskPriority.medium,
            status: TaskStatus.todo,
            dueDate: DateTime.now(),
          );
          ref.read(taskListProvider.notifier).addTask(newTask);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
