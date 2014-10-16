class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include Hydra::Collections::Collectible
  include Blacklight::SolrHelper

  #has_file_datastream "full_text", versionable: false

  has_attributes :proxy_depositor, :on_behalf_of, datastream: :properties, multiple: false

  after_create :create_transfer_request

  def create_transfer_request
    Sufia.queue.push(ContentDepositorChangeEventJob.new(pid, on_behalf_of)) if on_behalf_of.present?
  end

  def request_transfer_to(target)
    raise ArgumentError, "Must provide a target" unless target
    deposit_user = User.find_by_user_key(depositor)
    ProxyDepositRequest.create!(pid: pid, receiving_user: target, sending_user: deposit_user)
  end

  # TODO: This differs slightly from Sufia's #characterize. Why? Still relevant?
  #def characterize
  #  metadata = self.content.extract_metadata
  #  self.characterization.ng_xml = metadata unless metadata.blank?
  #  self.append_metadata
  #  self.filename = self.label
  #  extract_content
  #  save unless self.new_record?
  #end
  #
  #def create_pdf_thumbnail
  #   retryCnt = 0
  #   stat = false;
  #   for retryCnt in 1..3
  #     begin
  #       pdf = Magick::ImageList.new
  #       pdf.from_blob(content.content)
  #       first = pdf.to_a[0]
  #       first.format = "PNG"
  #       scale = 338.0/first.page.width
  #       scale = 0.40 if scale < 0.40
  #       thumb = first.scale scale
  #       thumb.crop!(0, 0, 338, 493)
  #       self.thumbnail.content = thumb.to_blob { self.format = "PNG" }
  #       stat = self.save
  #       break
  #     rescue => e
  #       Rails.logger.warn "Rescued an error #{e.inspect} retry count = #{retryCnt}"
  #       sleep 1
  #     end
  #   end
  #   return stat
  # end
  #
  #def create_video_thumbnail
  #  return unless Sufia.config.enable_ffmpeg
  #
  #  output_file = Dir::Tmpname.create(['sufia', ".png"], Sufia.config.temp_file_base){}
  #  content.to_tempfile do |f|
  #    # we could use something like this in order to find a frame in the middle.
  #    #ffprobe -show_files video.avi 2> /dev/null | grep duration | cut -d= -f2 53.399999
  #    command = "#{Sufia.config.ffmpeg_path} -i \"#{f.path}\" -loglevel quiet -vf \"scale=338:-1\"  -r  1  -t  1 -vframes 1 #{output_file}"
  #    system(command)
  #    raise "Unable to execute command \"#{command}\"" unless $?.success?
  #  end
  #
  #  self.thumbnail.content = File.open(output_file, 'rb').read
  #  self.thumbnail.mimeType = 'image/png'
  #end

  # Unstemmed, searchable, stored
  def self.noid_indexer
    @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
  end

  #def to_solr(solr_doc={}, opts={})
  #  super(solr_doc, opts)
  #  solr_doc[Solrizer.solr_name('label')] = self.label
  #  solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
  #  solr_doc[Solrizer.solr_name('file_format')] = file_format
  #  solr_doc[Solrizer.solr_name('file_format', :facetable)] = file_format
  #  solr_doc["all_text_timv"] = full_text.content
  #  solr_doc = index_collection_pids(solr_doc)
  #  return solr_doc
  #end

  def file_format
    return nil if self.mime_type.blank? and self.format_label.blank?
    return self.mime_type.split('/')[1]+ " ("+self.format_label.join(", ")+")" unless self.mime_type.blank? or self.format_label.blank?
    return self.mime_type.split('/')[1] unless self.mime_type.blank?
    return self.format_label
  end

  def export_as_endnote
    end_note_format = {
      '%T' => [:title, lambda { |x| x.first }],
      '%Q' => [:title, lambda { |x| x.to_ary.slice(1, -1) }],
      '%A' => [:creator],
      '%C' => [:publication_place],
      '%D' => [:date_created],
      '%8' => [:date_uploaded],
      '%E' => [:contributor],
      '%I' => [:publisher],
      '%J' => [:series_title],
      '%@' => [:isbn],
      '%U' => [:related_url],
      '%7' => [:edition_statement],
      '%R' => [:persistent_url],
      '%X' => [:description],
      '%G' => [:language],
      '%[' => [:date_modified],
      '%9' => [:resource_type],
      '%~' => ScholarSphere::Application::config.application_name,
      '%W' => 'Penn State University'
    }
    text = []
    text << "%0 GenericFile"
    end_note_format.each do |endnote_key, mapping|
      if mapping.is_a? String
        values = [mapping]
      else
        values = self.send(mapping[0]) if self.respond_to? mapping[0]
        values = mapping[1].call(values) if mapping.length == 2
        values = [values] unless values.is_a? Array
      end
      next if values.empty? or values.first.nil?
      spaced_values = values.join("; ")
      text << "#{endnote_key} #{spaced_values}"
    end
    return text.join("\n")
  end

  def registered?
    read_groups.include?('registered')
  end

  def public?
    read_groups.include?('public')
  end

  def characterize
    if !content.nil? && content.content.size > 2**30
      return false
    end
    super
  end


  # Get the files with a sibling relationship (belongs_to :batch)
  # The batch id is minted when visiting the upload screen and attached
  # to each file when it is done uploading.  The Batch object is not created
  # until all objects are done uploading and the user is redirected to
  # BatchController#edit.  Therefore, we must handle the case where
  # self.batch_id is set but self.batch returns nil.
  def related_files
    return [] if batch.nil?
    ids = batch.generic_file_ids.reject { |sibling| sibling == id }
    ids.map {|id| GenericFile.load_instance_from_solr id}
  end

  def audit(force = false)
    logs = []
    self.per_version do |ver|
      logs << audit_each(ver, force)
    end
    logs
  end

  def audit_each(version, force = false)
    latest_audit = logs(version.dsid).first
    unless force
      return latest_audit unless ::GenericFile.needs_audit?(version, latest_audit)
    end
    #  Resque.enqueue(AuditJob, version.pid, version.dsid, version.versionID)
    Sufia.queue.push(AuditJob.new(version.pid, version.dsid, version.versionID))

    # run the find just incase the job has finished already
    latest_audit = logs(version.dsid).first
    latest_audit = ChecksumAuditLog.new(pass: NO_RUNS, pid: version.pid, dsid: version.dsid, version: version.versionID) unless latest_audit
    latest_audit
  end

  def self.audit(version, force = false)
    self.find(version.pid).audit_each(version,force)
  end

end
