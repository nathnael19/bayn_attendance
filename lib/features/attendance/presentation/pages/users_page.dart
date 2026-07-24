import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/person.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';
import 'user_detail_page.dart';

String? _frontImagePath(Person person) {
  final front = person.faceImagePaths['front'];
  if (front == null || front.isEmpty) return null;

  final file = File(front.first);
  return file.existsSync() ? front.first : null;
}

enum UsersSort { recent, name, department }

class UsersPage extends StatefulWidget {
  final VoidCallback? onEnroll;

  const UsersPage({super.key, this.onEnroll});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final TextEditingController _searchController;
  String _query = '';
  String _department = 'all';
  UsersSort _sort = UsersSort.recent;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<UsersCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEnrollment() {
    if (widget.onEnroll != null) {
      widget.onEnroll!();
      return;
    }

    Navigator.of(context).maybePop();
  }

  void _openDetails(Person person) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UserDetailPage(person: person)));
  }

  void _resetFilters() {
    setState(() {
      _query = '';
      _department = 'all';
    });
    _searchController.clear();
  }

  List<String> _departmentsFor(List<Person> persons) {
    final departments =
        persons
            .map((person) => person.department.trim())
            .where((department) => department.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return departments;
  }

  List<Person> _visiblePersons(List<Person> persons) {
    final query = _query.trim().toLowerCase();
    final filtered = persons.where((person) {
      final matchesQuery =
          query.isEmpty ||
          '${person.name} ${person.employeeId} ${person.department}'
              .toLowerCase()
              .contains(query);
      final matchesDepartment =
          _department == 'all' || person.department.trim() == _department;
      return matchesQuery && matchesDepartment;
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case UsersSort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case UsersSort.department:
          final departmentOrder = a.department.toLowerCase().compareTo(
            b.department.toLowerCase(),
          );
          return departmentOrder == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : departmentOrder;
        case UsersSort.recent:
          return b.registeredAt.compareTo(a.registeredAt);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _UsersColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 28.0 : 16.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UsersTopBar(colors: colors, onEnroll: _openEnrollment),
                      const SizedBox(height: 20),
                      BlocBuilder<UsersCubit, UsersState>(
                        builder: (context, state) {
                          return _UsersContent(
                            state: state,
                            colors: colors,
                            searchController: _searchController,
                            selectedDepartment: _department,
                            selectedSort: _sort,
                            departments: state is UsersLoaded
                                ? _departmentsFor(state.persons)
                                : const [],
                            onSearchChanged: (value) {
                              setState(() => _query = value);
                            },
                            onDepartmentChanged: (value) {
                              if (value == null) return;
                              setState(() => _department = value);
                            },
                            onSortChanged: (value) {
                              if (value == null) return;
                              setState(() => _sort = value);
                            },
                            onResetFilters: _resetFilters,
                            onEnroll: _openEnrollment,
                            onRetry: () => context.read<UsersCubit>().load(),
                            onOpenDetails: _openDetails,
                            visiblePersons: state is UsersLoaded
                                ? _visiblePersons(state.persons)
                                : const [],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _PrivacyNote(colors: colors),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UsersContent extends StatelessWidget {
  final UsersState state;
  final _UsersColors colors;
  final TextEditingController searchController;
  final String selectedDepartment;
  final UsersSort selectedSort;
  final List<String> departments;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<UsersSort?> onSortChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onEnroll;
  final VoidCallback onRetry;
  final ValueChanged<Person> onOpenDetails;
  final List<Person> visiblePersons;

  const _UsersContent({
    required this.state,
    required this.colors,
    required this.searchController,
    required this.selectedDepartment,
    required this.selectedSort,
    required this.departments,
    required this.onSearchChanged,
    required this.onDepartmentChanged,
    required this.onSortChanged,
    required this.onResetFilters,
    required this.onEnroll,
    required this.onRetry,
    required this.onOpenDetails,
    required this.visiblePersons,
  });

  @override
  Widget build(BuildContext context) {
    if (state is UsersLoading || state is UsersInitial) {
      return const _UsersLoadingView();
    }

    if (state is UsersError) {
      return _UsersErrorView(colors: colors, onRetry: onRetry);
    }

    final persons = (state as UsersLoaded).persons;
    final departmentsWithAll = ['all', ...departments];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UsersToolbar(
          colors: colors,
          searchController: searchController,
          selectedDepartment: selectedDepartment,
          selectedSort: selectedSort,
          departments: departmentsWithAll,
          onSearchChanged: onSearchChanged,
          onDepartmentChanged: onDepartmentChanged,
          onSortChanged: onSortChanged,
        ),
        const SizedBox(height: 16),
        _ResultsHeader(colors: colors, count: visiblePersons.length),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: persons.isEmpty
              ? _UsersEmptyView(
                  key: const ValueKey('empty-users'),
                  colors: colors,
                  title: 'No users registered yet',
                  message:
                      'Enroll a person to add them to the recognition index.',
                  actionLabel: 'Enroll a person',
                  icon: Icons.person_add_alt_1_rounded,
                  onAction: onEnroll,
                )
              : visiblePersons.isEmpty
              ? _UsersEmptyView(
                  key: const ValueKey('empty-filtered-users'),
                  colors: colors,
                  title: 'No users match this search',
                  message: 'Try another name, employee ID, or department.',
                  actionLabel: 'Clear filters',
                  icon: Icons.manage_search_rounded,
                  onAction: onResetFilters,
                )
              : _UsersList(
                  key: const ValueKey('loaded-users'),
                  colors: colors,
                  persons: visiblePersons,
                  onOpenDetails: onOpenDetails,
                ),
        ),
      ],
    );
  }
}

class _UsersTopBar extends StatelessWidget {
  final _UsersColors colors;
  final VoidCallback onEnroll;

  const _UsersTopBar({required this.colors, required this.onEnroll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: 'Go back',
          child: Tooltip(
            message: 'Go back',
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: colors.text,
              tooltip: 'Go back',
              style: IconButton.styleFrom(
                minimumSize: const Size.square(44),
                backgroundColor: colors.surfaceAlt,
                side: BorderSide(color: colors.border),
                shape: const CircleBorder(),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.success.withValues(alpha: 0.18),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _MicroLabel('LOCAL INDEX READY', color: colors.muted, fontSize: 10),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'Enroll person',
              child: Tooltip(
                message: 'Enroll person',
                child: IconButton(
                  onPressed: onEnroll,
                  icon: const Icon(Icons.add_rounded),
                  color: colors.text,
                  tooltip: 'Enroll person',
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(44),
                    backgroundColor: colors.gold,
                    foregroundColor: colors.darkText,
                    side: BorderSide(color: colors.goldBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsersToolbar extends StatelessWidget {
  final _UsersColors colors;
  final TextEditingController searchController;
  final String selectedDepartment;
  final UsersSort selectedSort;
  final List<String> departments;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<UsersSort?> onSortChanged;

  const _UsersToolbar({
    required this.colors,
    required this.searchController,
    required this.selectedDepartment,
    required this.selectedSort,
    required this.departments,
    required this.onSearchChanged,
    required this.onDepartmentChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: colors.text, fontSize: 14),
          decoration: _fieldDecoration(
            colors,
            hintText: 'Search name, ID, or department',
            prefixIcon: Icons.search_rounded,
          ),
        );
        final department = _FilterDropdown<String>(
          label: 'Filter by department',
          value: selectedDepartment,
          colors: colors,
          items: departments
              .map(
                (department) => DropdownMenuItem<String>(
                  value: department,
                  child: Text(
                    department == 'all' ? 'All departments' : department,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onDepartmentChanged,
        );
        final sort = _FilterDropdown<UsersSort>(
          label: 'Sort users',
          value: selectedSort,
          colors: colors,
          items: const [
            DropdownMenuItem(
              value: UsersSort.recent,
              child: Text('Recently added'),
            ),
            DropdownMenuItem(value: UsersSort.name, child: Text('Name A–Z')),
            DropdownMenuItem(
              value: UsersSort.department,
              child: Text('Department'),
            ),
          ],
          onChanged: onSortChanged,
        );

        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: department),
                  const SizedBox(width: 9),
                  Expanded(child: sort),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 9),
            SizedBox(width: 150, child: department),
            const SizedBox(width: 9),
            SizedBox(width: 142, child: sort),
          ],
        );
      },
    );
  }

  InputDecoration _fieldDecoration(
    _UsersColors colors, {
    required String hintText,
    required IconData prefixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: colors.border),
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colors.mutedLight, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: colors.muted, size: 20),
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.gold, width: 1.5),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final _UsersColors colors;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.colors,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: colors.border),
    );

    return Semantics(
      label: label,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        menuMaxHeight: 320,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.text),
        style: TextStyle(
          color: colors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: colors.gold, width: 1.5),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final _UsersColors colors;
  final int count;

  const _ResultsHeader({required this.colors, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MicroLabel('PEOPLE IN LOCAL INDEX', color: colors.muted, fontSize: 10),
        Text(
          _formatCount(count, 'person', 'people'),
          style: TextStyle(
            color: colors.mutedStrong,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UsersList extends StatelessWidget {
  final _UsersColors colors;
  final List<Person> persons;
  final ValueChanged<Person> onOpenDetails;

  const _UsersList({
    super.key,
    required this.colors,
    required this.persons,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: persons.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, thickness: 1, color: colors.divider),
        itemBuilder: (context, index) {
          final person = persons[index];
          return Dismissible(
            key: ValueKey(person.employeeId),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              _UserRow.showDeleteDialog(
                context,
                person: person,
                colors: colors,
                onConfirm: (deleteFromServer) {
                  context.read<UsersCubit>().deletePerson(
                    person.employeeId,
                    deleteFromServer: deleteFromServer,
                  );
                },
              );
              return false;
            },
            background: _DeleteBackground(colors: colors),
            child: _UserRow(
              person: person,
              colors: colors,
              onTap: () => onOpenDetails(person),
            ),
          );
        },
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  final _UsersColors colors;
  const _DeleteBackground({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Icon(
        Icons.delete_outline_rounded,
        color: Colors.white.withValues(alpha: 0.9),
        size: 24,
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final Person person;
  final _UsersColors colors;
  final VoidCallback onTap;

  const _UserRow({
    required this.person,
    required this.colors,
    required this.onTap,
  });

  static void showDeleteDialog(
    BuildContext context, {
    required Person person,
    required _UsersColors colors,
    required void Function(bool deleteFromServer) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        var deleteFromServer = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: colors.surface,
            surfaceTintColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.border),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete ${person.name}?',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete all face data, embeddings, and images for this person.',
                  style: TextStyle(
                    color: colors.mutedStrong,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () => setDialogState(
                    () => deleteFromServer = !deleteFromServer,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          deleteFromServer
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: deleteFromServer ? colors.error : colors.muted,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Also delete from server',
                                style: TextStyle(
                                  color: colors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'When backend sync is configured, removes remote copy too.',
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onConfirm(deleteFromServer);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAngles = person.faceImagePaths.length;
    final totalShots = person.faceImagePaths.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Semantics(
      button: true,
      label: 'Open ${person.name} details',
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.goldSoft.withValues(alpha: 0.32),
        focusColor: colors.goldSoft.withValues(alpha: 0.32),
        splashColor: colors.gold.withValues(alpha: 0.12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _ProfileAvatar(person: person, colors: colors),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            person.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          _SyncBadge(colors: colors, isSynced: person.isSynced),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${person.employeeId}  ·  ${person.department}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedStrong,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        children: [
                          _MetaChip(
                            label: '$totalAngles angles',
                            colors: colors,
                          ),
                          _MetaChip(label: '$totalShots shots', colors: colors),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.mutedLight,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Person person;
  final _UsersColors colors;

  const _ProfileAvatar({required this.person, required this.colors});

  @override
  Widget build(BuildContext context) {
    final frontPath = _frontImagePath(person);
    if (frontPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(frontPath),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(),
        ),
      );
    }
    return _initialAvatar();
  }

  Widget _initialAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.goldSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: Text(
        person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: colors.goldText,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final _UsersColors colors;
  final bool isSynced;

  const _SyncBadge({required this.colors, required this.isSynced});

  @override
  Widget build(BuildContext context) {
    final background = isSynced ? colors.statusSurface : colors.localSurface;
    final border = isSynced ? colors.statusBorder : colors.localBorder;
    final foreground = isSynced ? colors.success : colors.goldText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: foreground,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? 'Synced' : 'Local only',
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final _UsersColors colors;

  const _MetaChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.mutedStrong,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _UsersLoadingView extends StatelessWidget {
  const _UsersLoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = _UsersColors.of(context);
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.border),
      ),
      child: Column(
        children: List.generate(
          3,
          (index) => Column(
            children: [
              const _SkeletonRow(),
              if (index < 2) Divider(height: 1, color: colors.divider),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colors = _UsersColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 88),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _SkeletonBlock(colors: colors, width: 48, height: 48, radius: 15),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(colors: colors, width: 150, height: 12),
                  const SizedBox(height: 9),
                  _SkeletonBlock(
                    colors: colors,
                    width: double.infinity,
                    height: 10,
                  ),
                  const SizedBox(height: 8),
                  _SkeletonBlock(colors: colors, width: 86, height: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final _UsersColors colors;
  final double width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    required this.colors,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _UsersEmptyView extends StatelessWidget {
  final _UsersColors colors;
  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onAction;

  const _UsersEmptyView({
    super.key,
    required this.colors,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.icon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StateSurface(
      colors: colors,
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _UsersErrorView extends StatelessWidget {
  final _UsersColors colors;
  final VoidCallback onRetry;

  const _UsersErrorView({required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateSurface(
      colors: colors,
      icon: Icons.cloud_off_rounded,
      title: 'Couldn’t load users',
      message:
          'The local index did not respond. Your existing face data is unchanged.',
      actionLabel: 'Try again',
      onAction: onRetry,
      isError: true,
    );
  }
}

class _StateSurface extends StatelessWidget {
  final _UsersColors colors;
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;

  const _StateSurface({
    required this.colors,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isError ? colors.error : colors.muted;
    final background = isError ? colors.errorSurface : colors.surface;
    final iconBackground = isError
        ? colors.errorIconSurface
        : colors.surfaceAlt;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 34),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isError ? colors.errorBorder : colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? colors.errorText : colors.mutedStrong,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: Icon(isError ? Icons.refresh_rounded : icon, size: 18),
            label: Text(actionLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.text,
              backgroundColor: colors.surfaceAlt,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  final _UsersColors colors;

  const _PrivacyNote({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.verified_user_outlined,
            size: 17,
            color: colors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Face data stays on this device until you explicitly sync it with the server.',
            style: TextStyle(color: colors.muted, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _MicroLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _MicroLabel(this.text, {required this.color, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: fontSize <= 10 ? 1.05 : 0.9,
        height: 1,
      ),
    );
  }
}

String _formatCount(int value, String singular, String plural) {
  return '$value ${value == 1 ? singular : plural}';
}

class _UsersColors {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color muted;
  final Color mutedStrong;
  final Color mutedLight;
  final Color border;
  final Color divider;
  final Color gold;
  final Color goldBorder;
  final Color goldSoft;
  final Color goldText;
  final Color success;
  final Color successDark;
  final Color statusSurface;
  final Color statusBorder;
  final Color localSurface;
  final Color localBorder;
  final Color error;
  final Color errorSurface;
  final Color errorIconSurface;
  final Color errorBorder;
  final Color errorText;
  final Color skeleton;
  final Color darkText;

  const _UsersColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.muted,
    required this.mutedStrong,
    required this.mutedLight,
    required this.border,
    required this.divider,
    required this.gold,
    required this.goldBorder,
    required this.goldSoft,
    required this.goldText,
    required this.success,
    required this.successDark,
    required this.statusSurface,
    required this.statusBorder,
    required this.localSurface,
    required this.localBorder,
    required this.error,
    required this.errorSurface,
    required this.errorIconSurface,
    required this.errorBorder,
    required this.errorText,
    required this.skeleton,
    required this.darkText,
  });

  factory _UsersColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _UsersColors(
        background: AppTheme.homeDarkBackground,
        surface: AppTheme.homeDarkSurface,
        surfaceAlt: AppTheme.usersDarkSurfaceAlt,
        text: AppTheme.homeDarkText,
        muted: AppTheme.usersDarkMuted,
        mutedStrong: AppTheme.usersDarkMutedStrong,
        mutedLight: AppTheme.usersDarkMutedLight,
        border: AppTheme.homeDarkBorder,
        divider: AppTheme.usersDarkDivider,
        gold: AppTheme.homeGold,
        goldBorder: AppTheme.usersDarkGoldBorder,
        goldSoft: AppTheme.usersDarkGoldSoft,
        goldText: AppTheme.usersDarkGoldText,
        success: AppTheme.usersDarkSuccess,
        successDark: AppTheme.usersDarkSuccessDark,
        statusSurface: AppTheme.usersDarkStatusSurface,
        statusBorder: AppTheme.usersDarkStatusBorder,
        localSurface: AppTheme.usersDarkLocalSurface,
        localBorder: AppTheme.usersDarkLocalBorder,
        error: AppTheme.usersDarkError,
        errorSurface: AppTheme.usersDarkErrorSurface,
        errorIconSurface: AppTheme.usersDarkErrorIconSurface,
        errorBorder: AppTheme.usersDarkErrorBorder,
        errorText: AppTheme.usersDarkErrorText,
        skeleton: AppTheme.usersDarkSkeleton,
        darkText: AppTheme.homeDarkText,
      );
    }

    return const _UsersColors(
      background: AppTheme.homeLightBackground,
      surface: AppTheme.usersSurface,
      surfaceAlt: AppTheme.homeWarmSurface,
      text: AppTheme.homeLightText,
      muted: AppTheme.usersMuted,
      mutedStrong: AppTheme.usersMutedStrong,
      mutedLight: AppTheme.usersMutedLight,
      border: AppTheme.homeLightBorder,
      divider: AppTheme.usersDivider,
      gold: AppTheme.homeGold,
      goldBorder: AppTheme.usersGoldBorder,
      goldSoft: AppTheme.usersGoldSoft,
      goldText: AppTheme.usersGoldText,
      success: AppTheme.homeStatusGreen,
      successDark: AppTheme.usersSuccessDark,
      statusSurface: AppTheme.usersStatusSurface,
      statusBorder: AppTheme.usersStatusBorder,
      localSurface: AppTheme.usersLocalSurface,
      localBorder: AppTheme.usersLocalBorder,
      error: AppTheme.usersError,
      errorSurface: AppTheme.usersErrorSurface,
      errorIconSurface: AppTheme.usersErrorIconSurface,
      errorBorder: AppTheme.usersErrorBorder,
      errorText: AppTheme.usersErrorText,
      skeleton: AppTheme.usersSkeleton,
      darkText: AppTheme.homeLightText,
    );
  }
}
