#!/bin/bash
# Local testing script using Docker for isolation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
TEST_TYPE="main"
CLEANUP=true
VERBOSE=false

# Help function
show_help() {
    cat << EOF
Local Docker Testing Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -t, --type TYPE     Test type: main, alpine, or both (default: main)
    -v, --verbose       Enable verbose output
    --no-cleanup        Don't cleanup containers after tests
    --build             Force rebuild of containers
    --shell             Start interactive shell instead of running tests

EXAMPLES:
    $0                  # Run main tests in Docker
    $0 -t alpine       # Run Alpine tests in Docker
    $0 -t both         # Run both main and Alpine tests
    $0 --shell          # Start interactive shell for debugging
    $0 --build          # Force rebuild and run tests

EOF
}

# Parse arguments
BUILD=false
SHELL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--type)
            TEST_TYPE="$2"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            ;;
        --no-cleanup)
            CLEANUP=false
            ;;
        --build)
            BUILD=true
            ;;
        --shell)
            SHELL_MODE=true
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Validation
if [[ ! "$TEST_TYPE" =~ ^(main|alpine|both)$ ]]; then
    echo "Error: Invalid test type '$TEST_TYPE'. Must be 'main', 'alpine', or 'both'"
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR"

# Helper functions
run_docker_command() {
    local service="$1"
    
    echo "Running $service tests..."
    
    if [[ "$BUILD" == "true" ]]; then
        echo "Building $service container..."
        docker compose -f docker/docker-compose.yml build "$service"
    fi
    
    if [[ "$SHELL_MODE" == "true" ]]; then
        echo "Starting interactive shell for $service..."
        docker compose -f docker/docker-compose.yml run --rm "$service" /bin/bash
    else
        # Set up environment variables
        local env_args=""
        if [[ "$VERBOSE" == "true" ]]; then
            env_args="-e TEST_VERBOSE=true"
        fi
        
        if [[ "$service" == "zellij-utils-test-alpine" ]]; then
            docker compose -f docker/docker-compose.yml --profile alpine-test run --rm $env_args "$service"
        else
            docker compose -f docker/docker-compose.yml run --rm $env_args "$service"
        fi
    fi
}

cleanup_containers() {
    if [[ "$CLEANUP" == "true" ]]; then
        echo "Cleaning up containers..."
        docker compose -f docker/docker-compose.yml down -v --remove-orphans 2>/dev/null || true
    fi
}

# Main execution
main() {
    echo "============================================"
    echo "   Local Docker Testing"
    echo "============================================"
    echo "Test Type: $TEST_TYPE"
    echo "Verbose: $VERBOSE"
    echo "Shell Mode: $SHELL_MODE"
    echo "============================================"
    echo
    
    # Ensure Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        echo "Error: Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker compose version >/dev/null 2>&1; then
        echo "Error: Docker Compose is not available"
        exit 1
    fi
    
    # Set up cleanup trap
    trap cleanup_containers EXIT
    
    # Run tests based on type
    case "$TEST_TYPE" in
        "main")
            run_docker_command "zellij-utils-test"
            ;;
        "alpine")
            run_docker_command "zellij-utils-test-alpine"
            ;;
        "both")
            echo "Running both main and Alpine tests..."
            run_docker_command "zellij-utils-test"
            echo
            echo "============================================"
            echo
            run_docker_command "zellij-utils-test-alpine"
            ;;
    esac
    
    if [[ "$SHELL_MODE" == "false" ]]; then
        echo
        echo "============================================"
        echo "   Local Docker Testing Complete"
        echo "============================================"
        
        # Show test results if available
        if docker volume ls | grep -q zellij-utils_test-results; then
            echo "Test results are available in Docker volume"
            echo "To extract results: docker run --rm -v zellij-utils_test-results:/data alpine tar -czf - /data"
        fi
    fi
}

# Run main function
main "$@"