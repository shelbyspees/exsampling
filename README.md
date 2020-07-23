# ExSampling

Some example code demonstrating trace-aware sampling strategies and common mistakes.

## Try it out yourself

Requirements:
* Ruby >= 2.3
* Bundler >= 1.13
* Your Honeycomb API key
* The name of your Honeycomb team (as it appears in URLs)

Pass your Honeycomb information in via environment variables and run the script to see the examples execute in realtime.

```console
$ HONEYCOMB_WRITE_KEY=<key> HONEYCOMB_TEAM=<team> ruby exsampling.rb
```

## Discussion

### Without sampling
[/examples/without_sampling.rb](/examples/without_sampling.rb)

This is our baseline, the overall trace we're attempting different sampling approaches on.

![original trace without sampling. there's a root span with two children. child 1 has a grandchild span.](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/yAuYwWGj/without_sampling.png)

### Head-based without propagation
[/examples/head_based_without_propagation.rb](/examples/head_based_without_propagation.rb)

In this example, we're attempting to drop the entire trace, but we're doing it using a field that's only set on the root span. So, we end up only dropping that root span, and all its children are still sent to Honeycomb.

![the same trace, but missing the root span](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/YEup7KGR/head_based_without_propagation.png)

### Head-based with propagation
[/examples/head_based_with_propagation.rb](/examples/head_based_with_propagation.rb)

This time we set a trace-level field at the head, and all the spans in the trace were successfully dropped.

![error message reading: We were unable to find any spans for this trace. Check if the trace ID or start and end timestamps are incorrect.](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/geuw5ZYd/missing_trace.png)

### Tail-based before anything has been sent
[/examples/tail_based_before_anything_has_been_sent.rb](/examples/tail_based_before_anything_has_been_sent.rb)

This time we got lucky. We managed to set the trace-level field to drop this trace before any of the early spans completed and got sent to Honeycomb.

![error message reading: We were unable to find any spans for this trace. Check if the trace ID or start and end timestamps are incorrect.](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/geuw5ZYd/missing_trace.png)

### Tail-based after something has been sent
[/examples/tail_based_after_something_has_been_sent.rb](/examples/tail_based_after_something_has_been_sent.rb)

This time, we're attempting tail-based sampling, but the `child 1` and `grandchild` spans completed and got sent to Honeycomb before the trace-level field got set during `child 2`.

![trace missing the root span as well as child 2. child 1 and grandchild are visible](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/mXuA0jYK/tail_based_some_sent.png?v=f341c8df0e25fe8436ba1c8c444ab5bd)

### Nondeterministic sampling
[/examples/nondeterministic_sampling.rb](/examples/nondeterministic_sampling.rb)

Randomly dropping half your events. Remember, 1 span == 1 event in Honeycomb. If you're dropping at the event level, you'll probably end up with orphaned child spans like this.

Note that `child 2` shows up in the wrong spot. The code didn't change--Honeycomb just doesn't know how to recombine the trace with so many missing spans, so it takes a guess at how to render the parent/child relationships.

![trace with missing root and some missing children. two leaf nodes appear: child 2 and grandchild](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/7KumYvrW/nondeterministic.png)

### Deterministic sampling 
[/examples/deterministic_sampling.rb](/examples/deterministic_sampling.rb)

This example extends the [Ruby Beeline's](https://docs.honeycomb.io/getting-data-in/ruby/beeline/) `DeterministicSampler` module so that we can lean on the Beeline's implementation of `should_sample`. The `should_sample` method takes in a rate and a value and returns a boolean, with consistent inputs leading to consistent return values.

This consistency is what allows us to do trace-aware sampling. By passing in the `trace.trace_id`, we get a consistent result for all the spans within the same trace.

Either we see the trace in full:

![trace with all spans included. there's a root span with two children. child 1 has a grandchild span.](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/yAuYwWGj/without_sampling.png)

Or our `sample_hook` will drop the trace in full:

![error message reading: We were unable to find any spans for this trace. Check if the trace ID or start and end timestamps are incorrect.](https://p-81fa8j.b1.n0.cdn.getcloudapp.com/items/geuw5ZYd/missing_trace.png)

