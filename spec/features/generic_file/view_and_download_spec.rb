# frozen_string_literal: true
# This file is a Work in Progress
require 'feature_spec_helper'

include Selectors::Dashboard

describe 'Generic File viewing and downloading:', type: :feature do
  context "generic user" do
    let(:current_user) { create(:user) }
    let!(:work1) do
      create(:public_work_with_png, :full_meta_data,
             depositor: current_user.login,
             description: ["Description http://example.org/TheDescriptionLink/"]
            )
    end
    let!(:work2) { create(:private_work, depositor: current_user.login) }

    before do
      sign_in_with_js(current_user)
      visit '/dashboard/works'
      expect(page).to have_css '.active a', text: "Works"
      db_item_title(work1).click
    end

    context 'When viewing a file' do
      specify "I see all the correct information" do
        # "I can see the file's page" do
        expect(page).to have_content work1.title.first

        # 'I can not feature' do
        expect(page).not_to have_link "Feature"

        # 'I should see the visibility link' do
        within("h1 span") do
          expect(page).to have_content("Open Access")
        end

        # 'I should see the breadcrumb trail' do
        expect(page).to have_link("My Dashboard")

        # TODO: sufia does not contain the works breadcrumb
        # expect(page).to have_link("My Works")

        # 'I can see the link for all the linkable items' do
        # TODO sufia does not contain linked text in the description
        # expect(page).to have_link 'http://example.org/TheDescriptionLink/'
        expect(page).to have_link work1.related_url.first

        # 'I can download an Endnote version of the file'
        endnote_link = find_link('EndNote')[:href]

        # get an array of all the links we are testing
        test_links = {}

        # 'I can see the link for creator and it filters correctly' do
        test_links = store_link work1.creator.first, test_links

        # 'I can see the link for contributor and it filters correctly' do
        test_links = store_link work1.contributor.first, test_links

        # TODO: sufia does not currently support linking the following fields
        # 'I can see the link for publisher and it filters correctly' do
        # test_links = store_link work1.publisher.first, test_links

        # 'I can see the link for subject and it filters correctly' do
        # test_links = store_link work1.subject.first, test_links

        # 'I can see the link for language and it filters correctly' do
        # test_links = store_link work1.language.first, test_links

        # 'I can see the link for based_near and it filters correctly' do
        # test_links = store_link work1.based_near.first, test_links

        # 'I can see the link for a tag and it filters correctly' do
        # test_links = store_link file1.keyword.first, test_links

        # 'I can see the link for rights and it filters correctly' do
        # test_links = store_link Sufia.config.cc_licenses_reverse[work1.rights.first], test_links
        store_link Sufia.config.cc_licenses_reverse[work1.rights.first], test_links

        # TODO: sufia does not create the correct links for us to find our file
        # loop through all links
        # test_links.each do |name, link|
        #   test_link name, link
        # end

        # test the end not page
        visit endnote_link
        expect(page.response_headers['Content-Type']).to eq('application/x-endnote-refer; charset=utf-8')
      end

      # specify 'I can see the Mendeley modal' do
      #  skip 'This does not appear to be functioning properly'
      #  click_link 'Mendeley'
      #  expect(page).to have_css('.modal-header')
      # end
      #
      # specify 'I can see the Zotero modal' do
      #  skip 'This does not appear to be functioning properly'
      #  click_link 'Zotero'
      #  expect(page).to have_css('.modal-header')
      # end
    end
  end

  context "administrator user" do
    let(:admin_user)    { create(:administrator) }
    let!(:public_file)  { create(:public_file, depositor: admin_user.login) }
    let!(:private_file) { create(:private_file, depositor: admin_user.login) }

    before do
      sign_in_with_js(admin_user)
      visit '/dashboard/works'
    end

    context 'When viewing a public file' do
      before  { db_item_title(public_file).click }
      specify { expect(page).to have_link "Feature" }
    end

    context 'When viewing a private file' do
      before  { db_item_title(private_file).click }
      specify { expect(page).not_to have_link "Feature" }
    end
  end

  context 'When downloading a file' do
    # TBD
  end

  def store_link(link_name, test_links)
    expect(page).to have_link link_name
    test_links[link_name] = find_link(link_name)[:href]
    test_links
  end

  def test_link(_link_name, link_value)
    visit link_value
    expect(page).to have_content work1.title.first
    expect(page).not_to have_content work1.title.first
  end
end
