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

### [Without sampling](/examples/without_sampling.rb)

### [Head-based without propagation](/examples/head_based_without_propagation.rb)

### [Head-based with propagation](/examples/head_based_with_propagation.rb)

### [Tail-based before anything has been sent](/examples/tail_based_before_anything_has_been_sent.rb)

### [Tail-based after something has been sent](/examples/tail_based_after_something_has_been_sent.rb)

### [Nondeterministic sampling](/examples/nondeterministic_sampling.rb)

### [Deterministic sampling](/examples/deterministic_sampling.rb)
