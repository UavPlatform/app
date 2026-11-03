import 'package:flutter/material.dart';
import 'dispatch_pilot_pages.dart';

/// The pilot home is the dispatch hall, without an intermediary entry page.
class PilotHomePage extends StatelessWidget {
  const PilotHomePage({super.key});
  @override
  Widget build(BuildContext context) => const DispatchPilotHallPage();
}
