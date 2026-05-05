import 'package:venastudio/common.dart';

class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeServicesProvider);
    final branchesService = ref.watch(branchesServicesProvider);

    return Scaffold(
      backgroundColor: theme.secondaryBackGround,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackGround,
        foregroundColor: theme.textIconPrimaryColor,
        centerTitle: true,
        title: const Text('Branches'),
      ),
      body: branchesService.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => emptyState(
          ref,
          text: 'Failed to load branches',
          onRefresh: () => ref.invalidate(branchesServicesProvider),
        ),
        data: (branches) {
          if (branches.isEmpty) {
            return emptyState(
              ref,
              text: 'No branches available',
              onRefresh: () => ref.invalidate(branchesServicesProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(branchesServicesProvider);
            },
            child: LayoutBuilder(
              builder: (context, cs) {
                return ListView.builder(
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return InkWell(
                      onTap: () {
                        EditBranch.show(context, branch).then((value) {
                          if (value == '200') {
                            ref.invalidate(branchesServicesProvider);
                          }
                        });
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Card(
                        color: theme.primaryBackGround,
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            branch['name'] ?? 'No Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.activeTextIconColor,
                            ),
                          ),
                          subtitle: Text(
                            '${branch['location'] ?? 'No Location'}\nPaybill: ${branch['paybill'] ?? 'No Paybill'}',
                            style: TextStyle(color: theme.activeTextIconColor),
                          ),
                          trailing: Icon(
                            Icons.edit_rounded,
                            color: theme.activeTextIconColor,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class EditBranch extends ConsumerStatefulWidget {
  const EditBranch({super.key, required this.branch});
  final Map<dynamic, dynamic> branch;

  static Future<String?> show(
    BuildContext context,
    Map<dynamic, dynamic> branch,
  ) {
    return showDialog<String>(
      context: context,
      builder: (_) {
        return EditBranch(branch: branch);
      },
    );
  }

  @override
  ConsumerState<EditBranch> createState() => _EditBranchState();
}

class _EditBranchState extends ConsumerState<EditBranch> {
  bool isUpdating = false;
  final GlobalKey<FormState> _form = GlobalKey();

  late final TextEditingController _cName = TextEditingController(
    text: widget.branch['name'],
  );
  late final TextEditingController _cLocation = TextEditingController(
    text: widget.branch['location'],
  );
  late final TextEditingController _cTill = TextEditingController(
    text: '${widget.branch['paybill'] ?? ''}',
  );

  @override
  Widget build(BuildContext context) {
    final dWidth = MediaQuery.of(context).size.width;
    final width = dWidth > 400.0 ? 400.0 : dWidth;
    final theme = ref.watch(themeServicesProvider);

    return Center(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cName,
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'Enter branch name'
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          TextFormField(
                            controller: _cLocation,
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'Enter branch location'
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                            ),
                          ),
                          TextFormField(
                            controller: _cTill,
                            keyboardType: TextInputType.number,
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'Enter commission'
                                : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Commission',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: .5,
                    thickness: .5,
                    color: theme.inactiveBackGround,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Consumer(
                      builder: (context, ref, _) {
                        return TextButton(
                          onPressed: isUpdating
                              ? null
                              : () {
                                  if (_form.currentState!.validate()) {
                                    setState(() {
                                      isUpdating = true;
                                    });
                                    _update(ref);
                                  }
                                },
                          style: TextButton.styleFrom(
                            backgroundColor: theme.primaryBackGround,
                            foregroundColor: theme.activeTextIconColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fixedSize: const Size(double.maxFinite, 20),
                          ),
                          child: isUpdating
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: theme.activeBackGround,
                                  ),
                                )
                              : const Text('UPDATE'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _update(WidgetRef ref) async {
    final oldBranch = widget.branch;
    final newBranch = {
      'id': '${oldBranch['id']}',
      'name': _cName.text,
      'location': _cLocation.text,
      'paybill': '${num.tryParse(_cTill.text) ?? oldBranch['paybill']}',
    };
    try {
      await ref.read(branchesServicesProvider.notifier).update(newBranch);
      Navigator.of(context).pop('200');
    } catch (e) {
      setState(() {
        isUpdating = false;
      });
    }
  }
}
