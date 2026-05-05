import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class CartClientSection extends StatefulWidget {
  const CartClientSection({
    super.key,
    required this.theme,
    required this.formKey,
    required this.cPhoneClient,
    required this.user,
    required this.cShopName,
    required this.cAgentName,
    required this.branchesService,
    required this.agentsService,
    required this.onPhoneChanged,
    required this.onBranchTap,
    required this.onAgentTap,
    required this.isAbooking,
    required this.onBookingStatusChange,
    required this.bookingDate,
    required this.onBookingDateSelected,
  });

  final ThemeConfig theme;
  final GlobalKey<FormState> formKey;
  final TextEditingController cPhoneClient;
  final ServiceUser? user;
  final TextEditingController cShopName;
  final TextEditingController cAgentName;
  final AsyncValue<List<Map<dynamic, dynamic>>> branchesService;
  final AsyncValue<List<Agent>> agentsService;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<List<Map<dynamic, dynamic>>> onBranchTap;
  final ValueChanged<List<Agent>> onAgentTap;
  final bool isAbooking;
  final VoidCallback onBookingStatusChange;
  final DateTime? bookingDate;
  final ValueChanged<DateTime?> onBookingDateSelected;

  @override
  State<CartClientSection> createState() => _CartClientSectionState();
}

class _CartClientSectionState extends State<CartClientSection> {
  late FocusNode phoneFocusNode;

  @override
  void initState() {
    super.initState();
    phoneFocusNode = FocusNode();
  }

  @override
  void dispose() {
    phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Client Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textIconPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: widget.cPhoneClient,
                  label: 'Phone Number',
                  keyboardType: TextInputType.number,
                  onChanged: widget.onPhoneChanged,
                  focusNode: phoneFocusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.length != 10) {
                      return 'Phone number must be 10 digits';
                    }
                    if (!value.startsWith('0')) {
                      return 'Phone number must start with 0';
                    }
                    return null;
                  },
                ),
                if (widget.user?.type == SUPERADMIN_TYPE_NAME)
                  const SizedBox(height: 16),
                if (widget.user?.type == SUPERADMIN_TYPE_NAME)
                  _buildBranchField(context),
                const SizedBox(height: 16),
                _buildAgentField(context),
                const SizedBox(height: 16),
                _buildBookingSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      showCursor: true,
      focusNode: focusNode,
      onTap: () => focusNode?.requestFocus(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.theme.textIconPrimaryColor),
      ),
      style: TextStyle(color: widget.theme.textIconPrimaryColor),
    );
  }

  Widget _buildSelectableField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.theme.textIconPrimaryColor),
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: widget.theme.textIconPrimaryColor,
        ),
      ),
      style: TextStyle(color: widget.theme.textIconPrimaryColor),
    );
  }

  Widget _buildBranchField(BuildContext context) {
    return widget.branchesService.when(
      loading: () => _buildLoadingIndicator('Select Shop'),
      error: (error, stackTrace) => _buildErrorText('Unable to load shops'),
      data: (data) => _buildSelectableField(
        controller: widget.cShopName,
        label: 'Select Shop',
        onTap: () => widget.onBranchTap(data),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please select a shop';
          return null;
        },
      ),
    );
  }

  Widget _buildAgentField(BuildContext context) {
    return widget.agentsService.when(
      loading: () => _buildLoadingIndicator('Assign One Agent'),
      error: (error, stackTrace) => _buildErrorText('Unable to load agents'),
      data: (data) => _buildSelectableField(
        controller: widget.cAgentName,
        label: 'Assign One Agent',
        onTap: () => widget.onAgentTap(data.where((e) => !e.archived).toList()),
      ),
    );
  }

  Widget _buildBookingSection(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    final theme = container.read(themeServicesProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.secondaryBackGround,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: widget.isAbooking
                ? () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      initialDate:
                          widget.bookingDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            primaryColor: theme.textIconPrimaryColor,
                            hintColor: theme.textIconPrimaryColor,
                            dialogBackgroundColor: theme.secondaryBackGround,
                            textTheme: TextTheme(
                              bodyMedium: TextStyle(
                                color: theme.textIconPrimaryColor,
                              ),
                            ),
                            colorScheme: ColorScheme.dark(
                              primary: Colors.blueAccent,
                              onPrimary: theme.textIconPrimaryColor,
                              surface: theme.secondaryBackGround,
                              onSurface: theme.textIconPrimaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (date != null) {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              primaryColor: theme.textIconPrimaryColor,
                              hintColor: theme.textIconPrimaryColor,
                              dialogBackgroundColor: theme.secondaryBackGround,
                              textTheme: TextTheme(
                                bodyMedium: TextStyle(
                                  color: theme.textIconPrimaryColor,
                                ),
                              ),
                              colorScheme: ColorScheme.dark(
                                primary: Colors.blueAccent,
                                onPrimary: theme.textIconPrimaryColor,
                                surface: theme.secondaryBackGround,
                                onSurface: theme.textIconPrimaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (time != null) {
                        widget.onBookingDateSelected(
                          DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    }
                  }
                : null,
            style: TextButton.styleFrom(
              foregroundColor: widget.isAbooking
                  ? theme.textIconPrimaryColor
                  : theme.textIconSecondaryColor,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Text(
              widget.bookingDate != null
                  ? DateFormat('d MMM yyyy, h:mm a').format(widget.bookingDate!)
                  : 'Select Booking Date',
              style: TextStyle(
                color: widget.isAbooking
                    ? theme.textIconPrimaryColor
                    : theme.textIconSecondaryColor,
              ),
            ),
          ),
          Switch(
            value: widget.isAbooking,
            onChanged: (value) => widget.onBookingStatusChange(),
            activeColor: Colors.blueAccent,
            inactiveTrackColor: theme.secondaryBackGround,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.theme.textIconPrimaryColor,
          ),
        ),
        const SizedBox(height: 10),
        const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildErrorText(String errorText) {
    return Text(
      errorText,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: widget.theme.deleteColor,
      ),
    );
  }
}
