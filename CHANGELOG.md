# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.12] - 2025-09-23

### Changed
- **BREAKING**: Migrated from multi-modal to unified text-based RAG architecture
- Updated gemspec summary and description to reflect unified approach
- Deprecated `--content_type` option (now shows deprecation warning)
- Updated default embedding model to `text-embedding-3-large`
- Enhanced search modes documentation to explain unified text conversion
- Updated demo script to showcase cross-modal search capabilities
- Replaced content-type filtering examples with classification filtering

### Added
- Support for unified text-based content processing
- Cross-modal search capabilities (find images by description, audio by transcript)
- Deprecation warnings for obsolete multi-modal options
- Configuration options for unified content processing (`use_unified_content`)
- Enhanced documentation explaining text conversion process
- Support for `embedding_provider` configuration

### Documentation
- Updated README.md with unified text-based RAG explanation
- Converted HTML caution banner to GitHub-compliant callout syntax
- Updated ARCHITECTURE.md to describe unified text conversion pipeline
- Enhanced CLAUDE.md with unified configuration examples
- Updated SEARCH_MODES.md with comprehensive unified architecture explanation
- Updated demo script with unified approach examples

### Dependencies
- Updated ragdoll dependency to >= 0.1.12

## [0.1.11] - 2025-01-17

### Changed
- Updated dependencies in Gemfile.lock
- Refined document management commands
- Enhanced README documentation with expanded features and usage examples
- Improved standalone client with better error handling
- Enhanced CLI with additional document management capabilities
- Updated coss.toml configuration

### Added
- New document management commands and options
- Extended functionality for keyword and context management
- Improved command-line interface features

## [0.1.10] - Previous Release

### Added
- Enhanced context and prompt feedback mechanisms
- Similarity threshold option for search and context
- Demo script for improved readability and consistency

### Changed
- Updated Ragdoll gem to latest revision
- Refactored demo script
- Updated Rakefile and CLI for improved testing and keyword management

### Fixed
- Various dependency updates and improvements

## [0.1.9] - Previous Release

### Added
- Initial implementation of ragdoll-cli
- Core document management functionality
- Basic search and context features

### Changed
- Updated CI configuration
- Dependency updates

### Removed
- Obsolete CI configuration for Ruby
- Redundant GitHub workflows
