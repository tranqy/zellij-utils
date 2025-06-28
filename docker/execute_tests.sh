#!/bin/bash
# Automated test execution script - builds and runs tests in Docker
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT_HOST_DIR="$PROJECT_DIR/test-results"
CONTAINER_NAME="zellij-utils-test"
IMAGE_NAME="zellij-utils:test"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Print usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Automated test execution for Zellij Utils in Docker environment.

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -c, --clean         Clean up before running tests
    -k, --keep          Keep container running after tests
    -o, --output DIR    Custom output directory (default: ./test-results)
    -t, --timeout SEC   Test timeout in seconds (default: 600)
    --alpine            Use Alpine Linux container
    --no-cache          Build without Docker cache

COMMANDS:
    build               Build Docker image only
    test                Run tests (default)
    shell               Start interactive shell in container
    clean               Clean up containers and images
    logs                Show container logs
    results             Show latest test results

EXAMPLES:
    $0                  # Run tests with default settings
    $0 -v -c            # Run tests with verbose output and cleanup
    $0 --alpine test    # Run tests in Alpine container
    $0 shell            # Start interactive shell for debugging
    $0 clean            # Clean up Docker resources

EOF
}

# Parse command line arguments
VERBOSE=false
CLEAN=false
KEEP_CONTAINER=false
USE_ALPINE=false
NO_CACHE=false
TEST_TIMEOUT=600
COMMAND="test"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -k|--keep)
            KEEP_CONTAINER=true
            shift
            ;;
        -o|--output)
            TEST_OUTPUT_HOST_DIR="$2"
            shift 2
            ;;
        -t|--timeout)
            TEST_TIMEOUT="$2"
            shift 2
            ;;
        --alpine)
            USE_ALPINE=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        build|test|shell|clean|logs|results)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Set image and container names based on Alpine flag
if [[ "$USE_ALPINE" == "true" ]]; then
    IMAGE_NAME="zellij-utils:test-alpine"
    CONTAINER_NAME="zellij-utils-test-alpine"
fi

# Check Docker availability
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running or not accessible"
        exit 1
    fi
    
    log_info "Docker is available"
}

# Clean up existing containers and images
cleanup_docker() {
    log_info "Cleaning up Docker resources..."
    
    # Stop and remove container if running
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Stopping and removing container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
    
    # Remove image if exists
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}$"; then
        log_info "Removing image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME" >/dev/null 2>&1 || true
    fi
    
    # Clean up test results if requested
    if [[ "$CLEAN" == "true" && -d "$TEST_OUTPUT_HOST_DIR" ]]; then
        log_info "Removing previous test results"
        rm -rf "$TEST_OUTPUT_HOST_DIR"
    fi
    
    log_success "Cleanup complete"
}

# Build Docker image
build_image() {
    log_info "Building Docker image: $IMAGE_NAME"
    
    local dockerfile="Dockerfile"
    if [[ "$USE_ALPINE" == "true" ]]; then
        dockerfile="Dockerfile.alpine"
    fi
    
    local build_args=()
    if [[ "$NO_CACHE" == "true" ]]; then
        build_args+=("--no-cache")
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        build_args+=("--progress=plain")
    fi
    
    cd "$PROJECT_DIR"
    
    if docker build \
        "${build_args[@]}" \
        -f "docker/$dockerfile" \
        -t "$IMAGE_NAME" \
        .; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Run tests in container
run_tests() {
    log_info "Running tests in Docker container..."
    
    # Create output directory
    mkdir -p "$TEST_OUTPUT_HOST_DIR"
    
    # Docker run arguments
    local docker_args=(
        "--name" "$CONTAINER_NAME"
        "--rm"
        "-v" "$TEST_OUTPUT_HOST_DIR:/app/test-results"
        "-e" "TEST_VERBOSE=$VERBOSE"
        "-e" "TEST_TIMEOUT=$TEST_TIMEOUT"
        "-e" "TERM=xterm-256color"
    )
    
    # Keep container if requested
    if [[ "$KEEP_CONTAINER" == "true" ]]; then
        docker_args=(
            "${docker_args[@]/--rm/}"  # Remove --rm flag
            "-d"  # Run detached
        )
    fi
    
    # Add verbose flag if requested
    if [[ "$VERBOSE" == "true" ]]; then
        docker_args+=("-e" "TEST_VERBOSE=true")
    fi
    
    log_info "Starting container: $CONTAINER_NAME"
    
    if [[ "$KEEP_CONTAINER" == "true" ]]; then
        # Run detached
        if docker run "${docker_args[@]}" "$IMAGE_NAME"; then
            log_info "Container started. Use 'docker logs -f $CONTAINER_NAME' to follow logs"
            log_info "Use 'docker exec -it $CONTAINER_NAME bash' for interactive access"
        else
            log_error "Failed to start container"
            exit 1
        fi
    else
        # Run and wait for completion
        local exit_code=0
        if ! docker run "${docker_args[@]}" "$IMAGE_NAME"; then
            exit_code=$?
            log_error "Tests failed with exit code: $exit_code"
        fi
        
        # Show results summary
        show_results_summary
        
        return $exit_code
    fi
}

# Start interactive shell
start_shell() {
    log_info "Starting interactive shell in container..."
    
    # Check if container is already running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Connecting to running container: $CONTAINER_NAME"
        docker exec -it "$CONTAINER_NAME" bash
    else
        log_info "Starting new container for interactive session"
        docker run \
            --name "$CONTAINER_NAME-shell" \
            --rm \
            -it \
            -v "$TEST_OUTPUT_HOST_DIR:/app/test-results" \
            -e "TERM=xterm-256color" \
            "$IMAGE_NAME" \
            bash
    fi
}

# Show container logs
show_logs() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Showing logs for container: $CONTAINER_NAME"
        docker logs -f "$CONTAINER_NAME"
    else
        log_error "Container $CONTAINER_NAME not found"
        exit 1
    fi
}

# Show test results summary
show_results_summary() {
    local results_file="$TEST_OUTPUT_HOST_DIR/test_plan_results.md"
    
    if [[ -f "$results_file" ]]; then
        log_info "=== Test Results Summary ==="
        
        # Extract key metrics from results
        local total_tests=$(grep "Total Tests" "$results_file" | grep -oE '[0-9]+' | head -1)
        local passed_tests=$(grep "Passed" "$results_file" | grep -oE '[0-9]+' | head -1)
        local failed_tests=$(grep "Failed" "$results_file" | grep -oE '[0-9]+' | head -1)
        
        echo "Total Tests: ${total_tests:-0}"
        echo "Passed: ${passed_tests:-0}"
        echo "Failed: ${failed_tests:-0}"
        
        if [[ "${failed_tests:-0}" -eq 0 ]]; then
            log_success "🎉 All tests passed!"
        else
            log_error "❌ $failed_tests test(s) failed"
        fi
        
        echo ""
        log_info "Full results available at: $results_file"
        
        # Show failed tests if any
        if [[ "${failed_tests:-0}" -gt 0 ]]; then
            echo ""
            log_warning "Failed tests:"
            grep "❌" "$results_file" | head -10 || true
        fi
    else
        log_warning "Test results file not found: $results_file"
    fi
}

# Show latest results
show_results() {
    local results_file="$TEST_OUTPUT_HOST_DIR/test_plan_results.md"
    
    if [[ -f "$results_file" ]]; then
        log_info "Displaying test results from: $results_file"
        echo ""
        
        if command -v less >/dev/null 2>&1; then
            less "$results_file"
        elif command -v more >/dev/null 2>&1; then
            more "$results_file"
        else
            cat "$results_file"
        fi
    else
        log_error "No test results found. Run tests first with: $0 test"
        exit 1
    fi
}

# Main execution function
main() {
    log_info "Zellij Utils Docker Test Executor"
    log_info "Command: $COMMAND"
    log_info "Project: $PROJECT_DIR"
    log_info "Output: $TEST_OUTPUT_HOST_DIR"
    
    if [[ "$USE_ALPINE" == "true" ]]; then
        log_info "Using Alpine Linux container"
    fi
    
    # Check prerequisites
    check_docker
    
    case "$COMMAND" in
        "build")
            if [[ "$CLEAN" == "true" ]]; then
                cleanup_docker
            fi
            build_image
            ;;
        "test")
            if [[ "$CLEAN" == "true" ]]; then
                cleanup_docker
            fi
            build_image
            if run_tests; then
                log_success "Tests completed successfully"
                exit 0
            else
                log_error "Tests failed"
                exit 1
            fi
            ;;
        "shell")
            if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}$"; then
                log_info "Image not found, building first..."
                build_image
            fi
            start_shell
            ;;
        "clean")
            cleanup_docker
            ;;
        "logs")
            show_logs
            ;;
        "results")
            show_results
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
}

# Error handling
set -o errtrace
trap 'log_error "Script failed at line $LINENO"' ERR

# Execute main function
main "$@"