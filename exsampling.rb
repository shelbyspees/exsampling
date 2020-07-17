require 'bundler/inline'
gemfile { gem 'honeycomb-beeline', source: 'https://rubygems.org' }

### Configuration ##############################################################
#
# We look at the event for the `app.drop` field. If true, we drop the event. If
# false, we keep the event. We'll then look at how adding the `app.drop` field
# in different ways to different spots affects the overall trace.
#
################################################################################

Honeycomb.configure do |config|
  config.write_key = ENV['HONEYCOMB_WRITE_KEY']
  config.dataset = 'exsampling'

  config.sample_hook do |fields|
    if fields['app.drop']
      [false, 0]
    else
      [true, 1]
    end
  end
end

### Example 1 ##################################################################
#
# No one sets the `app.drop` field, so the whole trace is intact.
#
################################################################################

Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 1)
  Honeycomb.add_field('position', 'head')

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
  end
end

### Example 2 ##################################################################
#
# The root span sets the `app.drop` field in the head position, but not in such
# a way that the decision gets propagated to any children. So, only the root
# span is dropped, leaving the remaining children orphaned.
#
################################################################################

Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 2)
  Honeycomb.add_field('position', 'head')
  Honeycomb.add_field('drop', true) # only added to the current span

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
  end
end

### Example 3 ##################################################################
#
# We set a trace-level `app.drop` field which the children (if they haven't
# been sent yet) will inherit. We do this early enough (i.e., in the head
# position) that the whole trace is successfully dropped.
#
################################################################################

Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 3)
  Honeycomb.add_field('position', 'head')
  Honeycomb.add_field_to_trace('drop', true) # added to the whole trace

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
  end
end

### Example 4 ##################################################################
#
# We set a trace-level `app.drop` field from one of the children (i.e., in the
# tail position), and it just so happens to be before any events have been sent
# yet. So the whole trace is still successfully dropped, although it's probably
# a happy mistake.
#
################################################################################

Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 4)
  Honeycomb.add_field('position', 'head')

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
      Honeycomb.add_field_to_trace('drop', true) # nothing has been sent yet
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
  end
end

### Example 5 ##################################################################
#
# We set a span-level `app.drop` field from the tail position, but only after
# some upstream events have already been sent. We only lose the one span -
# which, to be fair, might be on purpose.
#
################################################################################

Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 5)
  Honeycomb.add_field('position', 'head')

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
    Honeycomb.add_field('drop', true) # only applies to the current span
  end
end

### Example 6 ##################################################################
#
# We set a trace-level `app.drop` field from the tail position, but only after
# some upstream events have already been sent. The only effect it has is on the
# current span and any other unsent events - including the root span.
#
################################################################################

Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 6)
  Honeycomb.add_field('position', 'head')

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
    Honeycomb.add_field_to_trace('drop', true) # other events have been sent
  end
end

### Example 7 ##################################################################
#
# You might *think* we would do percentage-based sampling by simply calling
# rand(), but that drops events randomly throughout a trace, leaving orphans.
#
################################################################################

Honeycomb.configure do |config|
  config.write_key = ENV['HONEYCOMB_WRITE_KEY']
  config.dataset = 'exsampling'

  config.sample_hook do |fields|
    [rand < 0.5, 2] # try to keep only 50% of *traces*...
  end
end

# ... but we're actually keeping 50% of *events*, leading to random orphans

srand(3) # for consistent results in the example

Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 7)
  Honeycomb.add_field('position', 'head')

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
  end
end
