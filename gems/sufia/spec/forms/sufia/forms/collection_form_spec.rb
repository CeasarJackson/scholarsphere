describe Sufia::Forms::CollectionForm do
  describe "#terms" do
    subject { described_class.terms }

    it do
      is_expected.to eq [:resource_type,
                         :title,
                         :creator,
                         :contributor,
                         :description,
                         :keyword,
                         :rights,
                         :publisher,
                         :date_created,
                         :subject,
                         :language,
                         :representative_id,
                         :thumbnail_id,
                         :identifier,
                         :based_near,
                         :related_url,
                         :visibility]
    end
  end

  let(:collection) { build(:collection) }
  let(:form) { described_class.new(collection) }

  describe "#primary_terms" do
    subject { form.primary_terms }
    it { is_expected.to eq([:title]) }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it do
      is_expected.to eq [
        :creator,
        :contributor,
        :description,
        :keyword,
        :rights,
        :publisher,
        :date_created,
        :subject,
        :language,
        :identifier,
        :based_near,
        :related_url,
        :resource_type
      ]
    end
  end

  describe "#id" do
    subject { form.id }
    it { is_expected.to be_nil }
  end
end
