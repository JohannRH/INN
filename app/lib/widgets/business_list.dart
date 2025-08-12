import 'package:flutter/material.dart';
import '../models/business.dart';
import '../components/business_card.dart';

class BusinessList extends StatelessWidget {
  final List<Business> businesses;

  const BusinessList({
    super.key,
    required this.businesses
  });

  @override
  Widget build(BuildContext context) {
    if (businesses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Text(
            'No businesses found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: businesses.map((b) {
        return BusinessCard(
          business: b,
        );
      }).toList(),
    );
  }
}
