import 'package:venastudio/common.dart';

class ColorCustomizationPage extends ConsumerWidget {
  const ColorCustomizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeServicesProvider);
    final themeNotifier = ref.read(themeServicesProvider.notifier);

    return Scaffold(
      backgroundColor: theme.secondaryBackGround,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackGround,
        foregroundColor: theme.textIconPrimaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textIconPrimaryColor),
        title: Text(
          'Theme Customization',
          style: TextStyle(color: theme.textIconPrimaryColor),
        ),
        actions: [
          Row(
            children: [
              GestureDetector(
                onTap: () => themeNotifier.toggleTheme(),
                child: Text(
                  theme.secondaryBackGround ==
                          ThemeConfig.light().secondaryBackGround
                      ? 'Light Mode'
                      : 'Dark Mode',
                  style: TextStyle(
                    color: theme.textIconPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  theme.secondaryBackGround ==
                          ThemeConfig.light().secondaryBackGround
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: theme.textIconPrimaryColor,
                ),
                onPressed: () => themeNotifier.toggleTheme(),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 500
                      ? 600
                      : constraints.maxWidth,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _PreviewPanel(theme: theme),
                    const SizedBox(height: 30),
                    _buildColorSection(
                      "Navigation Background",
                      theme.primaryBackGround,
                      themeNotifier.setPrimaryBackground,
                      theme,
                    ),
                    _buildColorSection(
                      "Main Background",
                      theme.secondaryBackGround,
                      themeNotifier.setSecondaryBackground,
                      theme,
                    ),
                    _buildColorSection(
                      "Card Gradient Start",
                      theme.cardGradientStart,
                      themeNotifier.setCardGradientStart,
                      theme,
                    ),
                    _buildColorSection(
                      "Card Gradient End",
                      theme.cardGradientEnd,
                      themeNotifier.setCardGradientEnd,
                      theme,
                    ),
                    _buildColorSection(
                      "Card Shadow",
                      theme.cardShadowColor,
                      themeNotifier.setCardShadowColor,
                      theme,
                    ),
                    _buildColorSection(
                      "Button Background",
                      theme.activeBackGround,
                      themeNotifier.setActiveBackground,
                      theme,
                    ),
                    _buildColorSection(
                      "Button/Text Color",
                      theme.activeTextIconColor,
                      themeNotifier.setActiveTextIconColor,
                      theme,
                    ),
                    _buildColorSection(
                      "Success Color",
                      theme.successColor,
                      themeNotifier.setSuccessColor,
                      theme,
                    ),
                    _buildColorSection(
                      "Checkbox Color",
                      theme.checkboxBorderColor,
                      themeNotifier.setCheckboxBorderColor,
                      theme,
                    ),
                    _buildColorSection(
                      "Date Picker Color",
                      theme.datePickerColor,
                      themeNotifier.setDatePickerColor,
                      theme,
                    ),
                    const SizedBox(height: 40),
                    _buildSaveResetRow(ref, theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSection(
    String title,
    Color selected,
    Function(Color) onSelect,
    ThemeConfig theme,
  ) {
    final labelColor = _getContrastingTextColor(theme.secondaryBackGround);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        ColorPickerRow(selected: selected, onSelect: onSelect),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSaveResetRow(WidgetRef ref, ThemeConfig theme) {
    final themeNotifier = ref.read(themeServicesProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            themeNotifier.resetTheme();
            ScaffoldMessenger.of(ref.context).showSnackBar(
              const SnackBar(content: Text("Theme reset to default.")),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text("Reset"),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.activeTextIconColor,
            backgroundColor: theme.primaryBackGround,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // themeNotifier.saveTheme();
            ScaffoldMessenger.of(ref.context).showSnackBar(
              const SnackBar(content: Text("Theme saved successfully!")),
            );
          },
          icon: const Icon(Icons.save),
          label: const Text("Save Theme"),
          style: ElevatedButton.styleFrom(
            foregroundColor: theme.activeTextIconColor,
            backgroundColor: theme.primaryBackGround,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final ThemeConfig theme;
  const _PreviewPanel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.cardGradientStart, theme.cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.cardShadowColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "Live Theme Preview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.activeTextIconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Colors below will reflect how your app UI looks.",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.activeTextIconColor),
          ),
        ],
      ),
    );
  }
}

class ColorPickerRow extends StatelessWidget {
  final Function(Color) onSelect;
  final Color selected;

  const ColorPickerRow({
    super.key,
    required this.onSelect,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.white,
      Colors.black,
      const Color(0xff2832a4), // user preferred blue
    ];

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = color.value == selected.value;
          final labelColor = _getContrastingTextColor(color);

          return GestureDetector(
            onTap: () => onSelect(color),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 48 : 40,
                  height: isSelected ? 48 : 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? labelColor
                          : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: labelColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _colorName(color),
                    style: TextStyle(fontSize: 10, color: labelColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _colorName(Color color) {
    switch (color.value) {
      case 0xFF2196F3:
        return "Blue";
      case 0xFF4CAF50:
        return "Green";
      case 0xFFF44336:
        return "Red";
      case 0xFFFF9800:
        return "Orange";
      case 0xFF009688:
        return "Teal";
      case 0xFFFFC107:
        return "Amber";
      case 0xFFE91E63:
        return "Pink";
      case 0xFFFFFFFF:
        return "White";
      case 0xFF000000:
        return "Black";
      case 0xFF2832A4:
        return "Royal Blue";
      default:
        return "Custom";
    }
  }
}

Color _getContrastingTextColor(Color bgColor) {
  return bgColor.computeLuminance() > 0.6 ? Colors.black : Colors.white;
}
