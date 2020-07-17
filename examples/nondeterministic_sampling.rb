puts <<-MSG

Suppose you only want to keep some percentage of your traces - say, half. You
might try to write a sample hook like this:

  config.sample_hook do |fields|
    [rand < 0.5, 2]
  end

However, since the sample hook works on the event level (NOT the trace level),
this winds up dropping events at random, potentially leading to random orphans.

MSG

Honeycomb.configure do |config|
  config.write_key = ENV['HONEYCOMB_WRITE_KEY']
  config.dataset = 'exsampling'

  config.sample_hook do |fields|
    if rand < 0.5
      puts "Drop event: #{JSON.pretty_generate(fields)}"
      [false, 2]
    else
      puts "Send event: #{JSON.pretty_generate(fields)}"
      [true, 2]
    end
  end
end

srand(6) # so the example has consistent results

Honeycomb.start_span(name: 'root') do
  puts trace_url
  puts

  sleep 1

  Honeycomb.start_span(name: 'child 1') do
    sleep 1

    Honeycomb.start_span(name: 'grandchild') do
      sleep 1
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    sleep 1
  end
end
