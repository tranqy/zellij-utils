# Makefile for Zellij Utils
# Provides convenient commands for development, testing, and deployment

.PHONY: help install test test-docker test-alpine clean lint format docs docker-build docker-test docker-shell validate test-validation backup release

# Default target
.DEFAULT_GOAL := help

# Configuration
PROJECT_NAME := zellij-utils
DOCKER_IMAGE := $(PROJECT_NAME):test
DOCKER_IMAGE_ALPINE := $(PROJECT_NAME):test-alpine
TEST_OUTPUT_DIR := ./test-results
DOCS_DIR := ./docs

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

## Help - Show this help message
help:
	@echo "$(BLUE)Zellij Utils - Development Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC) make [target]"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@grep -E '^## .*' $(MAKEFILE_LIST) | sed 's/## /  $(GREEN)/' | sed 's/ - /$(NC) - /'
	@echo ""

## install - Install zellij-utils to the system
install:
	@echo "$(BLUE)Installing zellij-utils...$(NC)"
	./scripts/install.sh

## test - Run all tests locally (requires zellij to be installed)
test:
	@echo "$(BLUE)Running local tests...$(NC)"
	@if ! command -v zellij >/dev/null 2>&1; then \
		echo "$(YELLOW)Warning: zellij not found. Install zellij first or use 'make test-docker'$(NC)"; \
		exit 1; \
	fi
	./tests/run_all_tests.sh

## test-docker - Run tests in Docker container (Ubuntu)
test-docker:
	@echo "$(BLUE)Running tests in Docker (Ubuntu)...$(NC)"
	./docker/execute_tests.sh test

## test-alpine - Run tests in Alpine Linux container
test-alpine:
	@echo "$(BLUE)Running tests in Docker (Alpine)...$(NC)"
	./docker/execute_tests.sh --alpine test

## test-verbose - Run Docker tests with verbose output
test-verbose:
	@echo "$(BLUE)Running tests with verbose output...$(NC)"
	./docker/execute_tests.sh -v test

## test-clean - Clean and run Docker tests
test-clean:
	@echo "$(BLUE)Cleaning and running tests...$(NC)"
	./docker/execute_tests.sh -c test

## docker-build - Build Docker test image
docker-build:
	@echo "$(BLUE)Building Docker test image...$(NC)"
	./docker/execute_tests.sh build

## docker-shell - Start interactive shell in Docker container
docker-shell:
	@echo "$(BLUE)Starting Docker shell...$(NC)"
	./docker/execute_tests.sh shell

## docker-logs - Show Docker container logs
docker-logs:
	@echo "$(BLUE)Showing Docker logs...$(NC)"
	./docker/execute_tests.sh logs

## results - Show latest test results
results:
	@echo "$(BLUE)Showing test results...$(NC)"
	./docker/execute_tests.sh results

## validate - Validate configuration and scripts
validate:
	@echo "$(BLUE)Validating configuration...$(NC)"
	@if [ -f scripts/config-validator.sh ]; then \
		bash scripts/config-validator.sh full; \
	else \
		echo "$(YELLOW)Config validator not found$(NC)"; \
	fi
	@echo "$(BLUE)Validating shell scripts...$(NC)"
	@find scripts -name "*.sh" -exec bash -n {} \; && echo "$(GREEN)All scripts are syntactically valid$(NC)"

## test-validation - Test validation functions with invalid inputs
test-validation:
	@echo "$(BLUE)Testing validation functions...$(NC)"
	@if [ -f scripts/config-validator.sh ]; then \
		bash scripts/config-validator.sh test; \
	else \
		echo "$(YELLOW)Config validator not found$(NC)"; \
	fi

## lint - Run shellcheck on all shell scripts
lint:
	@echo "$(BLUE)Running shellcheck...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		find scripts -name "*.sh" -exec shellcheck {} \; && echo "$(GREEN)Shellcheck passed$(NC)"; \
	else \
		echo "$(YELLOW)shellcheck not installed. Install with: apt install shellcheck$(NC)"; \
	fi

## format - Format shell scripts (if shfmt is available)
format:
	@echo "$(BLUE)Formatting shell scripts...$(NC)"
	@if command -v shfmt >/dev/null 2>&1; then \
		find scripts -name "*.sh" -exec shfmt -i 4 -w {} \; && echo "$(GREEN)Scripts formatted$(NC)"; \
	else \
		echo "$(YELLOW)shfmt not installed. Install with: go install mvdan.cc/sh/v3/cmd/shfmt@latest$(NC)"; \
	fi

## clean - Clean up temporary files and Docker resources
clean:
	@echo "$(BLUE)Cleaning up...$(NC)"
	rm -rf $(TEST_OUTPUT_DIR)
	rm -rf .cache
	find . -name "*.log" -delete 2>/dev/null || true
	find . -name ".DS_Store" -delete 2>/dev/null || true
	./docker/execute_tests.sh clean

## backup - Create backup of current configuration
backup:
	@echo "$(BLUE)Creating configuration backup...$(NC)"
	@if [ -f scripts/config-migration.sh ]; then \
		bash scripts/config-migration.sh backup; \
	else \
		echo "$(YELLOW)Backup script not found$(NC)"; \
	fi

## docs - Generate documentation (if supported)
docs:
	@echo "$(BLUE)Generating documentation...$(NC)"
	@mkdir -p $(DOCS_DIR)
	@echo "# Zellij Utils Documentation" > $(DOCS_DIR)/README.md
	@echo "" >> $(DOCS_DIR)/README.md
	@echo "Generated on: $$(date)" >> $(DOCS_DIR)/README.md
	@echo "$(GREEN)Basic documentation generated in $(DOCS_DIR)/$(NC)"

## install-deps - Install development dependencies
install-deps:
	@echo "$(BLUE)Installing development dependencies...$(NC)"
	@if command -v apt >/dev/null 2>&1; then \
		sudo apt update && sudo apt install -y shellcheck git make; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y ShellCheck git make; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install shellcheck git make; \
	else \
		echo "$(YELLOW)Package manager not recognized. Please install shellcheck, git, and make manually.$(NC)"; \
	fi

## ci - Run full CI pipeline
ci: validate test-docker
	@echo "$(GREEN)CI pipeline completed successfully$(NC)"

## release - Prepare for release (backup, test, validate)
release: backup validate test-docker
	@echo "$(GREEN)Release preparation completed$(NC)"
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Review test results in $(TEST_OUTPUT_DIR)/"
	@echo "  2. Update version in relevant files"
	@echo "  3. Create git tag"
	@echo "  4. Update documentation"

## status - Show project status
status:
	@echo "$(BLUE)Zellij Utils Project Status$(NC)"
	@echo ""
	@echo "$(YELLOW)Dependencies:$(NC)"
	@echo -n "  zellij: "
	@if command -v zellij >/dev/null 2>&1; then echo "$(GREEN)✓ $$(zellij --version)$(NC)"; else echo "$(YELLOW)✗ not installed$(NC)"; fi
	@echo -n "  git: "
	@if command -v git >/dev/null 2>&1; then echo "$(GREEN)✓ $$(git --version | cut -d' ' -f3)$(NC)"; else echo "$(YELLOW)✗ not installed$(NC)"; fi
	@echo -n "  docker: "
	@if command -v docker >/dev/null 2>&1; then echo "$(GREEN)✓ available$(NC)"; else echo "$(YELLOW)✗ not available$(NC)"; fi
	@echo -n "  shellcheck: "
	@if command -v shellcheck >/dev/null 2>&1; then echo "$(GREEN)✓ available$(NC)"; else echo "$(YELLOW)✗ not available$(NC)"; fi
	@echo ""
	@echo "$(YELLOW)Project Files:$(NC)"
	@echo "  Scripts: $$(find scripts -name '*.sh' | wc -l) files"
	@echo "  Layouts: $$(find layouts -name '*.kdl' 2>/dev/null | wc -l) files"
	@echo "  Tests: $$(find tests -name '*.sh' 2>/dev/null | wc -l) files"
	@echo "  Config: $$(find config -name '*.conf' 2>/dev/null | wc -l) files"
	@echo ""
	@if [ -d $(TEST_OUTPUT_DIR) ]; then \
		echo "$(YELLOW)Latest Test Results:$(NC)"; \
		echo "  Output: $(TEST_OUTPUT_DIR)/"; \
		if [ -f $(TEST_OUTPUT_DIR)/test_plan_results.md ]; then \
			echo "  Status: $$(grep -o '✅ PASS\|❌ FAIL' $(TEST_OUTPUT_DIR)/test_plan_results.md | head -1)"; \
		fi; \
	fi

## dev-setup - Set up development environment
dev-setup: install-deps
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@if [ ! -d .git ]; then \
		echo "$(YELLOW)Initializing git repository...$(NC)"; \
		git init .; \
	fi
	@echo "$(GREEN)Development environment ready$(NC)"
	@echo "$(BLUE)Recommended next steps:$(NC)"
	@echo "  make validate  # Validate current code"
	@echo "  make test      # Run tests locally"
	@echo "  make docker-test # Run tests in Docker"