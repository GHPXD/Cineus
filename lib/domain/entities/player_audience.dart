/// Legacy declarations are retained; unrestricted means no age was collected.
enum PlayerAudience {
  unknown,
  under16,
  teen,
  adult,
  unrestricted;

  bool get canPlay => this == teen || this == adult || this == unrestricted;
  // An undeclared user still completes authentication/approval in the store.
  bool get canPurchase => this == adult || this == unrestricted;
  bool get canMeasureCommerce => this == adult;
  static PlayerAudience parse(String? value) =>
      values.where((v) => v.name == value).firstOrNull ?? unknown;
}
