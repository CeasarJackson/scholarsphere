require 'spec_helper'

describe GenericFile, :type => :model do

  let(:user) { FactoryGirl.create :random_user }
  before(:each) do
    @file = GenericFile.new
    @file.apply_depositor_metadata(user.user_key)
  end

  it 'should export as endnote' do
    @file.stub(pid: 'stubbed_pid')
    expect(@file.export_as_endnote).to eq("%0 GenericFile\n%R http://scholarsphere.psu.edu/files/stubbed_pid\n%~ ScholarSphere\n%W Penn State University")
  end

  describe "create_thumbnail" do
    describe "with an image that doesn't get resized" do
      before do
        @f = GenericFile.new
        @f.stub(mime_type:'image/png', width:['50'], height:['50'])  #Would get set by the characterization job
        @f.add_file_datastream(File.open("#{Rails.root}/spec/fixtures/world.png", 'rb'), dsid:'content')
        @f.apply_depositor_metadata('mjg36')
        @f.save
      end
      after do
        @f.delete
      end
      it "should keep the thumbnail at its original size" do
        expect(@f.content.changed?).to be_falsey
      end
    end
  end

  describe "save" do
    after(:each) do
      @file.delete
    end
    it "should schedule a characterization job" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), dsid:'content')
      @file.save
    end
  end

  describe "characterize" do
    describe "after job runs" do
      # File.new(Rails.root + 'spec/fixtures/scholarsphere/scholarsphere_test4.pdf')
      before(:all) do
        @myfile = GenericFile.new
        @myfile.add_file(File.open(fixture_path + '/scholarsphere/scholarsphere_test4.pdf', 'rb').read, 'content', 'sufia_test4.pdf')
        @myfile.label = 'label123'
        @myfile.apply_depositor_metadata('mjg36')
        @myfile.characterize
      end
      after(:all) do
        @myfile.destroy
      end
      it "should NOT append metadata from the characterization" do
        expect(@myfile.title).not_to include("Microsoft Word - sample.pdf.docx")
        expect(@myfile.filename[0]).to eq(@myfile.label)
      end
      it "should NOT append each term only once" do
        @myfile.append_metadata
        expect(@myfile.format_label).to eq(["Portable Document Format"])
        expect(@myfile.title).not_to include("Microsoft Word - sample.pdf.docx")
      end
    end
  end

end
