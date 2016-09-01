# frozen_string_literal: true
require 'spec_helper'

describe CurationConcerns::GenericWorksController, type: :controller do
  describe "#show" do
    context "with a public user" do
      let(:work) { create(:public_work) }
      it "loads from solr" do
        expect_any_instance_of(CanCan::ControllerResource).not_to receive(:load_and_authorize_resource)
        get :show, id: work.id
        expect(assigns(:presenter)).to be_kind_of Sufia::WorkShowPresenter
      end
    end

    context "when the work doesn't exist" do
      it "redirects to the login" do
        get :show, id: 'non-existent-id'
        expect(response.redirect_url).to eq("http://test.host/login_session")
      end
    end

    context "when file is registered" do
      let(:work)   { create(:registered_file) }
      let(:path)   { Rails.application.routes.url_helpers.curation_concerns_generic_work_path(work) }
      it "redirects with file in url" do
        get :show, id: work.id
        expect(response.status).to eq(302)
        expect(session[:user_return_to]).to include(path)
      end
    end
  end

  describe "#delete" do
    let(:user)  { create(:user) }
    let!(:work) { create(:share_file, depositor: user.login) }
    before do
      allow_any_instance_of(Devise::Strategies::HttpHeaderAuthenticatable).to receive(:remote_user).and_return(user.login)
      allow_any_instance_of(User).to receive(:groups).and_return([])
    end
    it "is deleted from SHARE notify" do
      expect(ShareNotifyDeleteJob).to receive(:perform_later).with(work)
      delete :destroy, id: work
    end
  end

  context "when file is private" do
    let(:gf) { create(:private_file) }
    before   { sign_in user }

    context "when user is not administrator" do
      let(:user) { FactoryGirl.create(:user) }

      it "does not allow any user to view" do
        get :show, id: gf.id
        expect(response.status).to eq(401)
      end

      it "does not allow any user to edit" do
        get :edit, id: gf.id
        expect(response.status).to eq(401)
      end

      it "does not allow any user to update" do
        post :update, id: gf.id, generic_file: { title: ['new_title'] }
        expect(response.status).to eq(401)
      end
    end

    context "when user is an administrator" do
      let(:user) { FactoryGirl.create(:administrator) }

      it "does allow user to view" do
        get :show, id: gf.id
        expect(response.status).to eq(200)
      end

      it "allows edits" do
        get :edit, id: gf.id
        expect(response.status).to eq(200)
      end

      it "allows updates" do
        post :update, id: gf.id, generic_work: { title: ['new_title'] }
        expect(response.status).to eq(302)
        expect(gf.reload.title).to eq(['new_title'])
      end
    end
  end
end
