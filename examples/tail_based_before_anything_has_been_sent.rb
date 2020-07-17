puts <<-MSG

We can try to make the decision later on in one of the children - in a *tail*
position. If we do this before any events have actually been sent, we'll still
successfully drop the whole trace (the URL won't work).

MSG

Honeycomb.start_span(name: 'root') do
  puts trace_url
  puts

  sleep 1

  Honeycomb.start_span(name: 'child 1') do
    sleep 1

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field_to_trace('drop', true) # <<<
      sleep 1
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    sleep 1
  end
end
