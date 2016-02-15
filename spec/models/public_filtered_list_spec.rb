# frozen_string_literal: true
require 'spec_helper'

describe PublicFilteredList, type: :model do
  let(:file_list) { [GenericFile.new(title: ["private"]), GenericFile.new(title: ['public']) { |f| f.visibility = 'open' }] }

  subject { described_class.new(file_list).filter }

  it "keeps public files" do
    expect(subject.count).to eq(1)
    expect(subject.map(&:title)).to include(['public'])
    expect(subject.map(&:title)).not_to include(['private'])
  end
end
