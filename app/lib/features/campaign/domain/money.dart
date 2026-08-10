enum Currency { krw }

final class Money {
  Money.won(this.amount) : currency = Currency.krw {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
  }

  final int amount;
  final Currency currency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && amount == other.amount && currency == other.currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}
