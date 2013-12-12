namespace :scholarsphere do
  if Rails.env.test?
    # Don't load these files in production
    require 'rspec/core/rake_task'
    require 'cucumber/rake/task'
    desc "Execute Continuous Integration build (docs, tests with coverage)"
    task :ci => :environment do
      Rake::Task["jetty:config"].invoke
      Rake::Task["db:migrate"].invoke

      require 'jettywrapper'
      jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.join(Rails.root, 'jetty'))})

      error = nil
      error = Jettywrapper.wrap(jetty_params) do
        # do not run the js examples since selenium is not set up for jenkins
        ENV['SPEC_OPTS']="-t ~js"      
        Rake::Task['spec'].invoke
        Cucumber::Rake::Task.new(:features) do |t|
          t.cucumber_opts = "--format pretty"
        end
      end
      raise "test failures: #{error}" if error
    end
  end
end
