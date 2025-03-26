
String getStatusText(dynamic statusValue) {
  switch (statusValue) {
    case 1:
      return "APPROVED";
    case 2:
      return "PENDING";
    case 3:
      return "CANCELLED";
    case 4:
      return "REJECTED";
    default:
      return "PENDING";
  }
}
String generateMessage(Map<String, dynamic> notif) {
  final int transactionType = notif['transaction_type'] ?? 0;
  final String borrowerName = (notif['borrower_name'] ?? "Borrower").toString();
  final String ownerName = (notif['owner_name'] ?? "Owner").toString();
  final int quantity = notif['quantity'] ?? 1;
  final String status = getStatusText(notif['request_status']);

  final String itemName = (notif['ITEM_NAME'] ?? "Item").toString();
  final String description = (notif['DESCRIPTION'] ?? "No description").toString();
  final String parNo = (notif['PAR_NO'] ?? "N/A").toString();
  final String mrNo = (notif['MR_NO'] ?? "N/A").toString();
  final String pisNo = (notif['PIS_NO'] ?? "N/A").toString();
  final String propNo = (notif['PROP_NO'] ?? "N/A").toString();
  final String serialNo = (notif['SERIAL_NO'] ?? "N/A").toString();
  final String unitValue = (notif['unit_value'] ?? "N/A").toString();
  final String totalValue = (notif['total_value'] ?? "N/A").toString();

  String itemDetails = '''
Item Details:
- Name: $itemName
- Description: $description
- Qty: $quantity
- PAR No: $parNo
- MR No: $mrNo
- PIS No: $pisNo
- PROP No: $propNo
- Serial No: $serialNo
- Unit Value: $unitValue
- Total Value: $totalValue
''';

  String transactionName = "";
  switch (transactionType) {
    case 1:
      transactionName = "BORROW";
      break;
    case 2:
      transactionName = "LEND";
      break;
    case 3:
      transactionName = "DISTRIBUTION";
      break;
    case 4:
      transactionName = "TRANSFER";
      break;
    case 5:
      transactionName = "RETURN";
      break;
    default:
      transactionName = "TRANSACTION";
  }

  if (transactionType == 1) {
    return '''
SUBJECT: REQUEST TO $transactionName ITEM,
Dear $borrowerName,

Your request to $transactionName item:

$itemDetails

From $ownerName is "$status". Please wait for the admin's approval.
''';
  } else if (transactionType == 2) {
    return '''
SUBJECT: REQUEST TO LEND ITEM,
Dear $ownerName,

Your request to $transactionName item:

$itemDetails

To $borrowerName is "$status". Please wait for the admin's approval.
''';
  } else if (transactionType == 4) {
    return '''
SUBJECT: REQUEST TO TRANSFER ITEM,
Dear $ownerName,

Your request to $transactionName item:

$itemDetails

To $borrowerName is "$status". Please wait for the admin's approval.
''';
  } else if (transactionType == 5) {
    return '''
SUBJECT: REQUEST TO $transactionName ITEM,
Dear $borrowerName,

Your request for $transactionName item:

$itemDetails

From $ownerName is "$status". Please wait for the admin's approval.
''';
  } else if (transactionType == 3) {
    return '''
SUBJECT: ITEM DISTRIBUTED,

$itemDetails

This item has been distributed to you by $ownerName.
''';
  } else {
    return (notif['message'] ?? "Notification details unavailable.").toString();
  }
}
