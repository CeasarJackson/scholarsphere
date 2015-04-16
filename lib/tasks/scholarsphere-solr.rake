namespace :scholarsphere do

  namespace :solr do

    desc "Index a single object in solr specified by PID="
    task index: :environment do
      raise "Must specify a pid.  Ex:  PID='changeme:12" unless ENV['PID']
      initialize_rubydora_connection
      ActiveFedora::Base.find(ENV['PID']).update_index
    end

    desc "Compares number of objects in Solr with those in Fedora"
    task compare: :environment do
      q = Blacklight.solr.get "select", {q: "has_model_ssim:'info:fedora*'" }
      solr = q["response"]["numFound"]
      initialize_rubydora_connection
      fedora = ActiveFedora::Base.fedora_connection[0].connection.search(nil).count
      if fedora > solr
        raise "Fedora's #{fedora.to_s} objects exceeds Solr's #{solr}"
      else
        puts "Things appear to be OK"
      end
    end

  end

  # Loads Rubydora connection by using a fake, non-existent object
  def initialize_rubydora_connection
    ActiveFedora::Base.connection_for_pid("foo:1")
  end

end
