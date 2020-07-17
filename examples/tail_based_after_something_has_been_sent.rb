puts <<-MSG

But if we make the decision in a tail position after events have already been
sent, we can't undo that. Thus, the beelines don't truly support tail-based
sampling out of the box: we'll only drop some of the events in the trace.

In this example, the trace will look like this:

  (missing)
  ├── child 1
  │   └── grandchild
  └── (missing)

MSG

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
    Honeycomb.add_field_to_trace('drop', true) # <<<
    sleep 1
  end
end
