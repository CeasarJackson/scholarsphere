class Collection < ActiveFedora::Base
  include Sufia::Collection

  before_save :update_permissions
  validates :title, presence: true

  has_metadata name: "properties", type: PropertiesDatastream

  def terms_for_display
    [:title, :creator, :description, :date_modified, :date_uploaded]
  end
  
  def terms_for_editing
    terms_for_display - [:date_modified, :date_uploaded]
  end
  
  # Test to see if the given field is required
  # @param [Symbol] key a field
  # @return [Boolean] is it required or not
  def required?(key)
    self.class.validators_on(key).any?{|v| v.kind_of? ActiveModel::Validations::PresenceValidator}
  end
  
  def to_param
    noid
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc[Solrizer.solr_name("noid", Sufia::GenericFile.noid_indexer)] = noid
    return solr_doc
  end

  def update_permissions
    self.visibility = "open"
  end
end
