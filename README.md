<div align="center" style="background-color: yellow; color: black; padding: 20px; margin: 20px 0; border: 2px solid black; font-size: 48px; font-weight: bold;">
  ⚠️ CAUTION ⚠️<br />
  Software Under Development by a Crazy Man
</div>
<br />
<div align="center">
  <table>
    <tr>
      <td width="50%">
        <a href="https://research.ibm.com/blog/retrieval-augmented-generation-RAG" target="_blank">
          <img src="ragdoll-cli.png" alt="Ragdoll CLI Putting the Puzzle Together" width="800">
        </a>
      </td>
      <td width="50%" valign="top">
        <p>Multi-modal RAG (Retrieval-Augmented Generation) is an architecture that integrates multiple data types (such as text, images, and audio) to enhance AI response generation. It combines retrieval-based methods, which fetch relevant information from a knowledge base, with generative large language models (LLMs) that create coherent and contextually appropriate outputs. This approach allows for more comprehensive and engaging user interactions, such as chatbots that respond with both text and images or educational tools that incorporate visual aids into learning materials. By leveraging various modalities, multi-modal RAG systems improve context understanding and user experience.</p>
      </td>
    </tr>
  </table>
</div>

# Ragdoll::CLI

Standalone command-line interface for the Ragdoll RAG (Retrieval-Augmented Generation) system. Provides document import, search, and management capabilities through a simple CLI.

## Installation

```bash
gem install ragdoll-cli
```

This will install the `ragdoll` command-line tool.

## Quick Start

1. **Initialize configuration:**
   ```bash
   ragdoll init
   ```

2. **Set your API key:**
   ```bash
   export OPENAI_API_KEY=your_api_key_here
   ```

3. **Add documents:**
   ```bash
   ragdoll add docs/*.pdf --recursive
   ```

4. **Search for content:**
   ```bash
   ragdoll search "What is machine learning?"
   ```

## Commands

### Configuration

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

### Document Management

```bash
# Add a single document
ragdoll add document.pdf

# Add multiple documents and directories
ragdoll add file1.pdf file2.txt ../docs

# Add files matching a pattern
ragdoll add "documents/*.pdf"

# Add recursively from directory (default: true)
ragdoll add "docs/" --recursive

# Filter by document type
ragdoll add "files/*" --type pdf

# Available types: pdf, docx, txt, md, html

# Skip confirmation prompts
ragdoll add docs/ --skip-confirmation

# Force addition of duplicate documents
ragdoll add document.pdf --force-duplicate

# Available types: pdf, docx, txt, md, html
```

#### Duplicate Detection

Ragdoll automatically detects and prevents duplicate documents from being processed:

```bash
# Normal behavior - duplicates are detected and skipped
ragdoll add document.pdf
ragdoll add document.pdf  # Skipped (duplicate detected)

# Force addition of duplicates when needed
ragdoll add document.pdf --force-duplicate  # Creates new document despite duplicate

# Batch processing safely handles mixed new/duplicate files
ragdoll add docs/*.pdf  # Only processes new files, skips duplicates
```

**Duplicate Detection Features:**
- **File-based detection**: Compares file location, modification time, and SHA256 hash
- **Content-based detection**: Compares extracted text content and metadata
- **Smart similarity**: Detects duplicates even with minor differences (5% tolerance)
- **Performance optimized**: Uses database indexes for fast duplicate lookups

### Search

```bash
# Basic semantic search (default)
ragdoll search "machine learning concepts"

# Full-text search for exact keywords
ragdoll search "neural networks" --search-type fulltext

# Hybrid search combining semantic and full-text
ragdoll search "AI algorithms" --search-type hybrid

# Customize hybrid search weights
ragdoll search "deep learning" --search-type hybrid --semantic-weight 0.6 --text-weight 0.4

# Limit number of results
ragdoll search "AI algorithms" --limit 5

# Set similarity threshold
ragdoll search "machine learning" --threshold 0.8

# Different output formats
ragdoll search "deep learning" --format json
ragdoll search "AI" --format plain
ragdoll search "ML" --format table  # default
```

#### Search Types

- **Semantic Search** (default): Uses AI embeddings to find conceptually similar content
- **Full-text Search**: Uses PostgreSQL text search for exact keyword matching
- **Hybrid Search**: Combines both semantic and full-text search with configurable weights

```bash
# Semantic search - best for concepts and meaning
ragdoll search "How do neural networks learn?" --search-type semantic

# Full-text search - best for exact terms
ragdoll search "backpropagation algorithm" --search-type fulltext

# Hybrid search - best comprehensive results
ragdoll search "transformer architecture" --search-type hybrid --semantic-weight 0.7 --text-weight 0.3
```

### Document Operations

```bash
# List all documents
ragdoll list

# Limit number of documents shown
ragdoll list --limit 10

# Different output formats
ragdoll list --format json
ragdoll list --format plain

# Check document status
ragdoll status <id>

# Show detailed document information
ragdoll show <id>
ragdoll show <id> --format json

# Update document metadata
ragdoll update <id> --title "New Title"

# Delete a document
ragdoll delete <id>
ragdoll delete <id> --force  # Bypass confirmation

# Show system statistics
ragdoll stats
```

### Retrieval Utilities

```bash
# Get context for RAG applications
ragdoll context "<query>" --limit 5

# Enhance a prompt with context
ragdoll enhance "<prompt>" --context_limit 5
```

### Utilities

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

The CLI uses a YAML configuration file located at `~/.ragdoll/config.yml`. You can customize various settings:

```yaml
llm_provider: openai
embedding_provider: openai
embedding_model: text-embedding-3-small
chunk_size: 1000
chunk_overlap: 200
search_similarity_threshold: 0.7
max_search_results: 10
storage_backend: file
storage_config:
  directory: "~/.ragdoll"
api_keys:
  openai: your_key_here
  anthropic: your_key_here
```

### Environment Variables

API keys can be set via environment variables (recommended):

```bash
export OPENAI_API_KEY=your_key_here
export ANTHROPIC_API_KEY=your_key_here
export GOOGLE_API_KEY=your_key_here
export AZURE_OPENAI_API_KEY=your_key_here
export HUGGINGFACE_API_KEY=your_key_here
export OLLAMA_ENDPOINT=http://localhost:11434
```

### Custom Configuration Location

```bash
export RAGDOLL_CONFIG=/path/to/custom/config.yml
```

## Storage

Documents and embeddings are stored in a PostgreSQL database managed by the `ragdoll-core` gem for production performance. Configuration and log files are stored locally in `~/.ragdoll/`:

- `~/.ragdoll/config.yml` - Configuration settings
- `~/.ragdoll/ragdoll.log` - Log file (if configured)

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
# Semantic search for concepts
ragdoll search "How to configure SSL certificates?"

# Full-text search for specific terms
ragdoll search "SSL certificate configuration" --search-type fulltext

# Hybrid search for comprehensive results
ragdoll search "database optimization techniques" --search-type hybrid

# Get detailed results with custom formatting
ragdoll search "performance tuning" --format plain --limit 3

# Search with custom similarity threshold
ragdoll search "security best practices" --threshold 0.75 --search-type semantic
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
