# PRD-003: Build System & CI/CD

**Status**: ✅ Complete
**Dependencies**: PRD-002 (Project Setup)
**Estimated Effort**: 6 hours
**Priority**: P0 - CRITICAL (Must be third)
**Branch**: `feature/prd-003-build-ci-cd`

## Overview

Establish a robust CI/CD pipeline using GitHub Actions to ensure code quality, run tests, and build the application on all target platforms (macOS, Linux, Windows). This ensures every commit maintains quality standards and catches issues early.

## Context

With the project structure established (PRD-002), we need automated verification that:
- Code passes linting and formatting checks
- Tests run successfully
- Application builds on all platforms
- Coverage remains above threshold
- Pull requests meet quality standards

This enables confident parallel development for subsequent PRDs.

## Goals

1. ✅ GitHub Actions workflows for CI/CD
2. ✅ Automated linting and formatting checks
3. ✅ Automated test execution with coverage reporting
4. ✅ Multi-platform build verification (macOS, Linux, Windows)
5. ✅ PR quality gates
6. ✅ Fast feedback (<10 minutes for most checks)

## Non-Goals

- Deployment/distribution (not needed yet)
- Code signing (future PRD)
- Release automation (future PRD)
- Performance benchmarking (PRD-013)

## Requirements

### Functional Requirements

**FR-001**: Lint and format checking
- Run `flutter analyze` on every push
- Verify `dart format` compliance
- Fail if any issues found

**FR-002**: Test execution
- Run all tests on every push
- Generate coverage report
- Fail if coverage drops below 90% (once tests exist)

**FR-003**: Multi-platform builds
- Build on macOS (default, runs every PR)
- Build on Linux (runs every PR)
- Build on Windows (runs every PR or on-demand)

**FR-004**: PR quality gates
- All checks must pass before merge
- Status checks reported to PR
- Clear failure messages

**FR-005**: Caching for speed
- Cache Flutter SDK
- Cache pub dependencies
- Cache build artifacts where possible

### Non-Functional Requirements

**NFR-001**: Speed
- Lint/format check completes <2 minutes
- Test execution completes <5 minutes
- Full build (single platform) completes <10 minutes

**NFR-002**: Reliability
- Workflows don't fail due to flakiness
- Timeouts set appropriately
- Retries for network issues

**NFR-003**: Maintainability
- Workflows are well-commented
- Reusable workflow components
- Clear job names and outputs

## Technical Specifications

### Workflow Architecture

```
.github/workflows/
├── ci.yml                 # Main CI (lint, test, build)
├── pr-checks.yml          # PR-specific checks
└── (future: release.yml)  # Release automation (future)
```

### Workflow: ci.yml (Main CI Pipeline)

```yaml
name: CI

on:
  push:
    branches: [main, 'claude/**']
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze:
    name: Lint & Format
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'  # Use from PRD-001 dependency doc
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --set-exit-if-changed .

      - name: Analyze code
        run: flutter analyze --fatal-infos

  test:
    name: Unit & Widget Tests
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage --reporter expanded

      - name: Check coverage
        uses: VeryGoodOpenSource/very_good_coverage@v2
        with:
          min_coverage: 90
          exclude: |
            **/*.g.dart
            **/*.freezed.dart
            **/main.dart

      - name: Upload coverage to Codecov (optional)
        uses: codecov/codecov-action@v3
        if: github.event_name == 'push'
        with:
          files: ./coverage/lcov.info
          flags: unittests
          fail_ci_if_error: false

  build-macos:
    name: Build macOS
    runs-on: macos-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Build macOS app
        run: flutter build macos --debug

      - name: Upload macOS artifact
        uses: actions/upload-artifact@v3
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        with:
          name: macos-build
          path: build/macos/Build/Products/Debug/
          retention-days: 7

  build-linux:
    name: Build Linux
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Install Linux dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y clang cmake ninja-build pkg-config \
            libgtk-3-dev liblzma-dev libstdc++-12-dev

      - name: Get dependencies
        run: flutter pub get

      - name: Build Linux app
        run: flutter build linux --debug

      - name: Upload Linux artifact
        uses: actions/upload-artifact@v3
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        with:
          name: linux-build
          path: build/linux/x64/debug/bundle/
          retention-days: 7

  build-windows:
    name: Build Windows
    runs-on: windows-latest
    timeout-minutes: 30
    # Only run on main branch or when explicitly triggered
    if: github.ref == 'refs/heads/main' || contains(github.event.pull_request.labels.*.name, 'build-windows')
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Build Windows app
        run: flutter build windows --debug

      - name: Upload Windows artifact
        uses: actions/upload-artifact@v3
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        with:
          name: windows-build
          path: build/windows/x64/runner/Debug/
          retention-days: 7
```

### Workflow: pr-checks.yml (PR-Specific)

```yaml
name: PR Checks

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  pr-title:
    name: Validate PR Title
    runs-on: ubuntu-latest
    steps:
      - name: Check PR title format
        uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            style
            refactor
            test
            chore
          scopes: |
            prd-\d+
            input
            games
            ui
            platform
            ci
            core
          requireScope: false

  pr-size:
    name: Check PR Size
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check PR size
        run: |
          FILES_CHANGED=$(git diff --name-only origin/${{ github.base_ref }}...HEAD | wc -l)
          LINES_CHANGED=$(git diff --stat origin/${{ github.base_ref }}...HEAD | tail -n1 | awk '{print $4}')

          echo "Files changed: $FILES_CHANGED"
          echo "Lines changed: $LINES_CHANGED"

          if [ "$FILES_CHANGED" -gt 50 ]; then
            echo "⚠️ Warning: Large PR ($FILES_CHANGED files). Consider splitting."
          fi

          if [ "$LINES_CHANGED" -gt 1000 ]; then
            echo "⚠️ Warning: Large PR ($LINES_CHANGED lines). Consider splitting."
          fi

  link-prd:
    name: Check PRD Link
    runs-on: ubuntu-latest
    steps:
      - name: Check if PR references a PRD
        uses: actions/github-script@v7
        with:
          script: |
            const prBody = context.payload.pull_request.body || '';
            const prTitle = context.payload.pull_request.title || '';
            const hasPRDReference = /PRD-\d{3}/i.test(prBody + prTitle);

            if (!hasPRDReference) {
              core.warning('PR does not reference a PRD. Consider adding PRD-XXX to title or body.');
            } else {
              core.info('✅ PR references a PRD');
            }
```

### Branch Protection Rules

Configure in GitHub repository settings:

```yaml
# main branch protection
Require a pull request before merging: true
Require approvals: 1 (for human PRs, can be 0 for AI agents)
Dismiss stale pull request approvals: true
Require review from Code Owners: false (initially)
Require status checks to pass: true
  - analyze (Lint & Format)
  - test (Unit & Widget Tests)
  - build-macos (Build macOS)
  - build-linux (Build Linux)
Require branches to be up to date: true
Require conversation resolution: true
Do not allow bypassing: true
```

### Makefile (Optional, for local development)

Create `Makefile` for common commands:

```makefile
.PHONY: help analyze format test coverage build-macos build-linux build-windows clean

help:
	@echo "Keyboard Playground - Development Commands"
	@echo ""
	@echo "  make analyze     - Run static analysis"
	@echo "  make format      - Format all Dart code"
	@echo "  make test        - Run all tests"
	@echo "  make coverage    - Run tests with coverage"
	@echo "  make build-macos - Build macOS app"
	@echo "  make build-linux - Build Linux app"
	@echo "  make build-windows - Build Windows app"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make ci          - Run all CI checks locally"

analyze:
	flutter analyze --fatal-infos

format:
	dart format .

format-check:
	dart format --set-exit-if-changed .

test:
	flutter test --reporter expanded

coverage:
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html  # macOS
	# xdg-open coverage/html/index.html  # Linux

build-macos:
	flutter build macos --debug

build-linux:
	flutter build linux --debug

build-windows:
	flutter build windows --debug

clean:
	flutter clean
	rm -rf coverage/

ci: format-check analyze test
	@echo "✅ All CI checks passed locally!"
```

## Acceptance Criteria

### Workflows Created

- [ ] `.github/workflows/ci.yml` created with all jobs
- [ ] `.github/workflows/pr-checks.yml` created
- [ ] All workflows have appropriate triggers
- [ ] All workflows have timeouts set

### CI Jobs Working

- [ ] `analyze` job runs and passes on sample PR
- [ ] `test` job runs and passes on sample PR
- [ ] `build-macos` job completes successfully
- [ ] `build-linux` job completes successfully
- [ ] `build-windows` job completes (or skips appropriately)

### Caching Configured

- [ ] Flutter SDK cached
- [ ] Pub dependencies cached
- [ ] Cache hit rate >80% on subsequent runs

### Quality Gates

- [ ] PR cannot merge if analyze fails
- [ ] PR cannot merge if tests fail
- [ ] PR cannot merge if format check fails
- [ ] Status checks display on PR

### Documentation

- [ ] Makefile created with common commands
- [ ] CONTRIBUTING.md updated with CI/CD information
- [ ] README.md badge added showing CI status

### Performance

- [ ] Lint/format job completes <3 minutes
- [ ] Test job completes <10 minutes
- [ ] macOS build completes <30 minutes

## Implementation Steps

### Step 1: Create Workflow Files (2 hours)

```bash
# Create workflows directory
mkdir -p .github/workflows

# Create ci.yml (copy from Technical Specifications above)
touch .github/workflows/ci.yml

# Create pr-checks.yml
touch .github/workflows/pr-checks.yml
```

### Step 2: Create Makefile (30 min)

```bash
# Create Makefile
touch Makefile
# Add content from Technical Specifications
```

### Step 3: Test Workflows Locally (1 hour)

Use [act](https://github.com/nektos/act) to test locally:

```bash
# Install act (macOS)
brew install act

# Test analyze job
act -j analyze

# Test test job
act -j test
```

Or manually run commands:
```bash
make ci
```

### Step 4: Push and Verify on GitHub (1 hour)

```bash
# Commit workflows
git add .github/workflows/ Makefile
git commit -m "feat(prd-003): Add CI/CD workflows"
git push

# Check Actions tab on GitHub
# Verify all jobs run
```

### Step 5: Configure Branch Protection (30 min)

1. Go to GitHub repository settings
2. Navigate to Branches → Branch protection rules
3. Add rule for `main`
4. Configure as specified in Technical Specifications

### Step 6: Test with Sample PR (1 hour)

```bash
# Create test branch
git checkout -b test/ci-verification

# Make a small change
echo "# CI Test" >> README.md
git add README.md
git commit -m "test(ci): Verify CI workflows"
git push -u origin test/ci-verification

# Create PR on GitHub
# Verify all checks run and pass
```

### Step 7: Update Documentation (1 hour)

Update CONTRIBUTING.md:
```markdown
## Continuous Integration

Our CI pipeline runs on every push and PR:

- **Lint & Format**: Ensures code follows style guidelines
- **Tests**: Runs all unit and widget tests
- **Builds**: Verifies app builds on all platforms

### Running CI Checks Locally

\`\`\`bash
make ci  # Runs format-check, analyze, and test
\`\`\`

### CI Workflow Files

- `.github/workflows/ci.yml`: Main CI pipeline
- `.github/workflows/pr-checks.yml`: PR-specific checks

### Build Matrix

| Job | Platform | Trigger |
|-----|----------|---------|
| analyze | Ubuntu | Every push |
| test | Ubuntu | Every push |
| build-macos | macOS | Every push |
| build-linux | Ubuntu | Every push |
| build-windows | Windows | Main branch or labeled PR |
```

Add CI badge to README.md:
```markdown
# Keyboard Playground

![CI Status](https://github.com/<org>/<repo>/workflows/CI/badge.svg)
```

## Testing Requirements

### Local Testing

Before pushing:
```bash
# Run all CI checks locally
make ci

# Should pass:
# ✅ dart format --set-exit-if-changed .
# ✅ flutter analyze --fatal-infos
# ✅ flutter test
```

### CI Testing

After pushing:
- [ ] All workflow jobs appear in Actions tab
- [ ] All jobs complete successfully
- [ ] Check timings are reasonable (<10 min for most)
- [ ] Artifacts uploaded correctly (on main branch)

### PR Testing

Create a test PR:
- [ ] Status checks appear on PR
- [ ] All checks pass
- [ ] Merge button blocked until checks pass
- [ ] Clear failure messages if something fails

## Definition of Done

- [ ] All workflow files created and pushed
- [ ] Makefile created
- [ ] Branch protection configured
- [ ] Test PR created and passes all checks
- [ ] Documentation updated (CONTRIBUTING.md, README.md)
- [ ] CI badge added to README
- [ ] All jobs complete in reasonable time
- [ ] Caching working (verify cache hit on second run)
- [ ] DEPENDENCIES.md updated (PRD-003 marked complete)
- [ ] PRD-004-007 can start immediately

## Notes for AI Agents

### Common Issues

**Issue**: Workflow syntax error
- **Solution**: Use GitHub's workflow validator or yamllint

**Issue**: Flutter version mismatch
- **Solution**: Use exact version from PRD-001 dependencies doc

**Issue**: Linux build fails with missing dependencies
- **Solution**: Ensure all packages in apt-get install step

**Issue**: Timeout on builds
- **Solution**: Increase timeout-minutes or optimize build

### Testing Without Pushing

Use `act` to test locally:
```bash
# Install act
brew install act  # macOS
# or download from https://github.com/nektos/act

# Run specific job
act -j analyze

# Run all jobs
act
```

### Time Breakdown

- Create workflow files: 2 hours
- Create Makefile: 30 min
- Local testing: 1 hour
- GitHub verification: 1 hour
- Branch protection setup: 30 min
- Test PR: 1 hour
- Documentation: 1 hour
- **Total**: 6 hours

### Quick Validation Checklist

- [ ] Workflows have proper `on:` triggers
- [ ] All jobs have `timeout-minutes` set
- [ ] Flutter version matches PRD-001
- [ ] Caching enabled for Flutter and pub
- [ ] Status checks required for main branch
- [ ] All checks pass on test PR

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter GitHub Actions](https://docs.flutter.dev/deployment/cd#github-actions)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
- [VeryGoodOpenSource/very_good_coverage](https://github.com/VeryGoodOpenSource/very_good_coverage)

## Future Enhancements

(Not in this PRD, but document for later):

- [ ] Automated version bumping
- [ ] Release workflow with artifacts
- [ ] Code signing for distribution
- [ ] Performance benchmarking
- [ ] Visual regression testing
- [ ] Integration test runs

---

**Ready to start?** Ensure PRD-002 is complete and merged, then create your branch and start building the CI/CD pipeline!
