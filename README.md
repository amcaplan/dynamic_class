[![Gem Version](https://badge.fury.io/rb/dynamic_class.svg)](https://badge.fury.io/rb/dynamic_class)
[![Build Status](https://travis-ci.org/amcaplan/dynamic_class.svg?branch=master)](https://travis-ci.org/amcaplan/dynamic_class)
[![Code Climate](https://codeclimate.com/github/amcaplan/dynamic_class.png)](https://codeclimate.com/github/amcaplan/dynamic_class)

# DynamicClass

Many developers use `OpenStruct` as a convenient way of consuming APIs through
a nifty data object. But the performance penalty is pretty awful.

`DynamicClass` offers a better solution, optimizing for the case where you
need to create objects with the same set of properties every time, but you
can't define the needed keys until runtime. `DynamicClass` works by defining
instance methods on the class every time it encounters a new propery.

Let's see it in action:

``` ruby
Animal = DynamicClass.new do
  def speak
    "The #{type} makes a #{sound} sound!"
  end
end

dog = Animal.new(type: 'dog', sound: 'woof')
# => #<Animal:0x007fdb2b818ba8 @type="dog", @sound="woof">
dog.speak
# => The dog makes a woof sound!
dog.ears = 'droopy'
dog[:nose] = ['cold', 'wet']
dog['tail'] = 'waggable'
dog
# => #<Animal:0x007fc26b1841d0 @type="dog", @sound="woof", @ears="droopy", @nose=["cold", "wet"], @tail="waggable">

cat = Animal.new
# => #<Animal:0x007fdb2b83b180>
cat.to_h
# => {:type=>nil, :sound=>nil, :ears=>nil, :nose=>nil, :tail=>nil}
# The class has been changed by the dog!
```

Because methods are defined on the class (unlike `OpenStruct` which defines
methods on the object's singleton class), there is no need to define a method
more than once. This means that, past the first time a property is added,
the cost of setting a property drops.

The results are pretty astounding. Here are the results of the benchmark in
`bin/benchmark.rb` (including a few other `OpenStruct`-like solutions for
comparison), run on Ruby 2.2.4:

```
Initialization benchmark

Calculating -------------------------------------
          OpenStruct    14.668k i/100ms
PersistentOpenStruct    50.880k i/100ms
      OpenFastStruct    49.682k i/100ms
        DynamicClass    60.946k i/100ms
        RegularClass   107.521k i/100ms
-------------------------------------------------
          OpenStruct    165.010k (± 6.0%) i/s -    836.076k
PersistentOpenStruct    793.144k (± 5.4%) i/s -      3.969M
      OpenFastStruct    850.827k (± 5.0%) i/s -      4.273M
        DynamicClass      1.026M (± 4.0%) i/s -      5.180M
        RegularClass      3.451M (± 3.7%) i/s -     17.311M

Comparison:
        RegularClass:  3451422.2 i/s
        DynamicClass:  1026234.0 i/s - 3.36x slower
      OpenFastStruct:   850827.2 i/s - 4.06x slower
PersistentOpenStruct:   793144.4 i/s - 4.35x slower
          OpenStruct:   165009.7 i/s - 20.92x slower



Assignment Benchmark

Calculating -------------------------------------
          OpenStruct   112.139k i/100ms
PersistentOpenStruct   113.798k i/100ms
      OpenFastStruct    62.780k i/100ms
        DynamicClass   140.472k i/100ms
        RegularClass   141.757k i/100ms
-------------------------------------------------
          OpenStruct      3.773M (± 5.8%) i/s -     18.839M
PersistentOpenStruct      3.737M (± 6.8%) i/s -     18.663M
      OpenFastStruct      1.086M (± 4.8%) i/s -      5.462M
        DynamicClass      9.237M (± 5.8%) i/s -     46.075M
        RegularClass      9.017M (± 7.6%) i/s -     44.795M

Comparison:
        DynamicClass:  9236626.8 i/s
        RegularClass:  9017300.5 i/s - 1.02x slower
          OpenStruct:  3773095.2 i/s - 2.45x slower
PersistentOpenStruct:  3737490.7 i/s - 2.47x slower
      OpenFastStruct:  1085576.3 i/s - 8.51x slower



Access Benchmark

Calculating -------------------------------------
          OpenStruct   126.018k i/100ms
PersistentOpenStruct   123.179k i/100ms
      OpenFastStruct   113.118k i/100ms
        DynamicClass   139.960k i/100ms
        RegularClass   142.888k i/100ms
-------------------------------------------------
          OpenStruct      5.409M (± 5.3%) i/s -     26.968M
PersistentOpenStruct      5.341M (± 6.3%) i/s -     26.607M
      OpenFastStruct      4.094M (± 5.5%) i/s -     20.474M
        DynamicClass      9.623M (± 6.1%) i/s -     48.006M
        RegularClass      9.655M (± 5.9%) i/s -     48.153M

Comparison:
        RegularClass:  9655298.6 i/s
        DynamicClass:  9623042.4 i/s - 1.00x slower
          OpenStruct:  5409401.0 i/s - 1.78x slower
PersistentOpenStruct:  5341124.3 i/s - 1.81x slower
      OpenFastStruct:  4094344.3 i/s - 2.36x slower



All-Together Benchmark

Calculating -------------------------------------
          OpenStruct    14.450k i/100ms
PersistentOpenStruct    46.072k i/100ms
      OpenFastStruct    34.287k i/100ms
        DynamicClass    58.110k i/100ms
        RegularClass   107.647k i/100ms
-------------------------------------------------
          OpenStruct    161.775k (± 5.7%) i/s -    809.200k
PersistentOpenStruct    625.010k (± 5.7%) i/s -      3.133M
      OpenFastStruct    446.903k (± 4.8%) i/s -      2.263M
        DynamicClass    995.236k (± 5.0%) i/s -      4.997M
        RegularClass      3.102M (± 5.7%) i/s -     15.501M

Comparison:
        RegularClass:  3102088.4 i/s
        DynamicClass:   995235.5 i/s - 3.12x slower
PersistentOpenStruct:   625010.1 i/s - 4.96x slower
      OpenFastStruct:   446902.6 i/s - 6.94x slower
          OpenStruct:   161775.4 i/s - 19.18x slower
```

`DynamicClass` is still behind plain old Ruby classes, but it's the best out of
the pack when it comes to `OpenStruct` and friends.

## WARNING!

This class should only be used to consume trusted APIs, or for similar purposes.
It should never be used to take in user input. This will open you up to a memory
leak DoS attack, since every new key becomes a new method defined on the class,
and is never erased.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamic_class'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynamic_class

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can run the benchmark using `rake benchmark`.
You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

For functionality changes or bug fixes, please include tests. For performance
enhancements, please run the benchmarks and include results in your pull
request.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

