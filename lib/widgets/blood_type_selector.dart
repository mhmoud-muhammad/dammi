import 'package:flutter/material.dart';

import '../core/blood_types.dart';
import '../core/theme.dart';

/// شبكة 4×2 لاختيار فصيلة الدم.
class BloodTypeSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const BloodTypeSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // الفصائل تُكتب من اليسار لليمين حتى تظهر "+" و "-" في مكانها الصحيح.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
        children: [
          for (final type in kBloodTypes)
            _TypeButton(
              type: type,
              selected: type == value,
              onTap: () => onChanged(type),
            ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.primaryDark : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
