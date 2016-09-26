# frozen_string_literal: true
require 'feature_spec_helper'

describe 'Batch management of works', type: :feature do
  let(:current_user) { create(:user) }
  let!(:work1)       { create(:public_work, :with_complete_metadata, depositor: current_user.login) }
  let!(:work2)       { create(:public_work, :with_complete_metadata, depositor: current_user.login) }

  before do
    sign_in_with_js(current_user)
    visit '/dashboard/works'
  end

  describe 'editing and viewing multiple works' do
    before do
      check 'check_all'
      click_on 'batch-edit'
      fields.each { |f| fill_in_field(f) }
      work1.reload
      work2.reload
    end
    xit 'edits each field and displays the changes', js: true do
      expect(work1.contributor).to eq ['NEW contributor']
      expect(work1.description).to eq ['NEW description']
      expect(work1.keyword).to eq ['NEW keyword']
      expect(work1.publisher).to eq ['NEW publisher']
      expect(work1.date_created).to eq ['NEW date_created']
      expect(work1.subject).to eq ['NEW subject']
      expect(work1.language).to eq ['NEW language']
      expect(work1.identifier).to eq ['NEW identifier']
      expect(work1.based_near).to eq ['NEW based_near']
      expect(work1.related_url).to eq ['NEW related_url']
      expect(work2.contributor).to eq ['NEW contributor']
      expect(work2.description).to eq ['NEW description']
      expect(work2.keyword).to eq ['NEW keyword']
      expect(work2.publisher).to eq ['NEW publisher']
      expect(work2.date_created).to eq ['NEW date_created']
      expect(work2.subject).to eq ['NEW subject']
      expect(work2.language).to eq ['NEW language']
      expect(work2.identifier).to eq ['NEW identifier']
      expect(work2.based_near).to eq ['NEW based_near']
      expect(work2.related_url).to eq ['NEW related_url']

      # Reload the form and verify
      visit '/dashboard/works'
      check 'check_all'
      click_on 'batch-edit'
      expect(page).to have_content('Batch Edit Descriptions')
      expand("contributor")
      expect(page).to have_css "input#generic_work_contributor[value*='NEW contributor']"
      expand("description")
      expect(page).to have_css "textarea#generic_work_description", 'NEW description'
      expand("keyword")
      expect(page).to have_css "input#generic_work_keyword[value*='NEW keyword']"
      expand("publisher")
      expect(page).to have_css "input#generic_work_publisher[value*='NEW publisher']"
      expand("date_created")
      expect(page).to have_css "input#generic_work_date_created[value*='NEW date_created']"
      expand("subject")
      expect(page).to have_css "input#generic_work_subject[value*='NEW subject']"
      expand("language")
      expect(page).to have_css "input#generic_work_language[value*='NEW language']"
      expand("identifier")
      expect(page).to have_css "input#generic_work_identifier[value*='NEW identifier']"
      expand("based_near")
      expect(page).to have_css "input#generic_work_based_near[value*='NEW based_near']"
      expand("related_url")
      expect(page).to have_css "input#generic_work_related_url[value*='NEW related_url']"
    end
  end

  describe 'Deleting multiple works', js: true do
    context 'Selecting all my works to delete' do
      before do
        visit '/dashboard/works'
        check 'check_all'
        click_button 'Delete Selected'
      end
      it 'Removes the works from the system' do
        expect(GenericWork.count).to be_zero
      end
    end
  end

  def fields
    [
      "contributor", "description", "keyword", "publisher", "date_created", "subject",
      "based_near", "language", "identifier", "related_url"
    ]
  end

  def fill_in_field(id)
    expand(id)
    within "#form_#{id}" do
      fill_in "generic_work_#{id}", with: "NEW #{id}"
      click_button "#{id}_save"
    end
    within "#form_#{id}" do
      sleep 0.1 until page.text.include?('Changes Saved')
      expect(page).to have_content 'Changes Saved', wait: Capybara.default_max_wait_time * 4
    end
  end

  def expand(field)
    link = find("#expand_link_#{field}")
    while link["class"].include?("collapsed")
      sleep 0.1
      link.click if link["class"].include?("collapsed")
    end
  end
end
