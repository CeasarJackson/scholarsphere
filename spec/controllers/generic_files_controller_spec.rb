require 'spec_helper'

describe GenericFilesController, :type => :controller do
  routes { Sufia::Engine.routes }
  context "signed in user" do
    before do
      allow(Hydra::LDAP.connection).to receive(:get_operation_result).and_return(OpenStruct.new({code:0, message:"Success"}))
      allow(Hydra::LDAP).to receive(:does_user_exist?).and_return(true)
      @user = FactoryGirl.find_or_create(:jill)
      sign_in @user
      allow_any_instance_of(User).to receive(:groups).and_return([])
    end

    describe "#create" do
      before do
        @file_count = GenericFile.count
        @mock = GenericFile.new({pid: 'test:123'})
        allow(GenericFile).to receive(:new).and_return(@mock)
      end

      after do
        begin
          Batch.find("sample:batch_id").destroy
        rescue
        end
        @mock.delete unless @mock.inner_object.class == ActiveFedora::UnsavedDigitalObject
      end

      it "should call virus check" do
        allow_any_instance_of(GenericFile).to receive(:to_solr).and_return({ id: "foo:123" })
        file = fixture_file_upload('/world.png','image/png')
        s1 = double('one')
        expect(ContentDepositEventJob).to receive(:new).with('test:123','jilluser').and_return(s1)
        expect(Sufia.queue).to receive(:push).with(s1).once
        s2 = double('two')
        expect(CharacterizeJob).to receive(:new).with('test:123').and_return(s2)
        expect(Sufia.queue).to receive(:push).with(s2).once
        xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample:batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
      end
    end
  end

  context "public user" do
    let(:gf) {
      GenericFile.new(title: ['Test Document PDF'], filename: ['test.pdf'], read_groups:['public']).tap do |gf|
        gf.apply_depositor_metadata("mjg36")
        gf.save!
      end
    }
    routes { Sufia::Engine.routes }

    describe "#stats" do
      before do
        mock_query = double('query')
        allow(mock_query).to receive(:for_path).and_return([
            OpenStruct.new(date: '2014-01-01', pageviews: 4),
            OpenStruct.new(date: '2014-01-02', pageviews: 8),
            OpenStruct.new(date: '2014-01-03', pageviews: 6),
            OpenStruct.new(date: '2014-01-04', pageviews: 10),
            OpenStruct.new(date: '2014-01-05', pageviews: 2)])
        allow(mock_query).to receive(:map).and_return(mock_query.for_path.map(&:marshal_dump))
        profile = double('profile')
        allow(profile).to receive(:sufia__pageview).and_return(mock_query)
        allow(Sufia::Analytics).to receive(:profile).and_return(profile)
        download_query = double('query')
        allow(download_query).to receive(:for_file).and_return([OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:123456789", totalEvents: "3")])
        allow(download_query).to receive(:map).and_return(download_query.for_file.map(&:marshal_dump))
        allow(profile).to receive(:sufia__download).and_return(download_query)
      end

      it "doesn't call has access on stats" do
        expect(GenericFilesController).not_to receive(:has_access?)
        get :stats, id: gf.noid
      end
    end

    describe "#show" do
      it "creates loads from solr" do
        expect(CanCan::ControllerResource.any_instance).not_to receive(:load_and_authorize_resource)
        get :show, id: gf.noid
        expect(response).not_to redirect_to(action: 'show')
        expect(assigns[:generic_file].inner_object.class).to eq ActiveFedora::SolrDigitalObject
      end
    end
  end
end
