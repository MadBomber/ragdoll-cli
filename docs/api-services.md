# Services Reference

> **TODO:** This documentation is under development. Please check back later for complete content.

## Business Logic and Processing Services

TODO: Document all service classes in the Ragdoll-Core system, including:

- Service responsibilities and interfaces
- Method signatures and parameters
- Usage examples and patterns
- Error handling and exceptions

## Core Services

## DocumentProcessor

**Responsibility**: Multi-format document parsing and content extraction

**Key Methods**:
```ruby
class DocumentProcessor
  # Parse document from file path
  def self.parse(file_path)
    # Returns: { content:, metadata:, document_type: }
  end
  
  # Format-specific parsers
  def parse_pdf(file_path)    # PDF extraction with pdf-reader
  def parse_docx(file_path)   # DOCX extraction with docx gem
  def parse_html(file_path)   # HTML parsing with Nokogiri
  def parse_markdown(file_path) # Markdown processing
end
```

**Features**:
- Multi-format support (PDF, DOCX, HTML, Markdown, plain text)
- Metadata extraction from document properties
- Error handling for malformed documents
- Encoding detection and normalization

## DocumentManagement

**Responsibility**: Document CRUD operations and database persistence

**Key Methods**:
```ruby
class DocumentManagement
  # Create new document record
  def self.add_document(location, content, metadata = {})
    # Returns: document_id (string)
  end
  
  # Retrieve document with content
  def self.get_document(id)
    # Returns: document hash with all associated data
  end
  
  # Update document metadata and properties
  def self.update_document(id, **updates)
    # Returns: updated document hash
  end
  
  # Remove document and associated content
  def self.delete_document(id)
    # Returns: true on success, nil if not found
  end
  
  # List documents with pagination
  def self.list_documents(options = {})
    # Returns: array of document hashes
  end
  
  # System statistics
  def self.get_document_stats
    # Returns: statistics hash
  end
  
  # Add embedding to existing content
  def self.add_embedding(embeddable_id, chunk_index, embedding_vector, metadata = {})
    # Returns: embedding_id (string)
  end
end
```

**Features**:
- Database abstraction for document operations
- Automatic path normalization (file paths to absolute paths)
- Support for URLs and remote content
- Integration with background job processing
- Comprehensive error handling

## EmbeddingService

**Responsibility**: Vector generation for different content types

**Key Methods**:
```ruby
class EmbeddingService
  # Generate single embedding
  def generate_embedding(text)
    # Returns: vector array or nil
  end
  
  # Generate multiple embeddings efficiently
  def generate_embeddings_batch(texts)
    # Returns: array of vectors
  end
  
  # Calculate similarity between vectors
  def cosine_similarity(vector_a, vector_b)
    # Returns: similarity score (0.0 to 1.0)
  end
end
```

**Features**:
- Multiple LLM provider support (OpenAI, Anthropic, etc.)
- Batch processing for efficiency
- Text preprocessing and cleanup
- Provider failover and error handling

## TextChunker

**Responsibility**: Intelligent text segmentation

**Key Methods**:
```ruby
class TextChunker
  # Basic text chunking
  def self.chunk(text, chunk_size: 1000, chunk_overlap: 200)
    # Returns: array of text chunks
  end
  
  # Structure-aware chunking
  def self.chunk_by_structure(text, options = {})
    # Returns: chunks respecting document structure
  end
  
  # Code-aware chunking
  def self.chunk_code(text, language: nil)
    # Returns: chunks respecting code boundaries
  end
end
```

**Features**:
- Configurable chunk sizes and overlap
- Content-aware chunking strategies
- Sentence and paragraph boundary detection
- Code-aware chunking for programming content

## SearchEngine

**Responsibility**: Semantic and hybrid search operations

**Key Methods**:
```ruby
class SearchEngine
  # Semantic search using embeddings
  def search_documents(query, options = {})
    # Returns: array of search results with similarity scores
  end
  
  # Direct embedding-based search
  def search_similar_content(query_or_embedding, options = {})
    # Returns: array of content matches
  end
end
```

**Features**:
- Semantic similarity search using pgvector
- Document-type filtering support
- Configurable similarity thresholds
- Result ranking and relevance scoring
- Multi-modal content search

## TextGenerationService

**Responsibility**: LLM integration for content analysis

**Key Methods**:
```ruby
class TextGenerationService
  # Generate document summary
  def generate_summary(text, max_length: 500)
    # Returns: summary string
  end
  
  # Extract keywords from text
  def extract_keywords(text, max_keywords: 20)
    # Returns: array of keyword strings
  end
end
```

**Features**:
- LLM integration for content analysis
- Summary and keyword generation
- Multi-provider support
- Error handling and retries
- Fallback extraction methods

## Specialized Services

TODO: Document additional services:

### MetadataGenerator
- AI-powered content analysis
- Schema validation
- Structured metadata creation
- Quality assessment

### Database Service
- Connection management
- Migration handling
- Multi-adapter support
- Performance monitoring

## Service Configuration

TODO: Document service configuration:

- Provider selection and setup
- API key management
- Performance tuning options
- Error handling strategies

## Usage Patterns

TODO: Document common usage patterns:

- Service initialization
- Method chaining
- Error handling
- Testing approaches

## Integration Examples

TODO: Provide integration examples:

- Custom service implementation
- Service composition patterns
- Extension points
- Plugin architecture

---

*This document is part of the Ragdoll-Core documentation suite. For immediate help, see the [Quick Start Guide](quick-start.md) or [API Reference](api-client.md).*