# Integration Tests

This directory is reserved for integration tests.

Integration tests will be added in PRD-008 (Integration & Base Application) once all components are ready to be tested together.

## Running Integration Tests

Integration tests should be run separately from unit and widget tests:

```bash
flutter test integration_test/
```

## Structure

Integration tests will test:
- Full app launches successfully
- Exit sequences work end-to-end
- Game switching works correctly
- Input capture integrates properly with games

See test/README.md for more information about integration testing utilities.
