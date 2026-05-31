import 'package:venastudio/common.dart';

class AgentsPage extends ConsumerStatefulWidget {
  const AgentsPage({super.key});

  @override
  ConsumerState<AgentsPage> createState() => _AgentsPageState();
}

class _AgentsPageState extends ConsumerState<AgentsPage> {
  String selectedType = 'ALL';
  String selectedStatus = 'ALL';
  String sortOption = 'A-Z';
  bool ascending = true;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  final List<String> types = ['ALL', 'SuperAdmin', 'FrontOffice', 'Employee'];
  final List<String> statuses = ['ALL', 'ACTIVE', 'INACTIVE'];
  final List<String> sortOptions = ['A-Z', 'Z-A'];

  @override
  Widget build(BuildContext context) {
    final agentsState = ref.watch(agentsServicesProvider);
    final branches = ref.watch(branchesServicesProvider).value;
    final settings = ref.watch(settingsServicesProvider);
    final user = ref.watch(authenticationServiceProvider).valueOrNull?.user;

    final showFAB =
        (settings.createAttendant && user?.type == FRONTOFFICE_TYPE_NAME) ||
            user?.type == SUPERADMIN_TYPE_NAME;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        centerTitle: true,
        leading: context.backIcon(ref, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/settings');
          }
        }),
        title: const Text(
          'Agents',
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: venaDark),
            onPressed: () {
              showSearch(
                context: context,
                useRootNavigator: false,
                delegate: AgentsSearch(
                  agents: agentsState.value ?? [],
                  branches: branches,
                  updateAgent: (_) => ref.invalidate(agentsServicesProvider),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
          ),
        ),
        child: agentsState.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: venaTeal)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: venaDanger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          data: (agents) => _buildAgentsList(agents, branches),
        ),
      ),
      floatingActionButtonLocation:
          showFAB ? FloatingActionButtonLocation.endFloat : null,
      floatingActionButton: showFAB ? _floatingBtn() : null,
    );
  }

  Widget _buildAgentsList(
    List<Agent> agents,
    List<Map<dynamic, dynamic>>? branches,
  ) {
    final filtered = _filteredAgents(agents);

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: filtered.isEmpty
              ? emptyState(ref, text: 'No agents available')
              : RefreshIndicator(
                  color: venaTeal,
                  onRefresh: () async {
                    ref.invalidate(agentsServicesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _agentCard(filtered[index], branches);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 520;

          final typeDropdown = _buildDropdown(
            label: 'Type',
            value: selectedType,
            items: types,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedType = value);
            },
          );

          final statusDropdown = _buildDropdown(
            label: 'Status',
            value: selectedStatus,
            items: statuses,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedStatus = value);
            },
          );

          final sortDropdown = _buildDropdown(
            label: 'Sort',
            value: sortOption,
            items: sortOptions,
            onChanged: (value) {
              if (value == null) return;
              setState(() => sortOption = value);
            },
          );

          if (isSmall) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: typeDropdown),
                    const SizedBox(width: 8),
                    Expanded(child: statusDropdown),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: sortDropdown),
                    const SizedBox(width: 8),
                    _sortButton(),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: typeDropdown),
              const SizedBox(width: 10),
              Expanded(child: statusDropdown),
              const SizedBox(width: 10),
              Expanded(child: sortDropdown),
              const SizedBox(width: 10),
              _sortButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _sortButton() {
    return InkWell(
      onTap: () => setState(() => ascending = !ascending),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: venaTeal.withOpacity(0.10),
          border: Border.all(color: venaTeal.withOpacity(0.28)),
        ),
        child: Icon(
          ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: venaTeal,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 44,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: venaMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaLine),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaLine),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: venaDark,
              size: 18,
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: venaDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  List<Agent> _filteredAgents(List<Agent> agents) {
    List<Agent> filtered = List<Agent>.from(agents);

    if (selectedType != 'ALL') {
      filtered = filtered.where((agent) => agent.type == selectedType).toList();
    }

    if (selectedStatus != 'ALL') {
      filtered = filtered.where((agent) {
        return selectedStatus == 'ACTIVE' ? !agent.archived : agent.archived;
      }).toList();
    }

    filtered.sort((a, b) {
      final comparison = sortOption == 'A-Z'
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name);

      return ascending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _agentCard(Agent agent, List<Map<dynamic, dynamic>>? branches) {
    final isActive = !agent.archived;
    final initial =
        agent.name.trim().isNotEmpty ? agent.name.trim()[0].toUpperCase() : 'N';

    return InkWell(
      onTap: () {
        EditAgent.show(context, agent, branches).then((value) {
          if (value == '200') {
            ref.invalidate(agentsServicesProvider);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          border: Border.all(color: venaLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: venaTeal.withOpacity(0.12),
                    border: Border.all(color: venaTeal.withOpacity(0.28)),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: venaTeal,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    agent.name.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                _statusPill(isActive),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    EditAgent.show(context, agent, branches).then((value) {
                      if (value == '200') {
                        ref.invalidate(agentsServicesProvider);
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: venaDark,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _agentInfoCards(agent),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _miniTag('PIN ••••'),
                _miniTag(agent.type),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? venaSuccess.withOpacity(0.10)
            : venaDanger.withOpacity(0.10),
        border: Border.all(
          color: active
              ? venaSuccess.withOpacity(0.30)
              : venaDanger.withOpacity(0.30),
        ),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: active ? venaSuccess : venaDanger,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _agentInfoCards(Agent agent) {
    final info = <_AgentInfo>[
      _AgentInfo(Icons.email_outlined, 'Email', agent.email),
      _AgentInfo(Icons.phone_outlined, 'Phone', agent.phone),
      _AgentInfo(Icons.badge_outlined, 'National ID', 'ID: ${agent.userID}'),
      if ((agent.store ?? '').trim().isNotEmpty)
        _AgentInfo(Icons.storefront_outlined, 'Store', agent.store ?? ''),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 430;

        if (mobile) {
          return Column(
            children: info.map((item) {
              return _infoRow(item.icon, item.value);
            }).toList(),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: info.map((item) {
            return SizedBox(
              width: (constraints.maxWidth - 8) / 2,
              child: _infoCard(item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _infoCard(_AgentInfo item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: venaBg.withOpacity(0.58),
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: venaTeal.withOpacity(0.10),
              border: Border.all(color: venaTeal.withOpacity(0.22)),
            ),
            child: Icon(item.icon, size: 15, color: venaTeal),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: venaMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: venaMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: venaTeal.withOpacity(0.08),
        border: Border.all(color: venaTeal.withOpacity(0.22)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: venaDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _floatingBtn() {
    return FloatingActionButton.extended(
      backgroundColor: venaTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Add Agent',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      onPressed: () {
        EditAgent.show(context).then((value) {
          if (value == '200') {
            ref.invalidate(agentsServicesProvider);
          }
        });
      },
    );
  }
}

class _AgentInfo {
  const _AgentInfo(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class AgentsSearch extends SearchDelegate {
  AgentsSearch({
    required this.agents,
    required this.updateAgent,
    this.branches,
  });

  final List<Agent> agents;
  final Function(Agent) updateAgent;
  final List<Map<dynamic, dynamic>>? branches;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: venaBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: venaBg,
        elevation: 0,
        iconTheme: IconThemeData(color: venaDark),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: venaMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: venaLine),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  Widget _buildResults(BuildContext context) {
    final q = query.toLowerCase().trim();

    final results = agents.where((agent) {
      return agent.name.toLowerCase().contains(q) ||
          agent.email.toLowerCase().contains(q) ||
          agent.phone.toLowerCase().contains(q) ||
          (agent.store ?? '').toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No agent found',
          style: TextStyle(color: venaMuted, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Container(
      color: venaBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return _agentCard(results[index], context);
        },
      ),
    );
  }

  Widget _agentCard(Agent agent, BuildContext context) {
    final isActive = !agent.archived;
    final initial =
        agent.name.trim().isNotEmpty ? agent.name.trim()[0].toUpperCase() : 'N';

    return InkWell(
      onTap: () {
        EditAgent.show(context, agent, branches).then((value) {
          if (value == '200') {
            updateAgent(agent);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          border: Border.all(color: venaLine),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: venaTeal.withOpacity(0.12),
                border: Border.all(color: venaTeal.withOpacity(0.28)),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: venaTeal,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    agent.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: venaMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isActive ? 'ACTIVE' : 'INACTIVE',
              style: TextStyle(
                color: isActive ? venaSuccess : venaDanger,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditAgent extends StatefulWidget {
  const EditAgent({this.agent, super.key, this.loadedShops});

  final Agent? agent;
  final List<Map<dynamic, dynamic>>? loadedShops;

  static Future<String?> show(
    BuildContext context, [
    Agent? agent,
    List<Map<dynamic, dynamic>>? loadedShops,
  ]) {
    return showDialog<String>(
      useRootNavigator: false,
      context: context,
      builder: (_) {
        return EditAgent(agent: agent, loadedShops: loadedShops);
      },
    );
  }

  @override
  State<EditAgent> createState() => _EditAgentState();
}

class _EditAgentState extends State<EditAgent> {
  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);

  bool isupdating = false;
  final GlobalKey<FormState> _form = GlobalKey();

  late final TextEditingController _cName = TextEditingController(
    text: widget.agent?.name ?? '',
  );
  late final TextEditingController _cEmail = TextEditingController(
    text: widget.agent?.email ?? '',
  );
  late final TextEditingController _cPhone = TextEditingController(
    text: widget.agent?.phone ?? '',
  );
  late final TextEditingController _cId = TextEditingController(
    text: widget.agent?.userID.toString() ?? '',
  );
  late final TextEditingController _cPin = TextEditingController(
    text: widget.agent?.pin.toString() ?? '',
  );
  late final TextEditingController _cCommission = TextEditingController(
    text: widget.agent?.commission.toString() ?? '',
  );
  late final TextEditingController _cType = TextEditingController(
    text: widget.agent?.type ?? 'Employee',
  );

  late num shopId = _toNum(widget.agent?.shop);

  late final TextEditingController _cShop = TextEditingController(
    text: _initialShopName(),
  );

  late bool archived = widget.agent?.archived ?? false;

  num _toNum(dynamic value) {
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _initialShopName() {
    final agentStoreName = widget.agent?.store?.toString() ?? '';
    final agentBranchId = _toNum(widget.agent?.shop);
    final shops = widget.loadedShops ?? [];

    for (final shop in shops) {
      final id = _toNum(shop['id']);
      final name = shop['name']?.toString() ?? '';

      if (agentBranchId > 0 && id == agentBranchId) {
        shopId = id;
        return name;
      }

      if (agentStoreName.isNotEmpty && name == agentStoreName) {
        shopId = id;
        return name;
      }
    }

    return agentStoreName;
  }

  @override
  void dispose() {
    _cName.dispose();
    _cEmail.dispose();
    _cPhone.dispose();
    _cId.dispose();
    _cPin.dispose();
    _cCommission.dispose();
    _cType.dispose();
    _cShop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dWidth = context.sz.width;
    final width = dWidth > 460.0 ? 460.0 : dWidth - 24;

    return Center(
      child: SizedBox(
        width: width,
        child: Consumer(
          builder: (context, ref, _) {
            final branchesService = ref.watch(branchesServicesProvider);

            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.98),
                  border: Border.all(color: venaLine),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _header(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _form,
                          child: Column(
                            children: [
                              _input(_cName, 'Name'),
                              _input(_cEmail, 'Email'),
                              _input(_cPhone, 'Phone number'),
                              _input(
                                _cPin,
                                'Pin',
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              _input(
                                _cId,
                                'National ID',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              branchesService.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: LinearProgressIndicator(
                                    color: venaTeal,
                                  ),
                                ),
                                error: (_, __) => const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'Unable to load shops',
                                    style: TextStyle(
                                      color: venaDanger,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                data: (data) {
                                  return _input(
                                    _cShop,
                                    'Shop',
                                    readOnly: true,
                                    suffixIcon:
                                        Icons.keyboard_arrow_down_rounded,
                                    onTap: () {
                                      SelectShop.show(context, data).then((
                                        value,
                                      ) {
                                        if (value == null) return;

                                        setState(() {
                                          shopId = _toNum(value['id']);
                                          _cShop.text =
                                              value['name']?.toString() ?? '';
                                        });
                                      });
                                    },
                                  );
                                },
                              ),
                              _input(
                                _cCommission,
                                'Commission',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                              ),
                              _input(
                                _cType,
                                'User level',
                                readOnly: true,
                                suffixIcon: Icons.keyboard_arrow_down_rounded,
                                onTap: () async {
                                  final value = await showUserTypes(context);
                                  if (!mounted || value == null) return;

                                  setState(() {
                                    _cType.text = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Agent Archived',
                                  style: TextStyle(
                                    color: venaDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                                value: archived,
                                activeColor: venaTeal,
                                onChanged: (value) {
                                  setState(() => archived = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      _footer(ref),
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

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: venaTeal.withOpacity(0.08),
        border: const Border(bottom: BorderSide(color: venaLine)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: venaTeal.withOpacity(0.12),
              border: Border.all(color: venaTeal.withOpacity(0.30)),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: venaTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.agent == null ? 'Add Agent' : 'Edit Agent',
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close_rounded, color: venaDark),
          ),
        ],
      ),
    );
  }

  Widget _footer(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: venaLine)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: TextButton(
          onPressed: isupdating
              ? null
              : () {
                  if (_form.currentState!.validate()) {
                    _update(ref);
                  }
                },
          style: TextButton.styleFrom(
            backgroundColor: venaTeal,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: isupdating
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.agent == null ? 'ADD AGENT' : 'UPDATE AGENT',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: (value) {
          if ((value?.trim().isEmpty ?? true)) return 'Required';

          if (label == 'Email' && !(value?.contains('@') ?? false)) {
            return 'Invalid email';
          }

          return null;
        },
        onTap: onTap,
        style: const TextStyle(color: venaDark, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: venaMuted,
            fontWeight: FontWeight.w700,
          ),
          suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
          suffixIconColor: venaMuted,
          filled: true,
          fillColor: venaBg.withOpacity(0.65),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaLine),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaTeal, width: 1.4),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaDanger),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaDanger, width: 1.4),
          ),
        ),
      ),
    );
  }

  void _update(WidgetRef ref) {
    if (shopId <= 0) {
      final theme = ref.read(themeServicesProvider);
      context.showToast(
        'Please select a shop',
        textColor: theme.textIconPrimaryColor,
        error: true,
      );
      return;
    }

    setState(() => isupdating = true);

    final theme = ref.read(themeServicesProvider);

    final newAgent = Agent(
      id: widget.agent?.id ?? 0,
      name: _cName.text.trim(),
      email: _cEmail.text.trim(),
      phone: _cPhone.text.trim(),
      archived: archived,
      pin: num.tryParse(_cPin.text.trim()) ?? 0,
      commission: num.tryParse(_cCommission.text.trim()) ?? 0,
      shop: shopId,
      userID: num.tryParse(_cId.text.trim()) ?? 0,
      type: _cType.text.trim(),
      store: _cShop.text.trim(),
    );

    final Future<void> action = widget.agent != null
        ? ref
            .read(agentsServicesProvider.notifier)
            .update(agent: newAgent, shop: _cShop.text.trim())
        : ref
            .read(agentsServicesProvider.notifier)
            .add(agent: newAgent, shop: _cShop.text.trim());

    action.then((_) {
      if (!mounted) return;

      Navigator.of(context).pop('200');
      ref.invalidate(agentsServicesProvider);

      context.showToast(
        widget.agent == null ? 'Agent added' : 'Agent updated',
        textColor: theme.textIconPrimaryColor,
      );
    }).onError((error, stackTrace) {
      if (!mounted) return;

      setState(() => isupdating = false);

      context.showToast(
        'Unable to save agent',
        textColor: theme.textIconPrimaryColor,
        error: true,
      );
    });
  }

  Future<String?> showUserTypes(BuildContext context) {
    final levels = <String>[
      'Employee',
      'FrontOffice',
      'SuperAdmin',
    ];

    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: venaLine),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: levels.map((level) {
                final selected = _cType.text.trim() == level;

                return InkWell(
                  onTap: () {
                    Navigator.of(sheetContext).pop(level);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: venaLine)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            level,
                            style: TextStyle(
                              color: selected ? venaTeal : venaDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: venaTeal,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
