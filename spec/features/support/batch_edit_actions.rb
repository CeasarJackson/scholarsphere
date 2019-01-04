# frozen_string_literal: true

module Features
  module BatchEditActions
    def fill_in_batch_edit_field(id, opts = {})
      click_link "expand_link_#{id}"
      within "#form_#{id}" do
        fill_in "batch_edit_item_#{id}", with: opts.fetch(:with, "NEW #{id}")
        click_button "#{id}_save"
      end
      wait_until_saved(id)
    end

    def fill_in_three_batch_edit_fields(id1,id2,id3)
      click_link "expand_link_#{id1}"
      within "#form_#{id1}" do
        fill_in "batch_edit_item_#{id1}", with: "NEW #{id1}"
      end
      click_link "expand_link_#{id2}"
      within "#form_#{id2}" do
        fill_in "batch_edit_item_#{id2}", with: "NEW #{id2}"
      end
      click_link "expand_link_#{id3}"
      within "#form_#{id3}" do
        fill_in "batch_edit_item_#{id3}", with: "NEW #{id3}"
      end
      within "#form_#{id1}" do
        click_button "#{id1}_save"
      end
      within "#form_#{id2}" do
        click_button "#{id2}_save"
      end
      within "#form_#{id3}" do
        click_button "#{id3}_save"
      end
      wait_until_saved(id1)
      wait_until_saved(id2)
      wait_until_saved(id3)
    end

    def wait_until_saved(id)
      within "#form_#{id}" do
        total_duration = 0
        sleep_duration = 0.1
        until page.text.include?('Changes Saved') || total_duration > 5 do
          sleep sleep_duration
          total_duration += sleep_duration
        end
        expect(page).to(have_content('Changes Saved'), "Save timed out on field #{id}")
      end
    end

    def batch_edit_fields
      [
        'contributor', 'description', 'keyword', 'publisher', 'date_created', 'subject',
        'language', 'identifier', 'related_url'
      ]
    end
  end
end

RSpec.configure do |config|
  config.include Features::BatchEditActions, type: :feature
end
