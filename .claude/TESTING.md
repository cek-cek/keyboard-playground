# Testing Guide for Keyboard Playground

## Quick Start

### From Cold Start (New Session)

The SessionStart hook automatically sets up Flutter when you start a new session. However, if you need to manually set up or run tests:

1. **Run tests immediately:**
   ```bash
   make test
   ```

   The Makefile now automatically handles the Flutter PATH setup.

2. **If Flutter is not found:**
   ```bash
   make setup
   ```

### Running Tests

```bash
# Run all tests
make test

# Run tests with coverage
make coverage

# Run all CI checks (format, analyze, test)
make ci
```

### Manual Flutter Commands

If you need to run Flutter commands directly (outside of make), source the environment:

```bash
source .claude/env.sh
flutter test
flutter analyze
```

## Troubleshooting

### Flutter Not Found

If you see "flutter: command not found":

1. **Option 1 (Recommended):** Use make commands
   ```bash
   make test
   ```

2. **Option 2:** Source the environment
   ```bash
   source .claude/env.sh
   flutter test
   ```

3. **Option 3:** Run setup
   ```bash
   make setup
   ```

### Test Failures

1. Check Flutter doctor:
   ```bash
   source .claude/env.sh
   flutter doctor
   ```

2. Get dependencies:
   ```bash
   source .claude/env.sh
   flutter pub get
   ```

3. Clean and retry:
   ```bash
   make clean
   make test
   ```

## CI/CD Integration

The project is set up to run CI checks automatically. You can run the same checks locally:

```bash
make ci
```

This runs:
- Code formatting check
- Static analysis with strict lints
- All unit tests

**IMPORTANT:** A pre-push git hook ensures `make ci` passes before every push. This prevents broken code from being pushed to the repository.

## For Claude Code Web Sessions

The `.claude/hooks/SessionStart` hook automatically:
1. Checks if Flutter is available
2. Runs setup if needed
3. Displays quick command reference

The Makefile is configured to automatically add Flutter to PATH, so all `make` commands work without additional setup.

## Development Workflow

1. **Make changes to code**
2. **Format code:**
   ```bash
   make format
   ```

3. **Run analysis:**
   ```bash
   make analyze
   ```

4. **Run tests:**
   ```bash
   make test
   ```

5. **Or run all checks:**
   ```bash
   make ci
   ```

6. **Commit and push your changes**
   - The pre-push hook automatically runs `make ci` before allowing pushes
   - This ensures code quality and prevents broken code from being pushed

### Pre-Push Hook

A git pre-push hook is installed that automatically runs `make ci` before every push. This ensures:
- Code is properly formatted
- Static analysis passes
- All tests pass

**The hook will block the push if any checks fail.**

To bypass the hook in emergencies (not recommended):
```bash
git push --no-verify
```

The hook is automatically installed by `.claude/setup.sh` from `.claude/hooks/pre-push.template`.

## Test Structure

Tests are located in:
- `test/widget_test.dart` - Widget and integration tests

The project uses:
- `flutter_test` - Flutter testing framework
- `very_good_analysis` - Strict linting rules
- `flutter_lints` - Official Flutter lints
