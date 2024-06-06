class Order {
  final int orderId;
  final String items;
  final double totalAmount;
  final String customerName;
  final String status;
  final String timeStamp;

  Order({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.customerName,
    required this.status,
    required this.timeStamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'items': items,
      'totalAmount': totalAmount,
      'customerName': customerName,
      'status': status,
      'timeStamp': timeStamp,
    };
  }
}
