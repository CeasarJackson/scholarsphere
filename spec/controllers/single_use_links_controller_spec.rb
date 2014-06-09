require 'spec_helper'

describe SingleUseLinksController do
  routes { Sufia::Engine.routes }
  before(:each) do
    @user = FactoryGirl.find_or_create(:user)
    @file = GenericFile.new
    @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    @file.apply_depositor_metadata(@user)
    @file.save
    @file2 = GenericFile.new
    @file2.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    @file2.apply_depositor_metadata('mjg36')
    @file2.save
  end
  before do
    controller.stub(:has_access?).and_return(true)
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end
  describe "logged in user with edit permission" do
    before do
      sign_in @user
      @now = DateTime.now
      DateTime.stub(:now).and_return(@now)
      @hash = "some-dummy-sha2-hash" 
      Digest::SHA2.should_receive(:new).and_return(@hash)
    end

    describe "GET 'download'" do
      it "and_return http success" do
        get 'new_download', id:@file.pid
        response.should be_success
        assigns[:link].should == @routes.url_helpers.download_single_use_link_path(@hash)
      end

    end
  
    describe "GET 'show'" do
      it "and_return http success" do
        get 'new_show', id:@file.pid
        response.should be_success
        assigns[:link].should == @routes.url_helpers.show_single_use_link_path(@hash)
      end

    end   
  end

  describe "logged in user without edit permission" do
    before do
      @other_user = FactoryGirl.find_or_create(:archivist)
      @file.read_users << @other_user
      @file.save
      sign_in @other_user
    end

    describe "GET 'download'" do
      it "and_return http success" do
        get 'new_download', id:@file.pid
        response.should_not be_success
      end

    end

    describe "GET 'show'" do
      it "and_return http success" do
        get 'new_show', id:@file.pid
        response.should_not be_success
      end

    end
  end

  describe "unkown user" do
    describe "GET 'download'" do
      it "and_return http failure" do
        get 'new_download', id:@file.pid
        response.should_not be_success
      end
    end
  
    describe "GET 'show'" do
      it "and_return http failure" do
        get 'new_show', id:@file.pid
        response.should_not be_success
      end
    end   
  end

end
