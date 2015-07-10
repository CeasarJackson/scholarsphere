# -*- encoding : utf-8 -*-
class SolrDocument
  # Add Blacklight behaviors to the SolrDocument
  include Blacklight::Solr::Document
  # Adds Sufia behaviors to the SolrDocument.
  include Sufia::SolrDocumentBehavior

  # Method to return the ActiveFedora model
  def hydra_model
    Array(self[Solrizer.solr_name('active_fedora_model', Solrizer::Descriptor.new(:string, :stored, :indexed))]).first
  end

  def collections
    return nil if self[Solrizer.solr_name(:collection)].blank?
    collectionsIn = Array(self[Solrizer.solr_name(:collection)])
    collections = []
    collectionsIn.each {|pid| collections << Collection.load_instance_from_solr(pid) rescue {} }
    return collections
  end

  def creator
    return nil if self[Solrizer.solr_name(:creator)].blank?
    "#{ ul_start_tags } #{ self[Solrizer.solr_name(:creator)].join(ul_join_tags) } #{ ul_end_tags }".html_safe
  end

  private

    def ul_start_tags
      "<ul class='creator_list'>#{person_separator}<li>"
    end

    def ul_join_tags
      "</li>#{person_separator}<li> "
    end

    def ul_end_tags
      "</li></ul>"
    end

    def person_separator
      "<span class='glyphicon glyphicon-user'></span>"
    end

end
