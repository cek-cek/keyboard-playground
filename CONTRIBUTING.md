# Contributing to Keyboard Playground

## Development Setup

### 1. Install Flutter

Follow the official Flutter installation guide: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Clone and Setup

```bash
git clone <repository-url>
cd keyboard-playground
flutter pub get
```

### 3. IDE Setup (Recommended)

**VS Code**:
- Install Flutter extension
- Install Dart extension
- Settings are pre-configured in `.vscode/`

**Android Studio / IntelliJ**:
- Install Flutter plugin
- Install Dart plugin

### 4. Verify Setup

```bash
flutter analyze  # Should show no issues
flutter test     # Should pass all tests
flutter run -d linux  # Should run the app
```

## Development Workflow

### Before You Start

1. Check [DEPENDENCIES.md](DEPENDENCIES.md) for available PRDs
2. Read [AGENTS.md](AGENTS.md) for coordination guidelines
3. Create a feature branch: `git checkout -b feature/prd-XXX-description`

### During Development

1. Write tests first (TDD encouraged)
2. Run `flutter analyze` frequently
3. Format code: `dart format .`
4. Commit often with clear messages

### Before Submitting PR

```bash
# Run all checks
flutter analyze
flutter test --coverage
dart format --set-exit-if-changed .

# Commit
git add .
git commit -m "feat(prd-XXX): Description"
git push -u origin feature/prd-XXX-description
```

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` (no custom formatting)
- All public APIs must have documentation comments
- Prefer `const` constructors where possible

## Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for end-to-end flows
- Maintain >90% coverage

## Commit Messages

Format: `type(scope): subject`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `test`: Adding/updating tests
- `refactor`: Code refactoring
- `chore`: Build tasks, dependencies

**Examples**:
- `feat(prd-004): Implement macOS keyboard capture`
- `fix(input): Handle key repeat edge case`
- `docs(readme): Update setup instructions`

## Questions?

- Check [AGENTS.md](AGENTS.md) for detailed guidance
- Review existing PRDs in [docs/prds/](docs/prds/)
- Read architecture docs in [docs/architecture/](docs/architecture/)
