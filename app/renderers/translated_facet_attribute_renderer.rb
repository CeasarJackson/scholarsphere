# frozen_string_literal: true
# Override CurationConcerns::Renderers::FacetedAttributeRenderer so we can pass different values
# for facets. This allows us to display a faceted search link using the text that the user
# originally entered while using the normalized text that was created when the facet was
# "cleaned" using the SolrDocumentGroomer.
class TranslatedFacetAttributeRenderer < CurationConcerns::Renderers::FacetedAttributeRenderer
  private

    def li_value(value)
      link_to(ERB::Util.h(value), search_path(value_for_facet(value)))
    end

    def value_for_facet(value)
      return value unless options.key?(:mapping)
      options[:mapping][value]
    end
end
