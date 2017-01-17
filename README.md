[![Build Status](http://img.shields.io/travis/theodi/octopub.svg)](https://travis-ci.org/theodi/octopub)
[![Dependency Status](http://img.shields.io/gemnasium/theodi/octopub.svg)](https://gemnasium.com/theodi/octopub)
[![Coverage Status](http://img.shields.io/coveralls/theodi/octopub.svg)](https://coveralls.io/r/theodi/octopub)
[![Code Climate](http://img.shields.io/codeclimate/github/theodi/octopub.svg)](https://codeclimate.com/github/theodi/octopub)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://theodi.mit-license.org)
[![Dependency Status](https://dependencyci.com/github/theodi/octopub/badge)](https://dependencyci.com/github/theodi/octopub)
[![Badges](http://img.shields.io/:badges-7/7-ff6799.svg)](https://github.com/badges/badgerbadgerbadger)

# Octopub

A Rails app that provides a simple and frictionless way for users to publish data on Github.

More information is in the [announcement blog post](http://theodi.org/blog/removing-barriers-to-publishing-open-data).

Live instance is running at [http://octopub.io/](http://octopub.io/)

## Development

Checkout the repository and run ```bundle``` in the checked out directory.
The application uses sidekiq for managing the background proccessing of data uploads. To use this functionality, install ```redis``` either by following the [instructions](https://redis.io/topics/quickstart) or if on macOS and using homebrew, run ```brew install redis``` and start a redis instance running with ```redis-server```.

## Tests

Octopub uses the ```rspec``` test framework and the test suite can be run with the usual ```bundle exec rspec```

## Deployment

A commit to master will trigger a TravisCI run, which, if successful, will automatically deploy to Heroku.