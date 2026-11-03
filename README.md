
# Stock Inventory Manager

## Project Overview
This Flutter Web application manages stock inventory using Firebase Cloud Firestore. Users can add stock items, validate information, view saved records and perform advanced inventory searches.

## Setup and Run
1. Install Flutter SDK and Android Studio.
2. Open the stock_inventory_manager project.
3. Install dependencies using `flutter pub get`.
4. Ensure the Firebase Web configuration is present in `lib/firebase_options.dart`.
5. Run the application using `flutter run -d chrome`.

Required packages: `firebase_core`, `cloud_firestore`.

Firebase Project ID: `stock-inventory-manager-f9c6c`

## Firestore Data Model
Collection: `stockItems` with auto-generated document IDs.

Fields: sku (String), itemName (String), category (String), quantity (Integer), unitPrice (Number), reorderLevel (Integer) and createdAt (server Timestamp).

## Form Validation
All six inputs are compulsory. SKU must follow STK-XXX with three digits. Item names require at least three characters after trimming. Category must be Electronics, Stationery, Hardware or Grocery. Quantity and reorder level must be non-negative integers. Unit price must be greater than zero. Invalid data is not saved.

## Advanced Search
The inventory list retrieves live Firestore records. Keyword search supports partial, case-insensitive matches against SKU or item name. Category and low-stock filters can be combined with keyword search using AND logic. Low stock means quantity <= reorderLevel. Results can be sorted by quantity in ascending or descending order. Clear resets all filters.

## Test Log

| Input / Test | Expected Result | Actual Result | Evidence |
|---|---|---|---|
| Invalid form inputs | Inline errors; no Firestore write | Validation errors displayed; invalid write blocked | screenshots/invalid_form.png |
| Save STK-101, STK-102, STK-103 and refresh | All three records retrieved | All three items displayed after refresh | screenshots/firebase_inventory.png |
| Search mouse + Electronics + Low Stock | Only STK-103 appears | Only Wireless Mouse displayed | screenshots/combined_search.png |
