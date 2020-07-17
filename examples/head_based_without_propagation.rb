puts <<-MSG

When making the decision to drop a trace, you want the decision to propagate to
all the events in the trace. The surefire way to do this is to make the
decision from the root span - the *head* of the trace.

For our toy sampler, we use the `app.drop` field. In this example, we use
Honeycomb.add_field from the root span, which does not propagate across the
children. So, we only drop the root event, leaving orphaned children.

  (missing)
  ├── child 1
  │   └── grandchild
  └── child 2

MSG

Honeycomb.start_span(name: 'root') do
  puts trace_url
  puts

  Honeycomb.add_field('drop', true) # <<<
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
