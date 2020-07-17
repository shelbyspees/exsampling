puts <<-MSG

Without sampling, the trace looks like

  root
  ├── child 1
  │   └── grandchild
  └── child 2

Notice the order that events are processed. As each span ends, it fires an
event that gets put through the sampling hook to determine whether we send the
event or drop it.

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
    sleep 1
  end
end
