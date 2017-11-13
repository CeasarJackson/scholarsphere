# frozen_string_literal: true

module Migration
  class SolrListMigrator
    class << self
      def migrate_creators(solr_object_list, creator_alias_hash)
        solr_object_list.each_with_load do |object|
          update(object, creator_alias_hash)
        end
      end

      def update(object, creator_alias_hash)
        return if object.creator_ids.empty?
        return if already_migrated?(object)

        update_creators(object, creator_alias_hash)
      end

      private

        def already_migrated?(object)
          object.creator_ids[0].match(/^[0-9A-F]{8}-[0-9A-F]{4}/i)
        end

        def update_creators(object, creator_alias_hash)
          creators = translate_creators(object.creator_ids, creator_alias_hash)
          object = clear_creators(object)
          object.creators = creators
          object.save
        end

        def translate_creators(creators, creator_alias_hash)
          alias_list = []
          creators.each do |creator|
            creator_alias = lookup_creator(creator, creator_alias_hash)
            if creator_alias.blank?
              logger.error "Creator alias could not be found for #{creator}"
            else
              alias_list << creator_alias
            end
          end
          alias_list
        end

        def lookup_creator(creator, creator_alias_hash)
          clean_creator = creator.strip.squeeze(' ')
          creator_alias = creator_alias_hash[clean_creator]
          return creator_alias if creator_alias.present?

          cleaner_creator = clean_creator.gsub(',', '')
          creator_alias_hash[cleaner_creator]
        end

        def clear_creators(object)
          creator_uri = RDF::URI.new('http://purl.org/dc/elements/1.1/creator')
          update_uri = object.uri.to_s
          ActiveFedora::SparqlInsert.new(creator_uri => RDF::Graph.new).execute(update_uri)
          object.reload
        end
    end
  end
end
