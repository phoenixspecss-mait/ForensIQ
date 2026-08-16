class ServiceRateOption {
  final String key;
  final String label;
  final double defaultAmount;

  const ServiceRateOption({
    required this.key,
    required this.label,
    required this.defaultAmount,
  });
}

const List<ServiceRateOption> kServiceRateOptions = [
  ServiceRateOption(key: 'shoot_package', label: 'Shoot Package', defaultAmount: 15000),
  ServiceRateOption(key: 'bridal_makeup', label: 'Bridal Makeup', defaultAmount: 25000),
  ServiceRateOption(key: 'party_event_shoot', label: 'Party / Event Shoot', defaultAmount: 15000),
  ServiceRateOption(key: 'photoshoot_makeup', label: 'Photoshoot Makeup', defaultAmount: 12000),
  ServiceRateOption(key: 'half_day', label: 'Half Day Shoot', defaultAmount: 8000),
  ServiceRateOption(key: 'full_day', label: 'Full Day Shoot', defaultAmount: 18000),
];

List<Map<String, dynamic>> buildServiceOptions({Map<String, dynamic>? rateChart}) {
  return kServiceRateOptions.map((option) {
    final rawAmount = rateChart?[option.key];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '');

    return {
      'key': option.key,
      'name': option.label,
      'amount': amount,
    };
  }).toList();
}