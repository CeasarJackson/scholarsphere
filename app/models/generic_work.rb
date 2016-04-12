# frozen_string_literal: true
class GenericWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include Sufia::WorkBehavior
  include ShareNotify::Metadata

  validates :title, presence: { message: 'Your work must have a title.' }
end
