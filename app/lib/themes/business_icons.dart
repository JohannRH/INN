import 'package:flutter/material.dart';

class BusinessCategoryStyle {
  final Color color;
  final IconData icon;

  BusinessCategoryStyle({required this.color, required this.icon});
}

final Map<int, BusinessCategoryStyle> categoryStyles = {
  1: BusinessCategoryStyle(color: Colors.orange, icon: Icons.fastfood), // Alimentación
  2: BusinessCategoryStyle(color: Colors.blue, icon: Icons.local_hospital), // Salud
  3: BusinessCategoryStyle(color: Colors.green, icon: Icons.work), // Profesionales
  4: BusinessCategoryStyle(color: Colors.deepPurple, icon: Icons.school), // Educación
  5: BusinessCategoryStyle(color: Colors.teal, icon: Icons.store), // Comercio
  6: BusinessCategoryStyle(color: Colors.brown, icon: Icons.car_repair), // Automotriz
  7: BusinessCategoryStyle(color: Colors.pink, icon: Icons.movie), // Entretenimiento
  8: BusinessCategoryStyle(color: Colors.indigo, icon: Icons.hotel), // Hotelería
  9: BusinessCategoryStyle(color: Colors.redAccent, icon: Icons.home_repair_service), // Domésticos
  10: BusinessCategoryStyle(color: Colors.cyan, icon: Icons.computer), // Tecnología
  11: BusinessCategoryStyle(color: Colors.amber, icon: Icons.local_shipping), // Transporte
  12: BusinessCategoryStyle(color: Colors.lightGreen, icon: Icons.account_balance), // Financieros
  13: BusinessCategoryStyle(color: Colors.lime, icon: Icons.agriculture), // Agro
  14: BusinessCategoryStyle(color: Colors.grey, icon: Icons.factory), // Manufactura
  15: BusinessCategoryStyle(color: Colors.black87, icon: Icons.security), // Generales
  16: BusinessCategoryStyle(color: Colors.blueGrey, icon: Icons.category), // Otros
};
