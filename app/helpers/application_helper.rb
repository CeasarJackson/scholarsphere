# frozen_string_literal: true
# Helper methods unique to Scholarsphere only and not overrides of helpers from included gems
module ApplicationHelper
  def collection_helper_method(value)
    c = Collection.load_instance_from_solr(value)
    c.title
  end

  # TODO: Needed? this is in curation_concerns-0.14.0.pre1/app/inputs/select_with_modal_help_input.rb
  def link_to_help(subject)
    link_to '#', id: "#{subject}_help", rel: 'popover',
                 'data-content' => t("hydra.metadata_help.#{subject}_html"), 'data-original-title' => subject.titleize,
                 'aria-label' => "Help for #{subject.titleize}" do
      help_icon
    end
  end

  def render_linked_field(value, link_function, opt_param)
    return link_function.call value if opt_param.blank?
    return link_function.call value, opt_param unless link_function.name == :link_to_field
    link_function.call opt_param, value
  end

  def permission_level_tag(document)
    if document.registered?
      value = t('sufia.institution_name')
      class_name = "label-info"
    elsif document.public?
      value = "Open Access"
      class_name = "label-success"
    else
      value = "Private"
      class_name = "label-danger"
    end
    path = if can? :edit, document
             sufia.edit_generic_file_path(document, tab: "permissions")
           else
             sufia.generic_file_path(document)
           end
    link_to content_tag(:span, value, class: "label #{class_name}", title: value), path, id: "permission_#{document.id}"
  end
end
