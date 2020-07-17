puts <<-MSG

We fix the previous example by using Honeycomb.add_field_to_trace instead. This
causes the whole trace to be dropped (the URL won't work).

MSG

Honeycomb.start_span(name: 'root') do
  puts trace_url
  puts

  Honeycomb.add_field_to_trace('drop', true) # <<<
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
