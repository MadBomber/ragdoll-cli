# Ragdoll

Ragdoll is a comprehensive RAG (Retrieval-Augmented Generation) system that combines both core and CLI components. The core provides the foundational multi-modal document processing and semantic search capabilities, while the CLI offers a user-friendly interface for interacting with these features.

## Core Capabilities

### Overview

Ragdoll::Core is a database-oriented multi-modal RAG library built on ActiveRecord. It features PostgreSQL + pgvector for high-performance semantic search, polymorphic content architecture, and dual metadata design for sophisticated document analysis.

### Quick Start

```ruby
require 'ragdoll-core'

# Configure with PostgreSQL + pgvector
Ragdoll::Core.configure do |config|
  config.llm_provider = :openai
  config.embedding_model = 'text-embedding-3-small'
  config.database_config = {
    adapter: 'postgresql',
    database: 'ragdoll_production',
    username: 'ragdoll',
    password: ENV['DATABASE_PASSWORD'],
    host: 'localhost',
    port: 5432,
    auto_migrate: true
  }

  # Logging configuration
  config.log_level = :warn
  config.log_file = File.join(Dir.home, '.ragdoll', 'ragdoll.log')
end

# Add documents - returns detailed result
result = Ragdoll::Core.add_document(path: 'research_paper.pdf')
puts result[:message]  # "Document 'research_paper' added successfully with ID 123"
doc_id = result[:document_id]

# Check document status
status = Ragdoll::Core.document_status(id: doc_id)
puts status[:message]  # Shows processing status and embeddings count

# Search across content
results = Ragdoll::Core.search(query: 'neural networks')

# Get detailed document information
document = Ragdoll::Core.get_document(id: doc_id)
```

### High-Level API

The `Ragdoll` module provides a convenient high-level API for common operations, including document management, search and retrieval, and system operations.

## CLI User Commands

### Installation

```bash
gem install ragdoll-cli
```

This will install the `ragdoll` command-line tool.

### Quick Start

1. **Initialize configuration:**
   ```bash
   ragdoll init
   ```

2. **Set your API key:**
   ```bash
   export OPENAI_API_KEY=your_api_key_here
   ```

3. **Import documents:**
   ```bash
   ragdoll import "docs/*.pdf" --recursive
   ```

4. **Search for content:**
   ```bash
   ragdoll search "What is machine learning?"
   ```

### Commands

#### Configuration

```bash
# Initialize configuration
ragdoll init

# Show current configuration
ragdoll config show

# Set configuration values
ragdoll config set llm_provider openai
ragdoll config set chunk_size 1000

# Get configuration values
ragdoll config get embedding_model

# Show config file path
ragdoll config path

# Show database configuration and status
ragdoll config database
```

#### Document Import

```bash
# Import files matching a pattern
ragdoll import "documents/*.pdf"

# Import recursively from directory
ragdoll import "docs/**/*" --recursive

# Filter by document type
ragdoll import "files/*" --type pdf

# Available types: pdf, docx, txt, md, html
```

#### Search

```bash
# Basic search
ragdoll search "machine learning concepts"

# Limit number of results
ragdoll search "AI algorithms" --limit 5

# Different output formats
ragdoll search "deep learning" --format json
ragdoll search "AI" --format plain
ragdoll search "ML" --format table  # default
```

#### Document Management

```bash
# Add a single document
ragdoll add <path>

# List all documents
ragdoll list

# Limit number of documents shown
ragdoll list --limit 10

# Different output formats
ragdoll list --format json
ragdoll list --format plain

# Check document status
ragdoll status <id>

# Update document metadata
ragdoll update <id> --title "New Title"

# Delete a document
ragdoll delete <id>
ragdoll delete <id> --force  # Bypass confirmation

# Show system statistics
ragdoll stats
ragdoll stats --format json
ragdoll stats --format plain
```

#### Retrieval Utilities

```bash
# Get context for RAG applications
ragdoll context "<query>" --limit 5

# Enhance a prompt with context
ragdoll enhance "<prompt>" --context_limit 5
```

#### Utilities

```bash
# Show version information
ragdoll version

# Show help
ragdoll help
ragdoll help import  # Help for specific command

# Check system health
ragdoll health
```

## Configuration

The CLI uses a YAML configuration file located at `~/.ragdoll/config.yml`. You can customize various settings, and API keys can be set via environment variables.

## Storage

Documents and embeddings are stored in a PostgreSQL database managed by the `ragdoll-core` gem for production performance. Configuration and log files are stored locally in `~/.ragdoll/`.

## Supported Document Types

- **PDF files** (`.pdf`) - Extracts text and metadata
- **Microsoft Word** (`.docx`) - Extracts text, tables, and metadata
- **Text files** (`.txt`) - Plain text import
- **Markdown** (`.md`, `.markdown`) - Markdown document import
- **HTML** (`.html`, `.htm`) - Strips HTML tags and imports text

## Examples

### Import a directory of documentation

```bash
# Import all markdown files from a docs directory
ragdoll import "docs/**/*.md" --recursive

# Import mixed document types
ragdoll import "knowledge-base/*" --recursive
```

### Search and get enhanced prompts

```bash
# Basic search
ragdoll search "How to configure SSL certificates?"

# Get detailed results
ragdoll search "database optimization" --format plain --limit 3
```

### Manage your knowledge base

```bash
# See what's in your knowledge base
ragdoll stats
ragdoll list --limit 20

# Check status of a specific document
ragdoll status 123

# Update document title
ragdoll update 123 --title "Updated Document Title"

# Delete a document
ragdoll delete 123
```

## Integration with Other Tools

The CLI is designed to work well with other command-line tools:

```bash
# Search and pipe to jq for JSON processing
ragdoll search "API documentation" --format json | jq '.results[0].content'

# Import files found by find command
find ./docs -name "*.pdf" -exec ragdoll import {} \;

# Use with xargs for batch processing
ls *.md | xargs -I {} ragdoll import {}
```

## Troubleshooting

### Common Issues

1. **No API key configured:**
   ```
   Error: Missing API key
   Solution: Set OPENAI_API_KEY environment variable or add to config
   ```

2. **No documents found:**
   ```
   ragdoll stats  # Check if documents are imported
   ragdoll list   # See what documents exist
   ```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MadBomber/ragdoll-cli.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
