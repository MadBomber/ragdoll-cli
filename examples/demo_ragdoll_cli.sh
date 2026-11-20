#!/bin/bash
#
# Ragdoll CLI Demo Script
#
# This script demonstrates all available ragdoll-cli commands and capabilities
# including document management, search functionality, and analytics features.
#
# Prerequisites:
# - ragdoll-cli gem installed
# - Ragdoll system configured and running
# - Sample documents in ./sample_docs/ directory
#
# Usage: ./demo_ragdoll_cli.sh

set -e # Exit on any error

echo "🚀 Ragdoll CLI Comprehensive Demo"
echo "=================================="
echo ""
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}📋 $1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

# Helper function to run commands with descriptions
run_command() {
    local description="$1"
    local command="$2"
    echo ""
    echo -e "${YELLOW}➤ $description${NC}"
    echo -e "${GREEN}$ $command${NC}"
    eval "$command"
    echo ""
}

# Create sample documents directory and files
setup_sample_docs() {
    mkdir -p sample_docs

    cat >sample_docs/getting_started.md <<'EOF'
# Getting Started with Ragdoll

Ragdoll is a unified text-based RAG system that converts all media types to searchable text.
Images become AI-generated descriptions, audio becomes transcripts, and documents are
extracted as text for powerful cross-modal search capabilities.

## Features
- Unified text-based search across all media types
- Cross-modal search (find images by describing content)
- AI-powered text conversion (vision models, speech-to-text)
- Support for multiple document formats (PDF, DOCX, CSV, JSON, images, audio)
- Advanced analytics and tracking
- RESTful API and CLI interface
EOF

    cat >sample_docs/user_guide.txt <<'EOF'
User Guide

This guide covers how to use the search functionality effectively.
You can search for documents using natural language queries.
The system will return the most relevant results based on semantic similarity.

Tips for better search results:
- Use descriptive keywords
- Ask complete questions
- Try different phrasings if needed
EOF

    cat >sample_docs/api_reference.md <<'EOF'
# API Reference

## Search Endpoints

### POST /search
Performs a semantic search across all documents.

Parameters:
- query (string): The search query
- limit (integer): Maximum results to return
- search_type (string): semantic, hybrid, or fulltext

### GET /documents
Lists all documents in the system.

### POST /documents
Adds a new document to the system.
EOF

    echo -e "${GREEN}✓ Sample documents created in ./sample_docs/${NC}"
}

print_section "Setup: Creating Sample Documents"
setup_sample_docs

print_section "1. System Information & Health"

run_command "Show version information" \
    "ragdoll version"

run_command "Check system health" \
    "ragdoll health"

run_command "Initialize configuration (if needed)" \
    "ragdoll init"

print_section "2. Document Management"

run_command "Add a single document" \
    "ragdoll add sample_docs/getting_started.md"

run_command "Add multiple documents with progress tracking" \
    "ragdoll add sample_docs/user_guide.txt sample_docs/api_reference.md"

run_command "Add entire directory recursively" \
    "ragdoll add sample_docs/ --recursive"

run_command "Add documents with type filtering (markdown only)" \
    "ragdoll add sample_docs/ --type md"

run_command "List all documents (table format)" \
    "ragdoll list"

run_command "List documents in JSON format" \
    "ragdoll list --format json --limit 5"

run_command "List documents in plain format" \
    "ragdoll list --format plain --limit 10"

# Get a document ID for status/show/update/delete demos
echo -e "${YELLOW}Getting document ID for demo purposes...${NC}"
DOCUMENT_ID=$(ragdoll list --format json --limit 1 2>/dev/null | jq -r '.[0].id' 2>/dev/null || echo "")

if [[ -n "$DOCUMENT_ID" && "$DOCUMENT_ID" != "null" ]]; then
    run_command "Show document status" \
        "ragdoll status $DOCUMENT_ID"

    run_command "Show detailed document information" \
        "ragdoll show $DOCUMENT_ID"

    run_command "Show document in JSON format" \
        "ragdoll show $DOCUMENT_ID --format json"
else
    echo -e "${YELLOW}⚠️  No documents found in system for status/show demo${NC}"
    run_command "Show document status (example)" \
        "echo 'Command: ragdoll status DOCUMENT_ID'
         echo 'Note: Requires actual document ID from system'"

    run_command "Show detailed document information (example)" \
        "echo 'Command: ragdoll show DOCUMENT_ID'
         echo 'Note: Shows metadata, content length, embeddings count, etc.'"
fi

run_command "Update document metadata (example)" \
    "echo 'Command: ragdoll update $DOCUMENT_ID --title \"Updated Document Title\"'
     echo 'Note: Update requires valid document ID from actual system'"

print_section "3. Search Functionality"

run_command "Basic semantic search" \
    "ragdoll search 'how to get started'"

run_command "Search with result limit" \
    "ragdoll search 'API documentation' --limit 3"

run_command "Search with classification filter" \
    "ragdoll search 'user guide' --classification documentation"

run_command "Search with keyword filtering" \
    "ragdoll search 'search tips' --keywords 'guide,tips,help'"

run_command "Search with tags filtering" \
    "ragdoll search 'documentation' --tags 'guide,reference'"

run_command "Search in JSON format" \
    "ragdoll search 'semantic search' --format json"

run_command "Search in plain text format" \
    "ragdoll search 'endpoints' --format plain"

print_section "4. Advanced Search with Tracking"

run_command "Search with session and user tracking" \
    "ragdoll search 'getting started guide' --session_id 'demo-session-123' --user_id 'demo-user-456'"

run_command "Hybrid search (semantic + fulltext)" \
    "ragdoll search 'API reference' --search_type hybrid"

run_command "Hybrid search with custom weights" \
    "ragdoll search 'documentation guide' --search_type hybrid --semantic_weight 0.6 --text_weight 0.4"

run_command "Fulltext search only" \
    "ragdoll search 'parameters' --search_type fulltext"

run_command "Search with tracking disabled" \
    "ragdoll search 'user guide' --track_search false"

print_section "5. Context & Prompt Enhancement"

run_command "Get context for RAG applications" \
    "ragdoll context 'How do I search for documents?' --limit 3"

run_command "Enhance a prompt with context" \
    "ragdoll enhance 'Explain how to use the search API' --context_limit 2"

print_section "6. System Statistics"

run_command "Show comprehensive system statistics" \
    "ragdoll stats"

print_section "7. Search Analytics & Reporting"

run_command "Show search analytics overview (default 30 days)" \
    "ragdoll analytics overview"

run_command "Show analytics for specific time period" \
    "ragdoll analytics overview --days 7"

run_command "Show analytics in JSON format" \
    "ragdoll analytics overview --days 14 --format json"

run_command "Show recent search history" \
    "ragdoll analytics history"

run_command "Show search history with filters" \
    "ragdoll analytics history --user_id demo-user-456 --limit 10"

run_command "Show search history for specific session" \
    "ragdoll analytics history --session_id demo-session-123"

run_command "Show search history in JSON format" \
    "ragdoll analytics history --format json --limit 5"

run_command "Show search history in plain format" \
    "ragdoll analytics history --format plain --limit 5"

run_command "Show trending search queries (default 7 days)" \
    "ragdoll analytics trending"

run_command "Show trending queries for custom period" \
    "ragdoll analytics trending --days 14 --limit 15"

run_command "Show trending queries in JSON format" \
    "ragdoll analytics trending --format json"

run_command "Cleanup old search records (dry run)" \
    "ragdoll analytics cleanup --days 30"

run_command "Cleanup with custom retention period" \
    "ragdoll analytics cleanup --days 60 --dry_run"

run_command "Perform actual cleanup (use with caution)" \
    "ragdoll analytics cleanup --days 90 --force"

print_section "8. Individual Analytics Commands"

run_command "Quick search statistics" \
    "ragdoll search-stats --days 30"

run_command "Search statistics in JSON format" \
    "ragdoll search-stats --format json --days 7"

run_command "Recent search history (individual command)" \
    "ragdoll search-history --limit 15"

run_command "Search history with user filter" \
    "ragdoll search-history --user_id demo-user-456"

run_command "Trending queries (individual command)" \
    "ragdoll trending --days 14 --limit 12"

run_command "Cleanup searches (individual command)" \
    "ragdoll cleanup-searches --days 45 --dry_run"

print_section "9. Configuration Management"

run_command "Show current configuration" \
    "ragdoll config show"

run_command "Show configuration in JSON format" \
    "ragdoll config show --format json"

run_command "Set configuration value" \
    "ragdoll config set search.default_limit 15"

run_command "Get specific configuration value" \
    "ragdoll config get search.default_limit"

run_command "List all configuration keys" \
    "ragdoll config list"

run_command "Reset configuration to defaults" \
    "ragdoll config reset --confirm"

print_section "10. Advanced Use Cases"

run_command "Batch search with tracking for analytics" \
    "for query in 'getting started' 'API reference' 'user guide' 'search tips'; do
       ragdoll search \"\$query\" --session_id batch-session-789 --user_id analytics-demo
     done"

run_command "Search workflow simulation" \
    "# Simulate user search session
     ragdoll search 'how to search documents' --session_id workflow-demo --user_id test-user
     ragdoll search 'API documentation' --session_id workflow-demo --user_id test-user
     ragdoll search 'configuration guide' --session_id workflow-demo --user_id test-user"

run_command "Export search history for analysis" \
    "ragdoll analytics history --format json --limit 50 > search_history_export.json
     echo 'Search history exported to search_history_export.json'"

run_command "Generate analytics report" \
    "echo '# Ragdoll Search Analytics Report' > analytics_report.md
     echo '' >> analytics_report.md
     echo '## Overview' >> analytics_report.md
     ragdoll analytics overview --format json | jq -r 'to_entries[] | \"- \(.key): \(.value)\"' >> analytics_report.md
     echo '' >> analytics_report.md
     echo '## Recent Searches' >> analytics_report.md
     ragdoll analytics history --format plain --limit 10 >> analytics_report.md
     echo 'Analytics report generated: analytics_report.md'"

print_section "11. Document Removal Commands"

run_command "Delete a document (example - interactive)" \
    "echo 'Command: ragdoll delete DOCUMENT_ID'
     echo 'Note: This will prompt for confirmation before deletion'"

run_command "Force delete without confirmation (example)" \
    "echo 'Command: ragdoll delete DOCUMENT_ID --force'
     echo '⚠️  Warning: This bypasses confirmation prompts'"

echo -e "${RED}⚠️  Document deletion commands not executed in demo for safety${NC}"

print_section "12. Help and Documentation"

run_command "Show main help" \
    "ragdoll help"

run_command "Show help for specific commands" \
    "ragdoll help search"

run_command "Show analytics subcommand help" \
    "ragdoll help analytics"

run_command "Show config subcommand help" \
    "ragdoll help config"

print_section "Demo Complete!"

echo ""
echo -e "${GREEN}✅ Ragdoll CLI Demo completed successfully!${NC}"
echo ""
echo -e "${BLUE}Summary of demonstrated features:${NC}"
echo "• Document management (add, list, show, update, delete)"
echo "• Semantic, hybrid, and fulltext search with configurable weights"
echo "• Search tracking with session and user IDs"
echo "• Comprehensive analytics and reporting"
echo "• Context retrieval for RAG applications"
echo "• Prompt enhancement with relevant context"
echo "• Configuration management"
echo "• System health and statistics monitoring"
echo "• Multiple output formats (table, JSON, plain text)"
echo "• Batch operations and workflow automation"
echo ""
echo -e "${YELLOW}Generated files:${NC}"
echo "• ./sample_docs/ - Sample documents directory"
echo "• search_history_export.json - Exported search data"
echo "• analytics_report.md - Generated analytics report"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "• Explore the generated files"
echo "• Customize commands for your specific use case"
echo "• Set up automated analytics reporting"
echo "• Integrate ragdoll-cli into your workflows"
echo ""
echo "🎉 Happy document searching with Ragdoll!"
