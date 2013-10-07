# Template Profiler plugin for Movable Type

This plugin provides a simple way for anyone to audit a Movable Type template
to see why it is so darn slow.

It does so by profiling the evaluation of **individual template tags**
encountered during the course of a single-template build (i.e. either an index
template or a single archive file). That makes it easy to narrow down exactly
where the culprit is.

# Prerequisites

* Movable Type 5+
* [Config Assistant 2.5.0+](https://github.com/openmelody/mt-plugin-configassistant/releases)

* Support for Movable Type 4.x with
  [version 0.3](https://github.com/endevver/mt-plugin-profiler/releases)

# Profile Report

The performance statistics compiled for the final report include both aggregate
totals and single-instance averages. This enables you to identify both horribly
inefficient tags as well as those which are evaluated far too frequently
(indicating that caching might be helpful).

<div class="thumbnail"><a href="https://skitch.com/jayallen/r9655/profiler-plugin-tag-performance"><img src="https://img.skitch.com/20110518-e2g52pr1bg1i6bb27kg25c3i52.preview.jpg" alt="Profiler plugin - Tag performance" /></a></div>

The data contained in the report includes:

  * Name of the template tag
  * Number of times the tag was encountered
  * Aggregate processing time for the tag
  * Average processing time for a single evaluation of the tag
  * Number of database queries generated for the tag
  * Number of cache hits and misses for those queries

The report also provides nice javascript-based sorting capabilities to make it
easier to determine the outliers within given template.

# Known Issues

* Works only with Index Templates right now.

# Bugs, Feature requests and support ##

If you are having problems installing or using the plugin, please check out our
general knowledge base and help ticket system at
[help.endevver.com](http://help.endevver.com).

If you know that you've encountered a bug in the plugin or you have a request
for a feature you'd like to see, you can file a ticket in
[Github Issues](https://github.com/endevver/mt-plugin-profiler/issues).

# License

The plugin is licensed under the GPL v2.

# Copyright

* Six Apart, 2008
* Endevver LLC, 2009
