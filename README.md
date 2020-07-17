# ExSampling

The root span of the trace is considered the `head`. All children of the root span in the trace can be considered a `tail`. We use the terms "head" and "tail" because of head-based sampling and tail-based sampling.

## Configuration

For these examples, we've set up the `sample_hook` to drop any event (span) that contains the `app.drop` field.

```ruby
Honeycomb.configure do |config|
  # ...
  config.sample_hook do |fields|
    if fields['app.drop']
      [false, 0]
    else
      [true, 1]
    end
  end
end
```

## Example 1: no sampling

For this toy example, we're just generating spans: a root with two child spans, one of which gets a "grandchild" span.

```ruby
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
```

Here's what the trace looks like in full, without sampling:

![img_alt](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/o0uvd4Xo/exsampling_1.png)

## Example 2: missing root

This is head-based sampling done incorrectly, dropping the root span while failing to drop the children as well.

```ruby
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
```

![img_alt](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/GGuogX7A/exsampling_2.png)

## Example 3: head-based sampling successfully dropped all spans within trace

This is head-based sampling done right.
The decision is made at the head (root span) of the trace, and that decision is propogated down throughout the tail (child spans) via the trace-level field set early.
This is the strategy to use if you want to downsample at the request level.

```ruby
 Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 3)
  Honeycomb.add_field('position', 'head')
  Honeycomb.add_field_to_trace('drop', true)  # added to the whole trace

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
```

(no image because we dropped the entire trace)

## Example 4: tail-based sampling, dropped all spans within trace by coincidence

In this example we're also setting a trace-level field, but in this case it's being set late, in a child span.
We got lucky this time that the trace-level field got set before any events were sent.
In a longer trace where earlier spans are sent before the decision to drop gets made, you will likely end up with orphaned child spans. (See example 6.)

```ruby
Honeycomb.start_span(name: 'root') do
  Honeycomb.add_field_to_trace('example', 4)
  Honeycomb.add_field('position', 'head')

  Honeycomb.start_span(name: 'child 1') do
    Honeycomb.add_field('position', 'tail')

    Honeycomb.start_span(name: 'grandchild') do
      Honeycomb.add_field('position', 'tail')
      Honeycomb.add_field_to_trace('drop', true)  # nothing has been sent yet
    end
  end

  Honeycomb.start_span(name: 'child 2') do
    Honeycomb.add_field('position', 'tail')
  end
end
```

(no image because we dropped the entire trace)

## Example 5: tail-based: dropped child

This is a valid strategy if you want to drop individual spans that are especially noisy and don't provide a lot of value.

```ruby
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
    Honeycomb.add_field('drop', true)  # only applies to the current span
  end
end
```

Note that `child 2` has been dropped:

![img_alt](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/geuwGkB4/exsampling_5.png)

## Example 6: missing root, dropped child

This is the failed version of example 4.
We set the trace-level field too late, so early spans in the trace have already been sent. 
Note the timing:

- trace-level field is added to `child 2`
- `child 2` finishes
- trace-level field is added to `root`
- `root` finishes

```ruby
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
```

![img_alt](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/04uYjoRD/exsampling_6.png)

## Example 7: event-level sampling leads to random orphans

This is what happens when you don't use trace-aware sampling.
Here we try to do percentage-based sampling by calling `rand()` in the `sample_hook`:

```ruby
Honeycomb.configure do |config|
  # ...
  config.sample_hook do |fields|
    [rand < 0.5, 2]  # try to keep only 50% of *traces*
  end
end
```

The rest of the code is a copy of example 1:

```ruby
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
```

Since the `sample_hook` isn't trace-aware, we're actually keeping 50% of *events*, leading to random orphans:

![img_alt](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/Wnubv18d/exsampling_7.png)
