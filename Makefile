.PHONY: help analyze format format-check test coverage build-macos build-linux build-windows clean ci

help:
	@echo "Keyboard Playground - Development Commands"
	@echo ""
	@echo "  make analyze       - Run static analysis"
	@echo "  make format        - Format all Dart code"
	@echo "  make format-check  - Check code formatting"
	@echo "  make test          - Run all tests"
	@echo "  make coverage      - Run tests with coverage"
	@echo "  make build-macos   - Build macOS app"
	@echo "  make build-linux   - Build Linux app"
	@echo "  make build-windows - Build Windows app"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make ci            - Run all CI checks locally"

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
	@echo "Coverage report generated at coverage/html/index.html"
	@if [ "$$(uname)" = "Darwin" ]; then open coverage/html/index.html; fi
	@if [ "$$(uname)" = "Linux" ]; then xdg-open coverage/html/index.html 2>/dev/null || echo "Open coverage/html/index.html in your browser"; fi

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
