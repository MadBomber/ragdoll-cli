# Database Schema

> **TODO:** This documentation is under development. Please check back later for complete content.

## Polymorphic Multi-Modal Database Design

TODO: Document the complete database schema for Ragdoll-Core, including:

- Full schema diagram with table relationships
- Polymorphic associations design
- Index strategy for performance
- Migration files and versioning

## Core Tables

TODO: Detail each database table:

### Documents Table (`ragdoll_documents`)
- Schema definition
- Column descriptions
- Relationships to content tables
- Dual metadata architecture

### Content Tables
- `ragdoll_text_contents`
- `ragdoll_image_contents` 
- `ragdoll_audio_contents`

### Embeddings Table (`ragdoll_embeddings`)
- Vector storage design
- Polymorphic relationships
- Usage tracking fields
- pgvector integration

## Database Adapters

TODO: Document supported database configurations:

- PostgreSQL with pgvector (production)
- SQLite (development/testing)
- Migration between adapters
- Performance comparisons

## Indexing Strategy

TODO: Document database indexes:

- Vector similarity indexes (IVFFlat)
- Full-text search indexes
- Metadata JSON indexes
- Performance optimization indexes

## Database Migrations

TODO: Document migration system:

- Auto-migration feature
- Manual migration process
- Schema versioning
- Backward compatibility

---

*This document is part of the Ragdoll-Core documentation suite. For immediate help, see the [Quick Start Guide](quick-start.md) or [API Reference](api-client.md).*