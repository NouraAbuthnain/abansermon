import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/mosque_card.dart';

class MosqueSelectionSheet extends StatelessWidget {
  final List<Map<String, dynamic>> mosques;

  const MosqueSelectionSheet({super.key, required this.mosques});

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.doveGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            'Select Mosque to Capture',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a mosque context before establishing stream.',
            style: TextStyle(color: AppColors.slate, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          if (mosques.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No mosques available near you for capture.',
                style: TextStyle(color: AppColors.slate),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mosques.length,
                itemBuilder: (context, index) {
                  final m = mosques[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: MosqueCardWidget(
                      name: m['name'],
                      address: m['address'],
                      distance: m['distance'],
                      status: m['status'],
                      onTap: () {
                        // Dismiss modal and push capture screen with specific ID
                        Navigator.pop(context);
                        context.push('/capture/${m['id']}');
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
