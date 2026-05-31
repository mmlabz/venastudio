import 'package:venastudio/common.dart';

class PickAgent extends ConsumerStatefulWidget {
  const PickAgent({super.key, required this.agents});
  final List<Agent> agents;

  static Future<Agent?> show(BuildContext context, List<Agent> agents) {
    final mobileSize = SrceenType.type(context.sz).isMobile;
    if (mobileSize) {
      return showSearch<Agent>(
        context: context,
        useRootNavigator: true,
        delegate: MobileAgentSearch(agents: agents),
      );
    }
    return showDialog<Agent>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return PickAgent(agents: agents);
      },
    );
  }

  @override
  ConsumerState<PickAgent> createState() => _PickAgentState();
}

class _PickAgentState extends ConsumerState<PickAgent> {
  final TextEditingController _controller = TextEditingController();
  late List<Agent> agents = List.from(widget.agents);

  @override
  Widget build(BuildContext context) {
    final allWidth = context.sz.width;
    final mWidth = allWidth / 2;
    final width = mWidth < 400.0 ? allWidth : mWidth;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: width,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        readOnly: false,
                        controller: _controller,
                        onChanged: (value) {
                          final searched = widget.agents.where(
                            (element) => element.name.toLowerCase().contains(
                              value.toLowerCase(),
                            ),
                          );
                          setState(() {
                            agents = List.from(searched);
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search agent...',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          agents = List.from(widget.agents);
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 2,
            child: SizedBox(
              width: width - 30,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: agents.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: agents.length,
                        itemBuilder: (context, index) {
                          final agent = agents[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).pop(agent);
                              },
                              title: Text(
                                agent.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (agent.store != null)
                                    Text(
                                      agent.store!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  Text(
                                    agent.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text('No agents found')),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class MobileAgentSearch extends SearchDelegate<Agent> {
  MobileAgentSearch({required this.agents});
  final List<Agent> agents;
  @override
  List<Widget>? buildActions(BuildContext context) {
    return null;
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildOutput();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildOutput();
  }

  Widget _buildOutput() {
    final searched = agents.where(
      (element) =>
          element.name.toString().toLowerCase().contains(query.toLowerCase()),
    );
    return LayoutBuilder(
      builder: (_, cs) {
        final maxWidth = getMaxWidth(cs.maxWidth);
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: maxWidth,
            child: ListView.builder(
              itemCount: searched.length,
              itemBuilder: (context, index) {
                final item = searched.elementAt(index);
                return ListTile(
                  onTap: () {
                    Navigator.of(context).pop(item);
                  },
                  isThreeLine: true,
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.store != null) Text(item.store!),
                      Text(
                        item.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
