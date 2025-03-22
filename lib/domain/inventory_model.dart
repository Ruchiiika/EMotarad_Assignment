class InventoryItem {
  final String name;
  final int quantity;
  final double price;
  final int threshold;

  InventoryItem({required this.name, required this.quantity, required this.price, required this.threshold});

  factory InventoryItem.fromList(List<dynamic> row) {
    return InventoryItem(
      name: row[0] ?? "Unknown",
      quantity: int.tryParse(row[1].toString()) ?? 0,
      price: double.tryParse(row[2].toString()) ?? 0.0,
      threshold: int.tryParse(row[3].toString()) ?? 5,
    );
  }
}
