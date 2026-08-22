# Multi-Currency Support Implementation Plan

Support for two currencies (SY and Dollar) across the application, including separate balances for users, and currency-specific invoices and payments.

## Proposed Changes

### Core Models & Database

#### [NEW] [currency.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/models/currency.dart)
- Define `Currency` enum with values `sy` and `dollar`.
- Add helper methods for display names and symbols.

#### [MODIFY] [user.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/models/user.dart)
- Replace `total` field with `totalSy` and `totalDollar`.
- Update `copyWith`, `toMap`, and `fromMap` methods.

#### [MODIFY] [product.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/models/product.dart)
- Replace `price` field with `priceSy` and `priceDollar`.
- Update `copyWith`, `toMap`, and `fromMap`.

#### [MODIFY] [fatora.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/models/fatora.dart)
- Add `currency` field.
- Update `copyWith`, `toMap`, and `fromMap`.

#### [MODIFY] [payment.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/models/payment.dart)
- Add `currency` field.
- Update `copyWith`, `toMap`, and `fromMap`.

#### [MODIFY] [database_helper.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/database/database_helper.dart)
- Update `users` table schema: replace `total` with `totalSy` and `totalDollar`.
- Update `products` table schema: replace `price` with `priceSy` and `priceDollar`.
- Update `fatoras` table schema: add `currency` column.
- Update `payments` table schema: add `currency` column.
- Increment database version to 2 and add migration logic in `onUpgrade` (or update `onCreate` for new installations).

### Data Access Layer (DAOs & Repositories)

#### [MODIFY] [user_db.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/database/user_db.dart), [fatora_db.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/database/fatora_db.dart), [payment_db.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/database/payment_db.dart)
- Update SQL queries and mapping to include new currency-related fields.

#### [MODIFY] [user_dao.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/dao/user_dao.dart)
- Update `updateBalance` to accept `Currency` and update the respective total.

#### [MODIFY] [user_repository.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/repositories/user_repository.dart)
- Update `changeBalance` signature to include `Currency`.

### Service Layer

#### [MODIFY] [invoice_service.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/services/invoice_service.dart)
- Update `createInvoice`, `updateInvoice`, and `deleteInvoice` to pass the invoice's currency to `userRepository.changeBalance`.

#### [MODIFY] [payment_service.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/core/services/payment_service.dart)
- Update `createPayment` and `deletePayment` to pass the payment's currency to `userRepository.changeBalance`.

### Presentation Layer (UI & Controllers)

#### [MODIFY] [add_invoice_controller.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/feat/users/controllers/add_invoice_controller.dart)
- Add `selectedCurrency` state.
- Update `saveInvoice` to include the selected currency.

#### [MODIFY] [add_payment_controller.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/feat/users/controllers/add_payment_controller.dart)
- Add `selectedCurrency` state.
- Update `savePayment` to include the selected currency.

#### [MODIFY] [add_invoice_screen.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/feat/users/screen/add_invoice_screen.dart)
- Add a currency toggle/selector (SY / $).
- Update total display to show the selected currency symbol.

#### [MODIFY] [add_payment_screen.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/feat/users/screen/add_payment_screen.dart)
- Add a currency toggle/selector.

#### [MODIFY] [user_details_screen.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/feat/users/screen/user_details_screen.dart)
- Display both `SY` and `$` balances in the header.
- Show currency symbol for each invoice and payment in the lists.

#### [MODIFY] [user_card.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/feat/users/widget/user_card.dart)
- Display both balances in chips or a clear format.

#### [MODIFY] [user_form_bottom_sheet.dart](file:///C:/Users/TECHNO/StudioProjects/naji/lib/feat/users/widget/user_form_bottom_sheet.dart)
- Add input fields for both initial balances (`SY` and `$`).

## Verification Plan

### Manual Verification
- Create a new user with initial balances in both currencies.
- Create invoices in SY and verify only the SY balance changes.
- Create invoices in USD and verify only the USD balance changes.
- Create payments in both currencies and verify balances.
- Verify user details screen displays correct totals for each currency.
- Verify the list of invoices and payments shows the correct currency for each entry.
