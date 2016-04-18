#! /bin/bash
# keep a running tally of tests that we know are working so we can re-run them
bundle exec rspec\
  spec/models\
  spec/controllers\
  spec/jobs\
  spec/services\
  spec/presenters/collection_presenter_spec.rb\
  spec/presenters/file_set_presenter_spec.rb
  