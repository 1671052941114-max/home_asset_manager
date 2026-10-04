enum WarrantyStatus {
  noWarranty,
  active,
  expiringSoon,
  expired,
}

class WarrantyUtils {
  const WarrantyUtils._();

  static const int expiringSoonDays = 30;

  static WarrantyStatus getStatus(DateTime? warrantyEndDate) {
    if (warrantyEndDate == null) {
      return WarrantyStatus.noWarranty;
    }

    final today = _dateOnly(DateTime.now());
    final endDate = _dateOnly(warrantyEndDate);

    if (endDate.isBefore(today)) {
      return WarrantyStatus.expired;
    }

    final remainingDays = endDate.difference(today).inDays;

    if (remainingDays <= expiringSoonDays) {
      return WarrantyStatus.expiringSoon;
    }

    return WarrantyStatus.active;
  }

  static int? getRemainingDays(DateTime? warrantyEndDate) {
    if (warrantyEndDate == null) {
      return null;
    }

    final today = _dateOnly(DateTime.now());
    final endDate = _dateOnly(warrantyEndDate);

    return endDate.difference(today).inDays;
  }

  static bool isExpiringSoon(DateTime? warrantyEndDate) {
    return getStatus(warrantyEndDate) ==
        WarrantyStatus.expiringSoon;
  }

  static bool isExpired(DateTime? warrantyEndDate) {
    return getStatus(warrantyEndDate) ==
        WarrantyStatus.expired;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}