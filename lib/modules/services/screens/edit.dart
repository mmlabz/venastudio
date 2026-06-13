import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class EditSavisPage extends ConsumerStatefulWidget {
  const EditSavisPage({super.key, this.savis});
  final Savis? savis;

  static Future<String?> show(BuildContext context, [Savis? savis]) {
    return showDialog<String>(
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      context: context,
      builder: (_) => EditSavisPage(savis: savis),
    );
  }

  @override
  ConsumerState<EditSavisPage> createState() => _EditSavisPageState();
}

class _EditSavisPageState extends ConsumerState<EditSavisPage> {
  bool isupdating = false;
  File? _selectedImage;
  late bool _isVisible = widget.savis?.isVisible ?? true;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  late final TextEditingController _cName = TextEditingController(
    text: widget.savis?.name.value,
  );
  late final TextEditingController _cAmount = TextEditingController(
    text: widget.savis?.amount.toString().value,
  );
  late final TextEditingController _cCommission = TextEditingController(
    text: widget.savis?.commission.toString().value,
  );
  late final TextEditingController _cDiscount = TextEditingController(
    text: widget.savis?.discount.toString().value,
  );
  late final TextEditingController _cQuantity = TextEditingController(
    text: widget.savis?.quantity.toString().value,
  );
  late final TextEditingController _cType = TextEditingController(
    text: toBeginningOfSentenceCase(widget.savis?.type.toString().value),
  );
  late final TextEditingController _cDiscountDuration = TextEditingController(
    text: () {
      final start = DateTime.tryParse(widget.savis?.discountStartDate ?? '');
      final end = DateTime.tryParse(widget.savis?.discountEndDate ?? '');
      if (start != null && end != null) {
        return '${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}';
      }
      return '';
    }(),
  );

  late DateTime? startDate = DateTime.tryParse(
    widget.savis?.discountStartDate ?? '',
  );
  late DateTime? endDate = DateTime.tryParse(
    widget.savis?.discountEndDate ?? '',
  );

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffBFEFF5);
  static const Color venaBg = Color(0xffEEF9FB);

  @override
  void dispose() {
    _cName.dispose();
    _cAmount.dispose();
    _cCommission.dispose();
    _cDiscount.dispose();
    _cQuantity.dispose();
    _cType.dispose();
    _cDiscountDuration.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;

    final lower = path.toLowerCase();
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    if (!isImage) {
      if (!mounted) return;
      final theme = ref.read(themeServicesProvider);
      context.showToast(
        'Please select a valid image file',
        error: true,
        textColor: theme.textIconPrimaryColor,
      );
      return;
    }

    setState(() => _selectedImage = File(path));
  }

  @override
  Widget build(BuildContext context) {
    final dWidth = context.sz.width;
    final width = dWidth > 460.0 ? 460.0 : dWidth;
    final theme = ref.watch(themeServicesProvider);

    return Center(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.savis == null ? 'Add Service' : 'Edit Service',
                            style: const TextStyle(
                              color: venaDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          _imagePickerPreview(),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _cName,
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true) ? '' : null,
                            decoration: const InputDecoration(labelText: 'Name'),
                          ),
                          TextFormField(
                            controller: _cAmount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true) ? '' : null,
                            decoration: const InputDecoration(labelText: 'Price'),
                          ),
                          TextFormField(
                            controller: _cCommission,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Commission'),
                          ),
                          TextFormField(
                            controller: _cDiscount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Discount'),
                          ),
                          TextFormField(
                            controller: _cDiscountDuration,
                            readOnly: true,
                            onTap: () {
                              showDateRangePicker(
                                useRootNavigator: false,
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 400)),
                              ).then((value) {
                                if (value != null) {
                                  startDate = value.start;
                                  endDate = value.end;
                                  _cDiscountDuration.text =
                                      '${DateFormat.yMMMd().format(value.start)} - ${DateFormat.yMMMd().format(value.end)}';
                                }
                              });
                            },
                            decoration: const InputDecoration(labelText: 'Discount duration'),
                          ),
                          TextFormField(
                            controller: _cQuantity,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Quantity'),
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Service type',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: _cType.text.isEmpty ? null : _cType.text,
                            hint: const Text('Tap to select'),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Service type required';
                              return null;
                            },
                            items: ['Main', 'Addon']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (newValue) {
                              if (newValue != null) _cType.text = newValue;
                            },
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isVisible ? venaTeal.withOpacity(0.08) : const Color(0xffFFF3F3),
                              border: Border.all(
                                color: _isVisible ? venaLine : const Color(0xffF0B7B7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: _isVisible ? venaTeal : const Color(0xffD94B4B),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isVisible ? 'Visible in Catalog' : 'Hidden from Catalog',
                                        style: const TextStyle(
                                          color: venaDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _isVisible
                                            ? 'Customers and staff can select this service.'
                                            : 'Use this for duplicate or inactive services.',
                                        style: const TextStyle(
                                          color: venaMuted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _isVisible,
                                  activeColor: venaTeal,
                                  onChanged: (value) => setState(() => _isVisible = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: .5, thickness: .5, color: theme.inactiveBackGround),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextButton(
                      onPressed: isupdating
                          ? null
                          : () {
                              if (_form.currentState!.validate()) {
                                setState(() => isupdating = true);
                                _update(ref);
                              }
                            },
                      style: TextButton.styleFrom(
                        backgroundColor: theme.primaryBackGround,
                        foregroundColor: theme.activeTextIconColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        fixedSize: const Size(double.maxFinite, 44),
                      ),
                      child: isupdating
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: theme.activeTextIconColor,
                              ),
                            )
                          : Text(widget.savis == null ? 'ADD' : 'UPDATE'),
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

  Widget _imagePickerPreview() {
    final currentImage = widget.savis?.image.trim() ?? '';

    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: venaBg,
          border: Border.all(color: venaLine),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, fit: BoxFit.cover)
            else if (currentImage.isNotEmpty)
              Image.network(
                currentImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _emptyImage(),
              )
            else
              _emptyImage(),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  border: Border.all(color: venaLine),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, color: venaTeal, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Attach Image',
                      style: TextStyle(
                        color: venaDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyImage() {
    return Container(
      color: venaBg,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: venaTeal, size: 36),
          SizedBox(height: 8),
          Text(
            'Tap to attach service image',
            style: TextStyle(color: venaMuted, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Future<void> _update(WidgetRef ref) async {
    final theme = ref.watch(themeServicesProvider);
    try {
      final oldsavis = widget.savis;
      final newSavis = Savis(
        id: oldsavis?.id ?? 0,
        name: _cName.text.trim(),
        amount: num.tryParse(_cAmount.text) ?? oldsavis?.amount ?? 0,
        discount: num.tryParse(_cDiscount.text) ?? oldsavis?.discount ?? 0,
        commission: num.tryParse(_cCommission.text) ?? oldsavis?.commission ?? 0,
        hours: oldsavis?.hours ?? 0,
        minutes: oldsavis?.minutes ?? 0,
        type: _cType.text,
        quantity: num.tryParse(_cQuantity.text) ?? oldsavis?.quantity ?? 0,
        discountStartDate: startDate?.toString() ?? '',
        discountEndDate: endDate?.toString() ?? '',
        image: oldsavis?.image ?? '',
        availability: _isVisible ? 1 : 0,
      );

      if (widget.savis == null) {
        await ref.read(businessServicesProvider.notifier).add(
              newSavis,
              imageFile: _selectedImage,
            );
      } else {
        await ref.read(businessServicesProvider.notifier).update(
              newSavis,
              imageFile: _selectedImage,
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop('200');
    } catch (e) {
      if (!mounted) return;
      context.showToast(
        'Unable to update',
        error: true,
        textColor: theme.textIconPrimaryColor,
      );
      setState(() => isupdating = false);
    }
  }
}
