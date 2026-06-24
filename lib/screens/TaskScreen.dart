import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';

import '../l10n/app_localizations.dart';
import '../localization_helper.dart';
import '../services/task_service.dart';

// ignore: duplicate_import
import '../localization_helper.dart';

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.createdAt,
    required this.completed,
    required this.color,
  });

  final String id;
  final String title;
  final IconData icon;
  final int createdAt;
  bool completed;
  final Color color;
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  Timer? _refreshTimer;

  final List<TaskItem> _tasks = [];
  bool _isLoadingTasks = true;
  int _completedCount = 0;
  String? _loadError;
  String? _ownerName;

  int get _totalTrackedTaskCount => _tasks.length;

  double get _progress => _totalTrackedTaskCount == 0
      ? 0.0
      : (_completedCount / _totalTrackedTaskCount).clamp(0.0, 1.0);

  final List<IconData> _fallbackIcons = [
    Icons.task_alt,
    Icons.local_fire_department,
    Icons.auto_graph,
    Icons.local_florist,
    Icons.lightbulb,
    Icons.volunteer_activism,
    Icons.nature_people,
    Icons.favorite,
  ];

  final List<Color> _fallbackColors = [
    Colors.blueAccent,
    Colors.deepPurpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.yellowAccent,
    Colors.tealAccent,
  ];

  static final Map<int, IconData> _iconMapFromCodePoint = {
    Icons.water_drop.codePoint: Icons.water_drop,
    Icons.directions_walk.codePoint: Icons.directions_walk,
    Icons.edit_note.codePoint: Icons.edit_note,
    Icons.self_improvement.codePoint: Icons.self_improvement,
    Icons.emoji_emotions.codePoint: Icons.emoji_emotions,
    Icons.menu_book.codePoint: Icons.menu_book,
    Icons.school.codePoint: Icons.school,
    Icons.local_drink.codePoint: Icons.local_drink,
    Icons.fitness_center.codePoint: Icons.fitness_center,
    Icons.music_note.codePoint: Icons.music_note,
    Icons.bedtime.codePoint: Icons.bedtime,
    Icons.task_alt.codePoint: Icons.task_alt,
    Icons.local_fire_department.codePoint: Icons.local_fire_department,
    Icons.auto_graph.codePoint: Icons.auto_graph,
    Icons.local_florist.codePoint: Icons.local_florist,
    Icons.lightbulb.codePoint: Icons.lightbulb,
    Icons.volunteer_activism.codePoint: Icons.volunteer_activism,
    Icons.nature_people.codePoint: Icons.nature_people,
    Icons.favorite.codePoint: Icons.favorite,
  };

  IconData _iconFromCodePoint(int codePoint) {
    return _iconMapFromCodePoint[codePoint] ?? Icons.task_alt;
  }

  IconData _iconForTask(String title) {
    final text = title.toLowerCase();
    if (text.contains('water') || text.contains('ماء')) return Icons.water_drop;
    if (text.contains('walk') || text.contains('run') || text.contains('مشي')) {
      return Icons.directions_walk;
    }
    if (text.contains('write') ||
        text.contains('note') ||
        text.contains('thought') ||
        text.contains('اكتب') ||
        text.contains('كتابة') ||
        text.contains('تفكير')) {
      return Icons.edit_note;
    }
    if (text.contains('breath') ||
        text.contains('meditate') ||
        text.contains('تنفس') ||
        text.contains('هدوء')) {
      return Icons.self_improvement;
    }
    if (text.contains('smile') ||
        text.contains('happy') ||
        text.contains('ابتسم')) {
      return Icons.emoji_emotions;
    }
    if (text.contains('read') || text.contains('قراءة')) return Icons.menu_book;
    if (text.contains('study') || text.contains('دراسة')) return Icons.school;
    if (text.contains('drink') || text.contains('شرب')) {
      return Icons.local_drink;
    }
    if (text.contains('exercise') || text.contains('تمرين')) {
      return Icons.fitness_center;
    }
    if (text.contains('music') || text.contains('موسيقى')) {
      return Icons.music_note;
    }
    if (text.contains('sleep') || text.contains('نوم')) return Icons.bedtime;
    return _fallbackIcons[title.hashCode.abs() % _fallbackIcons.length];
  }

  Color _colorForTask(String title) {
    final text = title.toLowerCase();
    if (text.contains('water') ||
        text.contains('drink') ||
        text.contains('ماء') ||
        text.contains('شرب')) {
      return Colors.lightBlueAccent;
    }
    if (text.contains('walk') || text.contains('run') || text.contains('مشي')) {
      return Colors.orangeAccent;
    }
    if (text.contains('write') ||
        text.contains('note') ||
        text.contains('thought') ||
        text.contains('اكتب') ||
        text.contains('كتابة') ||
        text.contains('تفكير')) {
      return Colors.pinkAccent;
    }
    if (text.contains('breath') ||
        text.contains('meditate') ||
        text.contains('تنفس') ||
        text.contains('هدوء')) {
      return Colors.amber;
    }
    if (text.contains('smile') ||
        text.contains('happy') ||
        text.contains('ابتسم')) {
      return Colors.greenAccent;
    }
    if (text.contains('read') ||
        text.contains('study') ||
        text.contains('قراءة') ||
        text.contains('دراسة')) {
      return Colors.tealAccent;
    }
    if (text.contains('exercise') || text.contains('تمرين')) {
      return Colors.redAccent;
    }
    if (text.contains('music') || text.contains('موسيقى')) {
      return Colors.deepPurpleAccent;
    }
    if (text.contains('sleep') || text.contains('نوم')) {
      return Colors.indigoAccent;
    }
    return _fallbackColors[title.hashCode.abs() % _fallbackColors.length];
  }

  TaskItem _createTaskItem(String title) {
    return TaskItem(
      id: '',
      title: title,
      icon: _iconForTask(title),
      color: _colorForTask(title),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      completed: false,
    );
  }

  Future<void> _loadTasks() async {
    try {
      final state = await TaskService.loadTaskState();
      final loadedTasks = state.tasks
          .map(
            (record) => TaskItem(
              id: record.id,
              title: record.title,
              icon: _iconFromCodePoint(record.iconCodePoint),
              color: Color(record.colorValue),
              createdAt: record.createdAt,
              completed: record.completed,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _ownerName = state.fullName;
        _tasks
          ..clear()
          ..addAll(loadedTasks);
        _completedCount = state.completedCount;
        _loadError = null;
        _isLoadingTasks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load tasks.';
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _saveTask(TaskItem task) async {
    final savedTask = await TaskService.addTask(
      title: task.title,
      iconCodePoint: task.icon.codePoint,
      colorValue: task.color.toARGB32(),
      createdAt: task.createdAt,
    );

    if (savedTask == null) return;

    if (!mounted) return;
    setState(() {
      _tasks.add(
        TaskItem(
          id: savedTask.id,
          title: savedTask.title,
          icon: _iconFromCodePoint(savedTask.iconCodePoint),
          color: Color(savedTask.colorValue),
          createdAt: savedTask.createdAt,
          completed: savedTask.completed,
        ),
      );
    });
  }

  Future<void> _removeTask(int index, {required bool completed}) async {
    final task = _tasks[index];

    try {
      if (completed) {
        await TaskService.completeTask(task.id);
        if (!mounted) return;
        setState(() {
          _tasks[index].completed = true;
          _completedCount = _tasks.where((element) => element.completed).length;
        });
      } else {
        await TaskService.deleteTask(task.id);
        if (!mounted) return;
        setState(() {
          _tasks.removeAt(index);
          _completedCount = _tasks.where((element) => element.completed).length;
        });
      }

      if (_tasks.isNotEmpty && _tasks.every((element) => element.completed)) {
        _showCompletionMessage();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your tasks.')),
      );
    }
  }

  Future<bool> _confirmDelete(int index) async {
    if (_tasks[index].completed) {
      _showCompletedTaskCannotDeleteSnackBar();
      return false;
    }

    final palette = AppPalette.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: palette.surfaceAlt,
              title: Text(
                CustomLocalizations.of(context).get('deleteTaskTitle'),
                style: TextStyle(color: palette.textPrimary),
              ),
              content: Text(
                CustomLocalizations.of(context).get('deleteTaskConfirmation'),
                style: TextStyle(color: palette.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(CustomLocalizations.of(context).get('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    CustomLocalizations.of(context).get('delete'),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        ) ==
        true;
  }

  void _showDeletedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(CustomLocalizations.of(context).get('taskDeleted')),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _showCompletedTaskCannotDeleteSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يمكن حذف المهمة بعد تنفيذها'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCompletionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('أحسنت! خلصت كل المهام 🎉'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _completeTask(int index) async {
    await _removeTask(index, completed: true);
  }

  Future<void> _addTask() async {
    final String text = _taskController.text.trim();
    if (text.isEmpty) return;

    final task = _createTaskItem(text);

    try {
      await _saveTask(task);
      _taskController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save the task.')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) {
        _loadTasks();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          localizations.microTasks,
          style: TextStyle(color: palette.textPrimary, fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: 30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: palette.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 120,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: palette.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Small steps, big changes',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  if (_ownerName != null && _ownerName!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Owner: $_ownerName',
                        style: TextStyle(
                          color: palette.textSecondary.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildProgressCard(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildTaskList()),
                  const SizedBox(height: 16),
                  _buildAddTaskField(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_completedCount/$_totalTrackedTaskCount',
            style: TextStyle(color: palette.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                _progress >= 1 && _totalTrackedTaskCount > 0
                    ? Colors.greenAccent
                    : palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final palette = AppPalette.of(context);
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 72,
              color: palette.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              style: TextStyle(color: palette.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadTasks, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt,
              size: 72,
              color: palette.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet. Add one below!',
              style: TextStyle(color: palette.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final TaskItem task = _tasks[index];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(index),
          onDismissed: (_) {
            _removeTask(index, completed: false);
            _showDeletedSnackBar();
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: task.completed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  activeColor: palette.primary,
                  side: BorderSide(
                    color: palette.textSecondary.withOpacity(0.4),
                  ),
                  onChanged: (value) {
                    if (value == true && !task.completed) {
                      _completeTask(index);
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.completed
                              ? palette.textSecondary
                              : palette.textPrimary,
                          fontSize: 16,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: task.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.completed ? 'Completed' : 'Not done yet',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(task.icon, color: task.color, size: 26),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    if (task.completed) {
                      _showCompletedTaskCannotDeleteSnackBar();
                      return;
                    }

                    final bool confirmed = await _confirmDelete(index);
                    if (confirmed) {
                      _removeTask(index, completed: false);
                      _showDeletedSnackBar();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskField() {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _taskController,
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: CustomLocalizations.of(context).get('addCustomTask'),
                hintStyle: TextStyle(color: palette.textSecondary),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTask(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _addTask,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
