import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/features/account/data/account_service.dart';
import 'package:scholai_app/features/account/domain/platform_role.dart';
import 'package:scholai_app/features/pro/data/models/pro_application.dart';
import 'package:scholai_app/features/pro/data/models/pro_request.dart';
import 'package:scholai_app/features/pro/data/models/professional.dart';
import 'package:scholai_app/features/pro/data/pro_application_service.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';
import 'package:scholai_app/features/safety/data/conversation_report_service.dart';
import 'package:scholai_app/features/safety/domain/conversation_report.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  PlatformProfile? _me;
  bool _loading = true;
  String? _error;

  List<ProApplication> _applications = const [];
  List<ProRequest> _queue = const [];
  List<ConversationReport> _reports = const [];
  List<Professional> _professionals = const [];
  List<PlatformProfile> _people = const [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await AccountService.instance.ensureProfile();
      if (me == null || !me.canManagePlatform) {
        if (!mounted) return;
        setState(() {
          _me = me;
          _loading = false;
        });
        return;
      }
      final results = await Future.wait([
        ProApplicationService.instance.listAll(),
        ProRequestService.instance.listQueue(),
        ProRequestService.instance.listProfessionals(),
        ConversationReportService.instance.listRecent(),
        if (me.canAssignRoles) AccountService.instance.searchUsers(_search.text),
      ]);
      if (!mounted) return;
      setState(() {
        _me = me;
        _applications = results[0] as List<ProApplication>;
        _queue = results[1] as List<ProRequest>;
        _professionals = results[2] as List<Professional>;
        _reports = results[3] as List<ConversationReport>;
        if (me.canAssignRoles) {
          _people = results[4] as List<PlatformProfile>;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the platform. Deploy the latest Firestore rules, then retry.';
      });
    }
  }

  Future<void> _review(ProApplication application, ProApplicationStatus status) async {
    try {
      await ProApplicationService.instance.review(
        application: application,
        status: status,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That review did not save.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _assign(ProRequest request, Professional professional) async {
    try {
      await ProRequestService.instance.assignProfessional(
        request: request,
        professional: professional,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not assign that professional.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _searchPeople() async {
    try {
      final people = await AccountService.instance.searchUsers(_search.text);
      if (!mounted) return;
      setState(() => _people = people);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not search accounts.')),
      );
    }
  }

  Future<void> _setRole(PlatformProfile person, PlatformRole role) async {
    if (person.uid == AuthService.instance.uid && role != PlatformRole.superAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep your own super admin role so the console stays open.')),
      );
      return;
    }
    try {
      await AccountService.instance.setRole(uid: person.uid, role: role);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role was not changed. Only a super admin can do that.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _markReviewed(ConversationReport report) async {
    try {
      await ConversationReportService.instance.markReviewed(report.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark that report reviewed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Platform'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : me == null || !me.canManagePlatform
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'This console is for admins. A super admin can grant that role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                )
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : _Console(
                      me: me,
                      applications: _applications,
                      queue: _queue,
                      reports: _reports,
                      professionals: _professionals,
                      people: _people,
                      search: _search,
                      onReview: _review,
                      onAssign: _assign,
                      onMarkReviewed: _markReviewed,
                      onSearch: _searchPeople,
                      onSetRole: _setRole,
                    ),
    );
  }
}

class _Console extends StatelessWidget {
  const _Console({
    required this.me,
    required this.applications,
    required this.queue,
    required this.reports,
    required this.professionals,
    required this.people,
    required this.search,
    required this.onReview,
    required this.onAssign,
    required this.onMarkReviewed,
    required this.onSearch,
    required this.onSetRole,
  });

  final PlatformProfile me;
  final List<ProApplication> applications;
  final List<ProRequest> queue;
  final List<ConversationReport> reports;
  final List<Professional> professionals;
  final List<PlatformProfile> people;
  final TextEditingController search;
  final void Function(ProApplication, ProApplicationStatus) onReview;
  final void Function(ProRequest, Professional) onAssign;
  final void Function(ConversationReport) onMarkReviewed;
  final VoidCallback onSearch;
  final void Function(PlatformProfile, PlatformRole) onSetRole;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const Tab(text: 'Applications'),
      const Tab(text: 'Requests'),
      const Tab(text: 'Reports'),
      if (me.canAssignRoles) const Tab(text: 'Roles'),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ApplicationList(applications: applications, onReview: onReview),
                _QueueList(
                  queue: queue,
                  professionals: professionals,
                  onAssign: onAssign,
                ),
                _ReportList(reports: reports, onMarkReviewed: onMarkReviewed),
                if (me.canAssignRoles)
                  _RoleList(
                    people: people,
                    search: search,
                    onSearch: onSearch,
                    onSetRole: onSetRole,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.applications, required this.onReview});

  final List<ProApplication> applications;
  final void Function(ProApplication, ProApplicationStatus) onReview;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const _Empty(text: 'No applications yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final app = applications[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${app.credential} · ${app.organization}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${app.email} · ${app.areas.join(', ')}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                app.bio,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.35, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                app.status.label,
                style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
              ),
              if (app.status != ProApplicationStatus.approved) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => onReview(app, ProApplicationStatus.approved),
                      child: const Text('Approve'),
                    ),
                    TextButton(
                      onPressed: () => onReview(app, ProApplicationStatus.rejected),
                      child: const Text(
                        'Decline',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({
    required this.queue,
    required this.professionals,
    required this.onAssign,
  });

  final List<ProRequest> queue;
  final List<Professional> professionals;
  final void Function(ProRequest, Professional) onAssign;

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return const _Empty(text: 'No student requests yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: queue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = queue[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.topic,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${request.preferredMode.label} · ${request.timeWindow} · ${request.status.label}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              if ((request.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  request.note!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
              if (request.professionalName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'With ${request.professionalName}',
                    style: const TextStyle(color: AppColors.accentLight, fontSize: 12),
                  ),
                ),
              if ((request.userId ?? '').isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(
                      '/admin/chat/${request.userId}/${request.id}',
                    ),
                    icon: const Icon(Icons.reply_outlined, size: 16),
                    label: Text(
                      request.messages.isEmpty
                          ? 'Open thread'
                          : 'Open thread · ${request.messages.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              if (professionals.isNotEmpty &&
                  request.status != ProRequestStatus.cancelled &&
                  request.status != ProRequestStatus.completed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text(
                      'Assign a professional',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    dropdownColor: AppColors.surfaceMid,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: [
                      for (final pro in professionals)
                        DropdownMenuItem(value: pro.id, child: Text(pro.name)),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      final pro = professionals.firstWhere((item) => item.id == id);
                      onAssign(request, pro);
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

class _RoleList extends StatelessWidget {
  const _RoleList({
    required this.people,
    required this.search,
    required this.onSearch,
    required this.onSetRole,
  });

  final List<PlatformProfile> people;
  final TextEditingController search;
  final VoidCallback onSearch;
  final void Function(PlatformProfile, PlatformRole) onSetRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: search,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Find by email',
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.search, color: AppColors.primaryLight),
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        Expanded(
          child: people.isEmpty
              ? const _Empty(text: 'No accounts match. People appear after they open the app.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: people.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final person = people[index];
                    final title = person.email.isEmpty
                        ? 'Anonymous · ${person.uid.substring(0, 6)}'
                        : person.email;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ),
                          DropdownButton<PlatformRole>(
                            value: person.role,
                            dropdownColor: AppColors.surfaceMid,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: [
                              for (final role in PlatformRole.values)
                                DropdownMenuItem(value: role, child: Text(role.label)),
                            ],
                            onChanged: (role) {
                              if (role != null && role != person.role) {
                                onSetRole(person, role);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, required this.onMarkReviewed});

  final List<ConversationReport> reports;
  final void Function(ConversationReport) onMarkReviewed;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _Empty(text: 'No conversation reports yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.kind.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (report.counterpartName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  report.counterpartName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                report.note,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
              ),
              if (report.excerpt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  report.excerpt,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                report.isOpen ? 'Open' : 'Reviewed',
                style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
              ),
              if (report.isOpen)
                TextButton(
                  onPressed: () => onMarkReviewed(report),
                  child: const Text('Mark reviewed'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
