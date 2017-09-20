# frozen_string_literal: true

require 'rails_helper'

describe Collection do
  subject { collection }

  describe 'setting creators' do
    let!(:person) { create(:person, given_name: 'Lucy', sur_name: 'Lee') }
    let!(:lucy)   { create(:alias, display_name: 'Lucy Lee', person: person) }

    let(:collection) { create(:collection, creators: attributes) }
    let(:attributes) do
      [
        { 'display_name' => 'Fred Jones', 'given_name' => 'Fred', 'sur_name' => 'Jones' },
        { 'display_name' => 'Lucy Lee', 'given_name' => 'Lucy', 'sur_name' => 'Lee' }
      ]
    end

    it 'finds or creates the Alias record' do
      expect { collection.save! }
        .to change { described_class.count }.by(1)
        .and change { Alias.count }.by(1)
      expect(collection.creators).to include lucy
      expect(collection.creators.map(&:display_name)).to contain_exactly('Fred Jones', 'Lucy Lee')
    end
  end

  context 'with no attached files' do
    let(:collection) { build(:collection) }

    its(:bytes) { is_expected.to eq(0) }
  end

  context 'with attached files' do
    let!(:collection) { create(:public_collection, members: [work1, work2]) }

    let(:work1)       { build(:public_work, id: '1') }
    let(:work2)       { build(:public_work, id: '2') }
    let(:resp) do
      [{ Solrizer.solr_name(:file_size, CurationConcerns::CollectionIndexer::STORED_LONG) => '20' }]
    end

    before { allow(ActiveFedora::SolrService).to receive(:query).and_return(resp) }
    its(:bytes) { is_expected.to eq(40) }
  end

  describe '::indexer' do
    let(:collection) { described_class }

    its(:indexer) { is_expected.to eq(CollectionIndexer) }
  end

  context 'with a new collection' do
    let(:collection) { build(:collection) }

    it { is_expected.not_to be_private_access }
    it { is_expected.to be_open_access }
  end
end
