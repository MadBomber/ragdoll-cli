#!/usr/bin/env ruby
# frozen_string_literal: true

require "debug_me"
include DebugMe

$DEBUG_ME = true

# Standalone example for generating image descriptions via RubyLLM
require_relative "../lib/ragdoll-core"

RubyLLM.configure do |config|
  config.openai_api_key         = ENV.fetch("OPENAI_API_KEY", nil)
  config.openai_organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", nil)
  config.openai_project_id      = ENV.fetch("OPENAI_PROJECT_ID", nil)
  config.anthropic_api_key  = ENV.fetch("ANTHROPIC_API_KEY", nil)
  config.gemini_api_key     = ENV.fetch("GEMINI_API_KEY", nil)
  config.deepseek_api_key   = ENV.fetch("DEEPSEEK_API_KEY", nil)
  config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)
  config.bedrock_api_key       = ENV.fetch("BEDROCK_ACCESS_KEY_ID", nil)
  config.bedrock_secret_key    = ENV.fetch("BEDROCK_SECRET_ACCESS_KEY", nil)
  config.bedrock_region        = ENV.fetch("BEDROCK_REGION", nil)
  config.bedrock_session_token = ENV.fetch("BEDROCK_SESSION_TOKEN", nil)

  config.ollama_api_base = ENV.fetch("OLLAMA_API_BASE", nil)
  #
  # --- Custom OpenAI Endpoint ---
  # Use this for Azure OpenAI, proxies, or self-hosted models via OpenAI-compatible APIs.
  config.openai_api_base = ENV.fetch("OPENAI_API_BASE", nil) # e.g., "https://your-azure.openai.azure.com"
  #
  # --- Default Models ---
  # Used by RubyLLM.chat, RubyLLM.embed, RubyLLM.paint if no model is specified.
  # config.default_model            = 'gpt-4.1-nano'            # Default: 'gpt-4.1-nano'
  # config.default_embedding_model  = 'text-embedding-3-small'  # Default: 'text-embedding-3-small'
  # config.default_image_model      = 'dall-e-3'                # Default: 'dall-e-3'
  #
  # --- Connection Settings ---
  # config.request_timeout            = 120 # Request timeout in seconds (default: 120)
  # config.max_retries                = 3   # Max retries on transient network errors (default: 3)
  # config.retry_interval             = 0.1 # Initial delay in seconds (default: 0.1)
  # config.retry_backoff_factor       = 2   # Multiplier for subsequent retries (default: 2)
  # config.retry_interval_randomness  = 0.5 # Jitter factor (default: 0.5)
  #
  # --- Logging Settings ---
  # config.log_file   = '/logs/ruby_llm.log'
  config.log_level = :error # debug level can also be set to debug by setting RUBYLLM_DEBUG envar to true
end

if ARGV.empty?
  puts "Usage: #{$PROGRAM_NAME} IMAGE_PATH [PROMPT]"
  exit 1
end

image_path = ARGV.shift
unless File.exist?(image_path)
  warn "Error: File not found - #{image_path}"
  exit 1
end

service = Ragdoll::Core::Services::ImageDescriptionService.new
description = service.generate_description(image_path)
puts description
