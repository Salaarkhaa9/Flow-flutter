import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Task> _tasks = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final tasks = await _taskService.getTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    }
  }

  Future<void> _addTask() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final task = Task(
      id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await _taskService.addTask(task);

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      _titleController.clear();
      _notesController.clear();
      await _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task added!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Future<void> _toggleComplete(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _taskService.updateTask(updated);
    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Task?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0a2226))),
        content: Text('Delete "${task.title}"?', style: GoogleFonts.inter(color: const Color(0xFF71717A))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF71717A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _taskService.deleteTask(task.id);
      await _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted.'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(color: const Color(0xFF18181B), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF71717A),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
        filled: true,
        fillColor: const Color(0xFFF4F4F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0a2226), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFF0a2226).withOpacity(0.15)
              : const Color(0xFFE4E4E7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleComplete(task),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? const Color(0xFF0a2226)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: task.isCompleted
                      ? const Color(0xFF0a2226)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: task.isCompleted
                        ? Colors.black26
                        : const Color(0xFF0a2226),
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.notes,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: task.isCompleted
                          ? Colors.black26
                          : const Color(0xFF71717A),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12,
                        color: task.isCompleted
                            ? Colors.black26
                            : const Color(0xFF71717A)),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(task.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: task.isCompleted
                            ? Colors.black26
                            : const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
            onPressed: () => _deleteTask(task),
            tooltip: 'Delete',
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0a2226), Color(0xFFFAFAFA)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a2226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Tasks',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_tasks.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFd6ff00),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$completedCount/${_tasks.length}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0a2226),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0a2226).withOpacity(0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                                color: const Color(0xFFE4E4E7)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0a2226)
                                            .withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.task_alt_rounded,
                                          color: Color(0xFF0a2226)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Add Task',
                                            style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.w800,
                                                color: const Color(0xFF0a2226)),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Jot down a quick note or to-do.',
                                            style: GoogleFonts.inter(
                                                color: const Color(0xFF71717A),
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _buildField(
                                  'Title',
                                  _titleController,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  'Notes (optional)',
                                  _notesController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _addTask,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF0a2226),
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text('Add Task',
                                            style: GoogleFonts.outfit(
                                                fontWeight:
                                                    FontWeight.w800,
                                                fontSize: 15)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your Tasks',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0a2226),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_loading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                    color: Color(0xFF0a2226)),
                              ),
                            ),
                          if (!_loading && _tasks.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFE4E4E7)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.task_alt_outlined,
                                      size: 40, color: Color(0xFF71717A)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No tasks yet',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF71717A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add your first task above.',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFA1A1AA),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!_loading && _tasks.isNotEmpty)
                            ..._tasks.map((t) => _buildTaskItem(t)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
