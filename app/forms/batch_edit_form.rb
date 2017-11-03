# frozen_string_literal: true

class BatchEditForm < Sufia::Forms::BatchEditForm
  include WithCreator
  include WithCleanerAttributes

  def self.build_permitted_params
    permitted = super
    permitted << { creators: [:id, :display_name, :given_name, :sur_name, :_destroy] }
    permitted << :visibility
    permitted
  end

  def model_class_name
    'batch_edit_item'
  end

  def creators
    # The model.creators association doesn't seem to work
    # properly with an unpersisted record, so we manually load
    # the creator records here.
    if model.new_record? && model.creator_ids.present?
      agent_records = Agent.find model.creator_ids
      model.creators = agent_records
    end
    super
  end

  def initialize_combined_fields
    super
    permissions = []
    admin_set_id = ''
    batch_document_ids.each do |doc_id|
      work = model_class.find(doc_id)
      permissions = (permissions + work.permissions).uniq
      admin_set_id = work.admin_set_id
    end
    model.admin_set_id = admin_set_id
    model.permissions_attributes = permissions.map(&:to_hash).uniq
  end
end
