# frozen_string_literal: true
class CollectionPresenter < Sufia::CollectionPresenter
  # TODO: Move to Sufia?
  def self.terms
    super + [:date_modified, :date_uploaded]
  end
end
