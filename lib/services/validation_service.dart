class ValidationService {
  void validateUser(String name, String location, String type) {
    if (name.isEmpty) {
      throw Exception("User name cannot be empty");
    }
    if (location.isEmpty) {
      throw Exception("User location cannot be empty");
    }
    if (type.isEmpty) {
      throw Exception("User type cannot be empty");
    }
  }

  void validateProduct(String name, double price) {
    if (name.isEmpty) {
      throw Exception("Product name cannot be empty");
    }
    if (price <= 0) {
      throw Exception("Product price must be greater than zero");
    }
  }

  void validateInvoice() {
    // Add invoice validation logic
  }

  void validatePayment() {
    // Add payment validation logic
  }
}
