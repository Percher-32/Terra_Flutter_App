class ArbitStore {
  Map data = {};

  void fallback(dynamic key, dynamic value) {
    if (!data.keys.contains(key)) {
      data[key] = value;
    }
  }
}

const base_types = {
  0: "Food & Dining",
  1: "Home Services",
  2: "Health & Wellness",
  3: "Shopping & Retail",
  4: "Professional Services",
  5: "Automotive",
  6: "Beauty & Personal Care",
  7: "Entertainment & Leisure",
  8: "Education",
  9: "Lodging & Travel",
};

void Arbitfallbacks() {
  arbitStore.fallback("distance_index", 3.toInt());
  arbitStore.fallback("userLocationChooseIndex", 1.toInt());
  arbitStore.fallback("distance", milesToKm(10).toInt());
  arbitStore.fallback("gasSafeOnly", false);
  arbitStore.fallback("electricitySafeOnly", false);
  arbitStore.fallback("allowedBtypes", "Both");
  arbitStore.fallback("allowedBtypesINDEX", 0);
  arbitStore.fallback("categoryINDEX", -1);
  arbitStore.fallback("sorting", "DST");
  arbitStore.fallback("sortingINDEX", 0);
  arbitStore.fallback("searchTags", []);
  arbitStore.fallback("userLocation", [53.7444,-0.3324]);
}

double milesToKm(double miles) => miles * 1.60934;
double KmTomiles(double miles) => miles / 1.60934;

ArbitStore arbitStore = ArbitStore();