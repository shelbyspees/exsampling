require 'bundler/inline'
gemfile { gem 'honeycomb-beeline', source: 'https://rubygems.org' }

Honeycomb.configure do |config|
  config.write_key = ENV['HONEYCOMB_WRITE_KEY']
  config.dataset = 'exsampling'

  config.sample_hook do |fields|
    if fields['app.drop']
      puts "Drop event: #{JSON.pretty_generate(fields)}"
      puts
      [false, 0]
    else
      puts "Send event: #{JSON.pretty_generate(fields)}"
      puts
      [true, 1]
    end
  end
end

def trace_url
  'https://ui.honeycomb.io/novalogic/datasets/exsampling/trace' \
    "?trace_id=#{Honeycomb.current_trace&.id}" \
    "&trace_start_ts=#{Time.now.to_i - 60}" \
    "&trace_end_ts=#{Time.now.to_i + 60}"
end

require_relative 'examples/without_sampling'
require_relative 'examples/head_based_without_propagation'
require_relative 'examples/head_based_with_propagation'
require_relative 'examples/tail_based_before_anything_has_been_sent'
require_relative 'examples/tail_based_after_something_has_been_sent'
require_relative 'examples/nondeterministic_sampling'
require_relative 'examples/deterministic_sampling'
