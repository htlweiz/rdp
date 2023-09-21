# Test Cases


### Test Case: Add Value Type

This test aims to verify that the `add_or_update_value_type` method effectively adds value types to the database. It also ensures that the added value type has the expected name and unit.

### Test Case: Add Value

The purpose of this test is to confirm that the `add_value` method accurately adds values to the database. It also checks that the database entry aligns with the expected time, value, and value type.

### Test Case: Get Value Types (Empty Database)

This test checks if the `get_value_types` method returns an empty list when there are no value types in the database.

### Test Case: Get Value Types

The objective of this test is to ensure that the `get_value_types` method correctly retrieves all existing value types from the database.

### Test Case: Get Value Type (Existing Value Type)

The objective of this test is to confirm that the `get_value_type` method effectively retrieves a `ValueType` object for an existing value type from the database. It also validates that the retrieved value type matches the expected name and unit.

### Test Case: Get Values (Empty Database)

This test checks if the `get_values` method returns an empty list when there are no values in the database.

### Test Case: Get Values

This test verifies that the `get_values` method correctly retrieves all existing values from the database.

### Test Case: Get Values (No Filters)

The goal of this test is to confirm that the `get_values` method returns values correctly when no filters are provided.

### Test Case: Get Values (With Value Type Filter)

This test checks if the `get_values` method accurately returns values when only the `value_type_id` filter is provided.

### Test Case: Get Values (With Start Filter)

The purpose of this test is to ensure that the `get_values` method correctly returns values when only the `start` filter is provided.

### Test Case: Get Values (With End Filter)

This test aims to verify that the `get_values` method correctly returns values when only the `end` filter is provided.

### Test Case: Get Values (With All Filters)

This test checks if the `get_values` method correctly returns values when all filters (`value_type_id`, `start`, and `end`) are provided.