# frozen_string_literal: true

require_relative '../../../test_helper'

module Ragdoll
  module CLI
    class KeywordsTest < Minitest::Test
      def setup
        @output = StringIO.new
        @keywords = Keywords.new
        @keywords.instance_variable_set(:@output, @output)
        
        # Mock the StandaloneClient
        @mock_client = Minitest::Mock.new
        StandaloneClient.stub :new, @mock_client do
          # Tests will run inside this stub block
        end
      end

      def test_search_with_single_keyword
        mock_results = [
          {
            id: '1',
            title: 'Ruby Programming Guide',
            keywords: ['ruby', 'programming', 'tutorial']
          }
        ]
        
        @mock_client.expect(:search_by_keywords, mock_results, [['ruby'], { limit: 20 }])
        
        StandaloneClient.stub :new, @mock_client do
          @keywords.options = { format: 'plain', all: false, limit: 20 }
          
          out, _err = capture_io do
            @keywords.search('ruby')
          end
          
          assert_includes out, 'Searching documents by keywords: ruby'
          assert_includes out, 'Mode: ANY keywords (OR)'
          assert_includes out, 'Ruby Programming Guide'
        end
        
        @mock_client.verify
      end

      def test_search_with_multiple_keywords_all_mode
        mock_results = [
          {
            id: '1', 
            title: 'Ruby and Python Comparison',
            keywords: ['ruby', 'python', 'programming']
          }
        ]
        
        @mock_client.expect(:search_by_keywords_all, mock_results, [['ruby', 'python'], { limit: 20 }])
        
        StandaloneClient.stub :new, @mock_client do
          @keywords.options = { format: 'plain', all: true, limit: 20 }
          
          out, _err = capture_io do
            @keywords.search('ruby', 'python')
          end
          
          assert_includes out, 'Searching documents by keywords: ruby, python'
          assert_includes out, 'Mode: ALL keywords (AND)'
          assert_includes out, 'Ruby and Python Comparison'
        end
        
        @mock_client.verify
      end

      def test_search_with_no_results
        @mock_client.expect(:search_by_keywords, [], [['nonexistent'], { limit: 20 }])
        
        StandaloneClient.stub :new, @mock_client do
          @keywords.options = { format: 'table', all: false, limit: 20 }
          
          out, _err = capture_io do
            @keywords.search('nonexistent')
          end
          
          assert_includes out, 'No documents found with keywords: nonexistent'
          assert_includes out, 'Try different keywords'
          assert_includes out, 'ragdoll keywords list'
        end
        
        @mock_client.verify
      end

      def test_list_keywords
        mock_frequencies = {
          'ruby' => 5,
          'programming' => 3,
          'python' => 2
        }
        
        @mock_client.expect(:keyword_frequencies, mock_frequencies, [{ limit: 100, min_count: 1 }])
        
        StandaloneClient.stub :new, @mock_client do
          @keywords.options = { format: 'table', limit: 100, min_count: 1 }
          
          out, _err = capture_io do
            @keywords.list
          end
          
          assert_includes out, 'Keywords in system'
          assert_includes out, 'ruby'
          assert_includes out, 'programming'
          assert_includes out, 'Total keywords: 3'
        end
        
        @mock_client.verify
      end

      def test_list_keywords_json_format
        mock_frequencies = { 'ruby' => 5 }
        
        @mock_client.expect(:keyword_frequencies, mock_frequencies, [{ limit: 100, min_count: 1 }])
        
        StandaloneClient.stub :new, @mock_client do
          @keywords.options = { format: 'json', limit: 100, min_count: 1 }
          
          out, _err = capture_io do
            @keywords.list
          end
          
          assert_includes out, '"ruby"'
          assert_includes out, '5'
        end
        
        @mock_client.verify
      end

      def test_add_keywords_to_document
        mock_result = {
          success: true,
          keywords: ['ruby', 'programming', 'web']
        }
        
        @mock_client.expect(:add_keywords_to_document, mock_result, ['123', ['web']])
        
        StandaloneClient.stub :new, @mock_client do
          out, _err = capture_io do
            @keywords.add('123', 'web')
          end
          
          assert_includes out, '✓ Added keywords to document 123: web'
          assert_includes out, 'Document now has keywords: ruby, programming, web'
        end
        
        @mock_client.verify
      end

      def test_add_keywords_failure
        mock_result = {
          success: false,
          message: 'Document not found'
        }
        
        @mock_client.expect(:add_keywords_to_document, mock_result, ['999', ['keyword']])
        
        StandaloneClient.stub :new, @mock_client do
          assert_raises SystemExit do
            capture_io do
              @keywords.add('999', 'keyword')
            end
          end
        end
        
        @mock_client.verify
      end

      def test_remove_keywords_from_document
        mock_result = {
          success: true,
          keywords: ['ruby', 'programming']
        }
        
        @mock_client.expect(:remove_keywords_from_document, mock_result, ['123', ['web']])
        
        StandaloneClient.stub :new, @mock_client do
          out, _err = capture_io do
            @keywords.remove('123', 'web')
          end
          
          assert_includes out, '✓ Removed keywords from document 123: web'
          assert_includes out, 'Document now has keywords: ruby, programming'
        end
        
        @mock_client.verify
      end

      def test_set_document_keywords
        mock_result = {
          success: true,
          keywords: ['new', 'keywords']
        }
        
        @mock_client.expect(:set_document_keywords, mock_result, ['123', ['new', 'keywords']])
        
        StandaloneClient.stub :new, @mock_client do
          out, _err = capture_io do
            @keywords.set('123', 'new', 'keywords')
          end
          
          assert_includes out, '✓ Set keywords for document 123: new, keywords'
        end
        
        @mock_client.verify
      end

      def test_show_document_keywords
        mock_document = {
          id: '123',
          title: 'Test Document',
          keywords: ['ruby', 'test']
        }
        
        @mock_client.expect(:get_document, mock_document, ['123'])
        
        StandaloneClient.stub :new, @mock_client do
          out, _err = capture_io do
            @keywords.show('123')
          end
          
          assert_includes out, 'Keywords for document 123'
          assert_includes out, 'Title: Test Document'
          assert_includes out, 'Keywords: ruby, test'
        end
        
        @mock_client.verify
      end

      def test_show_document_no_keywords
        mock_document = {
          id: '123',
          title: 'Test Document',
          keywords: []
        }
        
        @mock_client.expect(:get_document, mock_document, ['123'])
        
        StandaloneClient.stub :new, @mock_client do
          out, _err = capture_io do
            @keywords.show('123')
          end
          
          assert_includes out, 'Keywords: (none)'
          assert_includes out, 'ragdoll keywords add 123'
        end
        
        @mock_client.verify
      end

      def test_keyword_stats
        mock_stats = {
          total_keywords: 10,
          documents_with_keywords: 5,
          avg_keywords_per_document: 2.5,
          top_keywords: [['ruby', 3], ['python', 2]],
          singleton_keywords: 4
        }
        
        @mock_client.expect(:keyword_statistics, mock_stats)
        
        StandaloneClient.stub :new, @mock_client do
          out, _err = capture_io do
            @keywords.stats
          end
          
          assert_includes out, 'Total unique keywords: 10'
          assert_includes out, 'Total documents with keywords: 5'
          assert_includes out, 'Average keywords per document: 2.5'
          assert_includes out, '1. ruby (3 documents)'
          assert_includes out, 'Least used keywords: 4'
        end
        
        @mock_client.verify
      end

      def test_search_no_keywords_provided
        assert_raises SystemExit do
          capture_io do
            @keywords.search
          end
        end
      end

      def test_add_no_keywords_provided
        assert_raises SystemExit do
          capture_io do
            @keywords.add('123')
          end
        end
      end

      def test_remove_no_keywords_provided
        assert_raises SystemExit do
          capture_io do
            @keywords.remove('123')
          end
        end
      end

      def test_set_no_keywords_provided
        assert_raises SystemExit do
          capture_io do
            @keywords.set('123')
          end
        end
      end

      def test_find_is_alias_for_search
        mock_results = [{ id: '1', title: 'Test', keywords: ['test'] }]
        @mock_client.expect(:search_by_keywords, mock_results, [['test'], { limit: 20 }])
        
        StandaloneClient.stub :new, @mock_client do
          @keywords.options = { format: 'table', all: false, limit: 20 }
          
          out, _err = capture_io do
            @keywords.find('test')
          end
          
          assert_includes out, 'Searching documents by keywords: test'
        end
        
        @mock_client.verify
      end

      private

      def capture_io
        original_stdout = $stdout
        original_stderr = $stderr
        stdout = StringIO.new
        stderr = StringIO.new
        $stdout = stdout
        $stderr = stderr
        
        begin
          yield
        ensure
          $stdout = original_stdout
          $stderr = original_stderr
        end
        
        [stdout.string, stderr.string]
      end
    end
  end
end