# Ragdoll CLI Search Modes

The ragdoll-cli now supports three distinct search modes to query your document collection:

## 1. Semantic Search (Default)

Semantic search uses AI-generated embeddings to find documents based on meaning and context, not just keyword matches.

```bash
# Basic semantic search
ragdoll search "machine learning concepts"

# With similarity threshold
ragdoll search "neural networks" --threshold 0.7

# Limit results
ragdoll search "deep learning" --limit 10
```

**Best for:**
- Conceptual queries
- Finding related content even without exact keyword matches
- Questions and natural language queries

## 2. Full-Text Search

Full-text search uses PostgreSQL's built-in text search capabilities to find documents containing specific words.

```bash
# Full-text search
ragdoll search "machine learning" --search-type fulltext

# With threshold for match ratio
ragdoll search "neural network" --search-type fulltext --threshold 0.5
```

**Best for:**
- Exact keyword matching
- Finding documents with specific terms
- When you know the exact words used in documents

## 3. Hybrid Search

Hybrid search combines both semantic and full-text search, providing the best of both approaches.

```bash
# Hybrid search with default weights (70% semantic, 30% text)
ragdoll search "machine learning" --search-type hybrid

# Custom weights (50/50 split)
ragdoll search "AI models" --search-type hybrid --semantic-weight 0.5 --text-weight 0.5

# Emphasize text matching
ragdoll search "tensorflow keras" --search-type hybrid --semantic-weight 0.3 --text-weight 0.7
```

**Best for:**
- Comprehensive searches
- When you want both conceptual and keyword matches
- Finding the most relevant results across different matching criteria

## Command Options

### Common Options
- `--limit, -l NUMBER`: Maximum number of results (default: 10)
- `--threshold NUMBER`: Similarity/match threshold 0.0-1.0 (lower = more results)
- `--format, -f FORMAT`: Output format (table, json, plain)

### Search Type Options
- `--search-type, -S TYPE`: Search type (semantic, fulltext, hybrid)
- `--semantic-weight, -w NUMBER`: Weight for semantic search in hybrid mode (0.0-1.0, default: 0.7)
- `--text-weight, -W NUMBER`: Weight for text search in hybrid mode (0.0-1.0, default: 0.3)

### Filtering Options
- `--content-type, -c TYPE`: Filter by content type (text, image, audio)
- `--classification, -C CLASS`: Filter by document classification
- `--tags, -T TAGS`: Filter by tags (comma-separated)

## Examples

### Find conceptually similar documents
```bash
ragdoll search "How do neural networks learn?" --search-type semantic
```

### Find documents with exact terms
```bash
ragdoll search "backpropagation algorithm" --search-type fulltext
```

### Balanced search for technical topics
```bash
ragdoll search "transformer architecture attention mechanism" \
  --search-type hybrid \
  --semantic-weight 0.6 \
  --text-weight 0.4
```

### Get detailed JSON output
```bash
ragdoll search "machine learning" --search-type hybrid --format json
```

## Understanding Results

### Semantic Search Results
- **Similarity Score**: 0.0 to 1.0 (higher = more similar)
- Based on vector distance in embedding space

### Full-Text Search Results
- **Text Match Score**: 0.0 to 1.0 (ratio of query words found)
- Based on word presence in document

### Hybrid Search Results
- **Combined Score**: Weighted combination of semantic and text scores
- **Match Types**: Shows which search types found the result
- Results are deduplicated by document ID

## Performance Tips

1. **Use semantic search** for exploratory queries and concepts
2. **Use full-text search** when you know exact terms
3. **Use hybrid search** for comprehensive results
4. **Adjust weights** based on your use case:
   - Higher semantic weight for conceptual searches
   - Higher text weight for keyword-focused searches
5. **Set appropriate thresholds**:
   - Lower thresholds return more results but may include less relevant ones
   - Higher thresholds return fewer but more relevant results

## Troubleshooting

### No results found?
- Lower the threshold: `--threshold 0.3`
- Try a different search type
- Use broader search terms
- Check if documents have been processed: `ragdoll stats`

### Too many results?
- Increase the threshold: `--threshold 0.8`
- Use more specific search terms
- Reduce the limit: `--limit 5`

### Unexpected results in hybrid search?
- Adjust the weights to favor the search type that works better for your query
- Try each search type separately to understand which is contributing what results