require 'action_view'
require 'rainbow'

include ActionView::Helpers::NumberHelper

namespace :scholarsphere do
  # adding a logger since it got removed from our gemset
  def logger
    Rails.logger
  end

  desc "Restore missing user accounts"
  task restore_users: :environment do
    # Query Solr for unique depositors
    terms_url = "#{ActiveFedora.solr_config[:url]}/terms?terms.fl=depositor_tesim&terms.sort=index&terms.limit=5000&wt=json&omitHeader=true"
    # Parse JSON response (looks like {"terms":{"depositor_tesim":["mjg36",3]}})
    terms_json = open(terms_url).read
    depositor_logins = begin
                         JSON.parse(terms_json)['terms']['depositor_tesim']
                       rescue
                         []
                       end
    # Filter out doc counts, and leave logins
    depositor_logins.select! { |item| item.is_a? String }
    # Check for depositor User accounts & restore/populate if missing
    depositor_logins.each { |l| User.create(login: l).populate_attributes if User.find_by_login(l).nil? }
    # Then iterate over other User accounts and populate their attributes just in case
    User.all.each do |u|
      # Skip user if already populated earlier
      next if depositor_logins.include? u.login
      u.populate_attributes
    end
  end

  desc "Report users quota in SS"
  task quota_report: :environment do
    caution_sz = 3_000_000_000   # 3GB
    warning_sz = 5_000_000_000   # 5GB
    problem_sz = 10_000_000_000  # 10GB
    # loop over users in active record
    users = {}
    User.all.each do |u|
      # for each user query get list of documents
      user_files = GenericFile.find(depositor: u.login)
      # sum the size of the users docs
      sz = 0
      user_files.each do |f|
        # puts number_to_human_size(f.file_size.first.to_i)
        sz += f.file_size.first.to_i
        # puts "#{sz}:#{f.file_size.first}"
      end
      uname = "#{u.login} #{u.name}"
      users = users.merge(uname => sz)
    end
    longest_key = users.keys.max { |a, b| a.length <=> b.length }
    printf "%-#{longest_key.length}s %s".background(:white).foreground(:black), "User", "Space Used"
    puts ""
    users.each_pair do |k, v|
      if v >= problem_sz
        printf "%-#{longest_key.length}s %s".background(:red).foreground(:white).blink, k, number_to_human_size(v)
      elsif v >= warning_sz
        printf "%-#{longest_key.length}s %s".background(:red).foreground(:white), k, number_to_human_size(v)
      elsif v >= caution_sz
        printf "%-#{longest_key.length}s %s".background(:yellow).foreground(:black), k, number_to_human_size(v)
      else
        printf "%-#{longest_key.length}s %s".background(:black).foreground(:white), k, number_to_human_size(v)
      end
      puts ""
    end
  end

  desc "(Re-)Generate the secret token"
  task generate_secret: :environment do
    File.open("#{Rails.root}/config/initializers/secret_token.rb", 'w') do |f|
      f.puts "#{Rails.application.class.parent_name}::Application.config.secret_key_base = '#{SecureRandom.hex(64)}'"
    end
  end

  desc "Characterize all files"
  task characterize: :environment do
    # grab the first increment of document ids from solr

    resp = ActiveFedora::SolrService.instance.conn.get "select",
                                                       params: { fl: ['id'], fq: "#{Solrizer.solr_name('has_model', :symbol)}:GenericFile" }
    puts resp
    # get the totalNumber and the size of the current response
    totalNum = resp["response"]["numFound"]
    idList = resp["response"]["docs"]
    page = 1

    # loop through each page appending the ids to the original list
    while idList.length < totalNum
      page += 1
      resp = ActiveFedora::SolrService.instance.conn.get "select",
                                                         params: { fl: ['id'], fq: "#{Solrizer.solr_name('has_model', :symbol)}:GenericFile",
                                                                   page: page }
      idList += resp["response"]["docs"]
      totalNum = resp["response"]["numFound"]
    end

    # for each document in the database call characterize
    idList.each { |o| Sufia.queue.push(CharacterizeJob.new o["id"]) }
  end

  desc "Re-solrize all objects"
  task resolrize: :environment do
    Sufia.queue.push(ResolrizeJob.new)
  end

  desc "Re-solrize top level objects"
  task resolrize_top: :environment do
    resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, ActiveFedora.fedora.host + ActiveFedora.fedora.base_path)
    # GET could be slow if it's a big resource, we're using HEAD to avoid this problem,
    # but this causes more requests to Fedora.
    return [] unless Ldp::Response.rdf_source?(resource.head)
    immediate_descendant_uris = resource.graph.query(predicate: ::RDF::Vocab::LDP.contains).map { |descendant| descendant.object.to_s }
    immediate_descendant_uris.each do |uri|
      id = ActiveFedora::Base.uri_to_id(uri)
      puts "Re-index everything ... #{id}"
      ActiveFedora::Base.find(id).update_index rescue logger.error "error processing #{id}"
    end
  end

  desc 'copy fits configuration files into the fits submodule'
  task :fits_conf do
    puts 'copying fits config files'
    out = `cp fits_conf/* fits/xml`
  end

  namespace :export do
    desc "Dump metadata as RDF/XML for e.g. Summon integration"
    task rdfxml: :environment do
      raise "rake scholarsphere:export:rdfxml output=FILE" unless ENV['output']
      export_file = ENV['output']
      triples = RDF::Repository.new
      rows = GenericFile.count
      GenericFile.find(:all).each do |gf|
        next unless gf.rightsMetadata.groups["public"] == "read" && gf.descMetadata.content
        RDF::Reader.for(:ntriples).new(gf.descMetadata.content) do |reader|
          reader.each_statement do |statement|
            triples << statement
          end
        end
      end
      unless triples.empty?
        RDF::Writer.for(:rdfxml).open(export_file) do |writer|
          writer << triples
        end
      end
    end
  end

  namespace :harvest do
    desc "Harvest LC subjects"
    task lc_subjects: :environment do |cmd, _args|
      vocabs = ["/tmp/subjects-skos.nt"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs)
    end

    desc "Harvest DBpedia titles"
    task dbpedia_titles: :environment do |cmd, _args|
      vocabs = ["/tmp/labels_en.nt"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs, predicate: RDF::RDFS.label)
    end

    desc "Harvest DBpedia categories"
    task dbpedia_categories: :environment do |cmd, _args|
      vocabs = ["/tmp/category_labels_en.nt"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs, predicate: RDF::RDFS.label)
    end

    desc "Harvest LC MARC geographic areas"
    task lc_geographic: :environment do |cmd, _args|
      vocabs = ["/tmp/vocabularygeographicAreas.nt"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs)
    end

    desc "Harvest Geonames cities"
    task geonames_cities: :environment do |cmd, _args|
      vocabs = ["/tmp/cities1000.txt"]
      LocalAuthority.harvest_tsv(cmd.to_s.split(":").last, vocabs, prefix: 'http://sws.geonames.org/')
    end

    desc "Harvest Lexvo languages"
    task lexvo_languages: :environment do |cmd, _args|
      vocabs = ["/tmp/lexvo_2012-03-04.rdf"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs,
                                 format: 'rdfxml',
                                 predicate: RDF::URI("http://www.w3.org/2008/05/skos#prefLabel"))
    end

    desc "Harvest LC genres"
    task lc_genres: :environment do |cmd, _args|
      vocabs = ["/tmp/authoritiesgenreForms.nt"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs)
    end

    desc "Harvest LC name authorities"
    task lc_names: :environment do |cmd, _args|
      vocabs = ["/tmp/authoritiesnames.nt.skos"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs)
    end

    desc "Harvest LC thesaurus of graphic materials"
    task lc_graphics: :environment do |cmd, _args|
      vocabs = ["/tmp/vocabularygraphicMaterials.nt"]
      LocalAuthority.harvest_rdf(cmd.to_s.split(":").last, vocabs)
    end
  end

  namespace "checksum" do
    desc "Run a checksum on all the GenericFiles"
    task "all"  => :environment do
      errors = []
      GenericFile.all.each do |gf|
        next unless gf.content.checksum.blank?
        gf.content.checksumType = "MD5"
        if gf.content.checksum == gf.original_checksum[0]
          gf.content.checksumType = "SHA-1"
          gf.save # to do update version committer to checksum
        else
          errors << gf
        end
      end
      errors.each { |gf| puts "Invalid Checksum: #{gf.pid} new: #{gf.content.checksum} original: #{gf.original_checksum[0]} " }
    end
  end

  desc "Convert Resource Type"
  task "master_thesis" => :environment do
    # def add_advanced_parse_q_to_solr(solr_parameters, req_params = params)
    #  solr_parameters[:fq]="{!raw f=resource_type_sim}Masters Thesis"
    # end

    resp = ActiveFedora::SolrService.instance.conn.get "select",
                                                       params: { fl: ['id'], q: "#{Solrizer.solr_name('resource_type')}:\"Masters Thesis\"",
                                                                 fq: "#{Solrizer.solr_name('has_model', :symbol)}:GenericFile" }
    docs = resp["response"]["docs"]
    docs.each do |doc|
      gf = GenericFile.find(doc["id"])
      puts "File Found #{gf.title} #{gf.resource_type}"
      resources = gf.resource_type
      gf.resource_type = resources.map { |type| type == "Masters Thesis" ? "Thesis" : type }
      puts "File Updated #{gf.title} #{gf.resource_type}"
      gf.save
    end
  end

  def solr_generic_files_only(solr_parameters, _user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrService.construct_query_for_rel(has_model: ::GenericFile.to_class_uri)
    ]
  end

  desc "Generate thumbnails for ALL documents"
  task "generate_thumbnails" => :environment do
    solr = ActiveFedora::SolrService.instance.conn.get "select",
                                                       params: { fl: ['id'], fq: "#{Solrizer.solr_name('has_model', :symbol)}:GenericFile" }
    total_docs = solr["response"]["numFound"]
    logger.info "Total documents to process: #{total_docs}"

    total_processed = errors = page = 0
    while total_processed < total_docs
      page += 1
      solr = ActiveFedora::SolrService.instance.conn.get "select",
                                                         params: { fl: ['id'], fq: "#{Solrizer.solr_name('has_model', :symbol)}:GenericFile",
                                                                   page: page }
      total_docs = solr["response"]["numFound"]
      docs = solr["response"]["docs"]
      docs.each do |doc|
        begin
          id = doc["id"]
          Sufia.queue.push(CreateDerivativesJob.new id)
        rescue Exception => e
          errors += 1
          logger.error "Error processing document: #{id}\r\n#{e.message}\r\n#{e.backtrace.inspect}"
        end
      end
      total_processed += docs.length
      logger.info "Total documents queued: #{total_processed}"
    end
    logger.error("Total errors: #{errors}") if errors > 0
  end

  # Start date must be in format 'yyyy/MM/dd'
  desc "Prints to stdout a list of failed jobs in resque"
  task "get_failed_jobs", [:start_date, :details] => :environment do |_cmd, args|
    details = (args[:details] == "true")
    start_date = args[:start_date] || Date.today.to_s.tr('-', '/')
    log = ""
    i = 0
    puts "Getting failed jobs from: #{start_date}"
    Resque::Failure.each do |i, job|
      i += 1
      job_failed_at = job["failed_at"]
      if job_failed_at >= start_date
        payload = job["payload"]
        job_args64 = payload["args"]
        job_args = Base64.decode64(job_args64[0])
        prefix_at = job_args.index("scholarsphere:")
        if prefix_at.nil?
          log += "Unexpected job arguments found: #{job_args}\r\n"
        else
          sufix_at = job_args.index(":", prefix_at + 14)
          pid = job_args[prefix_at, sufix_at - prefix_at - 1].chomp
          if details

            exception = job["exception"]
            error = job["error"]
            backtrace = job["backtrace"][0]
            log += "PID: #{pid}\r\n"
            log += "Failed at: #{job_failed_at}\r\n"
            log += "Exception: #{exception} - #{error}\r\n"
            log += "Backtrace: #{backtrace}\r\n"
            begin
              gf = GenericFile.find(pid)
              log += "File name: #{gf[:filename]}\r\n"
              log += "Mime type: #{gf[:mime_type]}\r\n"
            rescue Exception => e
              log += "File name: (could not be determined)\r\n"
            end
            log += "---------------\r\n"
          else
            log += "#{pid}\r\n"
          end
        end
        puts i if (i % 100) == 0
      end
    end

    puts "Writting log..."
    File.write('find_failed_jobs.log', log)
    puts "Done."
  end

  desc "Create derivatives for the documents indicated in a file. Each line in the file must include a PID (e.g. scholarsphere:123xyz)"
  task "generate_thumbnail", [:file_name] => :environment do |_cmd, args|
    file_name = args[:file_name]
    abort "Must provide a file name to read the PIDs" if file_name.nil?
    puts "Processing file #{file_name}"
    File.readlines(file_name).each do |line|
      pid = line.chomp
      unless pid.empty?
        Sufia.queue.push(CreateDerivativesJob.new pid)
        puts "Queued derivatives for PID: #{pid}"
      end
    end
  end

  desc "Characterizes documents indicated in a file. Each line in the file must include a PID (e.g. scholarsphere:123xyz)"
  task "characterize_some", [:file_name] => :environment do |_cmd, args|
    file_name = args[:file_name]
    abort "Must provide a file name to read the PIDs" if file_name.nil?
    puts "Processing file #{file_name}"
    File.readlines(file_name).each do |line|
      pid = line.chomp
      unless pid.empty?
        Sufia.queue.push(CharacterizeJob.new pid)
        puts "Queued characterization for PID: #{pid}"
      end
    end
  end

  desc "Queues a job to (re)generate the sitemap.xml"
  task "sitemap_queue_generate" => :environment do
    Sufia.queue.push(SitemapRegenerateJob.new)
  end

  desc "list user's email"
  task "list_users" => :environment do
    users = User.all.map(&:email).reject(&:blank?)
    f = File.new("user_emails.txt", "w")
    f.write(users.join(", "))
    f.close
  end

  desc "generate and mail the stats report for yesterday"
  task "deliver_stats" => :environment do
    StatsMailer.stats_mail(1.day.ago.beginning_of_day, 1.day.ago.end_of_day).deliver
  end
  desc "generate and mail the stats report for the past week"
  task "deliver_weekly_stats" => :environment do
    StatsMailer.stats_mail(8.day.ago.beginning_of_day, 1.day.ago.end_of_day).deliver
  end

  desc "Mark a file as private"
  task "make_private", [:file_id] => :environment do |_cmd, args|
    file_id = args[:file_id]
    abort "Must provide a file id to mark as private" if file_id.nil?
    gf = GenericFile.find(file_id)
    gf.read_groups = []
    result = gf.save
    puts "File #{file_id} marked as private: #{result}"
  end
end
