import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class OrderSearch extends SearchDelegate {
  final WidgetRef ref;
  OrderSearch({
    required this.orders,
    required this.user,
    required this.theme,
    required this.ref,
  });
  final List<Map<dynamic, dynamic>> orders;
  final ServiceUser? user;
  final ThemeConfig theme;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: theme.secondaryBackGround,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.secondaryBackGround,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textIconPrimaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.secondaryBackGround,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: theme.textIconPrimaryColor),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: theme.textIconPrimaryColor),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
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
    final searched = orders.where((element) {
      final lowerQuery = query.toLowerCase();
      final billno = element['billno'].toString().toLowerCase();
      final agentname = element['agentname'].toString().toLowerCase();
      final ticket = element['receipt'].toString().toLowerCase();
      final phone = element['customer'].toString().toLowerCase();
      return billno.contains(lowerQuery) ||
          agentname.contains(lowerQuery) ||
          ticket.contains(lowerQuery) ||
          phone.contains(lowerQuery);
    }).toList();

    if (searched.isEmpty) {
      String emptyStateText = "No results found ...";
      return emptyState(
        ref,
        text: emptyStateText,
        onRefresh: () => ref.invalidate(orderServicesProvider),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;
        double aspectRatio = constraints.maxWidth > 900
            ? 1.4
            : constraints.maxWidth > 600
            ? 1.5
            : 1.1;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemCount: searched.length,
          itemBuilder: (context, index) {
            final order = searched[index] as Map<String, dynamic>;
            return _buildOrderCard(order, context, false, true);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    BuildContext context,
    bool readonly,
    bool insearch,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        // color: const Color(0xff1f2029),
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.cardGradientStart, theme.cardGradientEnd],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.cardShadowColor.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bill No: ${order['billno'] ?? 'Unknown'}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.activeTextIconColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Amount: ${(order['amount'] ?? 0.0).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.inactiveTextIconColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Agent: ${order['agentname'] ?? 'N/A'}",
                  style: TextStyle(color: theme.inactiveTextIconColor),
                ),
                const SizedBox(height: 8),
                Text(
                  "Receipt: ${order['receipt'] ?? 'N/A'}",
                  style: TextStyle(color: theme.inactiveTextIconColor),
                ),
                const SizedBox(height: 8),
                Text(
                  order['date'] != null
                      ? DateFormat.yMMMEd().format(
                          DateTime.tryParse(order['date']) ?? DateTime.now(),
                        )
                      : "No Date",
                  style: TextStyle(color: theme.inactiveTextIconColor),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          OrderView.show(
                            context,
                            order['id'],
                            readonly: true,
                            insearch: true,
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: theme.secondaryBackGround,
                          foregroundColor: theme.textIconPrimaryColor,
                        ),
                        child: const Text("View"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (insearch) Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/orders/complete/${order['id']}',
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: theme.secondaryBackGround,
                          foregroundColor: theme.textIconPrimaryColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Complete"),
                            SizedBox(width: 8),
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 16,
                              color: theme.textIconPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
