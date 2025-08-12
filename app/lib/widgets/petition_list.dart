import 'package:flutter/material.dart';
import '../models/petition.dart';
import '../components/petition_card.dart';

class PetitionList extends StatelessWidget {
  final List<Petition> petitions;
  final Function(Petition)? onPetitionTap;

  const PetitionList({
    super.key,
    required this.petitions,
    this.onPetitionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (petitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.request_page_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No petitions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first request to connect with local businesses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: petitions.length,
      itemBuilder: (context, index) {
        return PetitionCard(
          petition: petitions[index],
          onTap: () => onPetitionTap?.call(petitions[index]),
        );
      },
    );
  }
}
