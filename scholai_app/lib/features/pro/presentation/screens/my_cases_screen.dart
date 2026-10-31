import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';

/// Inbox for a matched professional — requests where professionalId is
/// their own uid. Tapping a case opens the shared reply thread.
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key});

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  List<ProRequest>? _cases;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final cases = await ProRequestService.instance.listMyCases();
      if (!mounted) return;
      setState(() => _cases = cases);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load your cases. Check Firestore rules are deployed, then retry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('My cases'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cases == null
          ? _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator())
          : _cases!.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No students matched to you yet. New requests appear here when an admin or auto-match assigns you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primaryLight,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cases!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _CaseCard(request: _cases![index]),
                  ),
                ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.request});

  final ProRequest request;

  @override
  Widget build(BuildContext context) {
    final uid = request.userId ?? '';
    final student = uid.isEmpty
        ? 'Student'
        : 'Student · ${uid.substring(0, uid.length.clamp(0, 6))}';
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/admin/chat/${request.userId}/${request.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.topic,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    request.status.label,
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$student · ${request.preferredMode.label} · ${request.timeWindow}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                request.messages.isEmpty
                    ? 'No messages yet — say hello'
                    : '${request.messages.length} message${request.messages.length == 1 ? '' : 's'}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
