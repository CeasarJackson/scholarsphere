require 'spec_helper'

describe TransfersController do
  describe "with a signed in user" do

    let(:another_user) { FactoryGirl.find_or_create(:test_user_1) }
    let(:user) { FactoryGirl.find_or_create(:user) }
    before do
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
      sign_in user
    end

    describe "#index" do
      before do
        @incoming_file = GenericFile.new.tap do |f|
          f.apply_depositor_metadata(another_user.user_key)
          f.save!
          f.request_transfer_to(user)
        end
        @outgoing_file = GenericFile.new.tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save!
          f.request_transfer_to(another_user)
        end
      end
      it "should be successful" do
        get :index
        response.should be_success
        assigns[:incoming].first.should be_kind_of ProxyDepositRequest
        assigns[:incoming].first.pid.should == @incoming_file.pid

        assigns[:outgoing].first.should be_kind_of ProxyDepositRequest
        assigns[:outgoing].first.pid.should == @outgoing_file.pid
      end
    end

    describe "#new" do
      let(:file) do
        GenericFile.new.tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save!
        end
      end
      it "should be successful" do
        get :new, generic_file_id: file
        response.should be_success
        assigns[:generic_file].should == file 
        assigns[:proxy_deposit_request].should be_kind_of ProxyDepositRequest
        assigns[:proxy_deposit_request].pid.should == file.pid
      end
    end

    describe "#create" do
      let(:file) do
        GenericFile.new.tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save!
        end
      end
      it "should be successful" do
        lambda { 
          post :create, generic_file_id: file.id, proxy_deposit_request: {transfer_to: another_user.user_key}
        }.should change(ProxyDepositRequest, :count).by(1)
        response.should redirect_to transfers_path
        flash[:notice].should == 'Transfer request created'
        proxy_request = another_user.proxy_deposit_requests.first
        proxy_request.pid.should == file.pid
        proxy_request.sending_user.should == user
        # AND A NOTIFICATION SHOULD HAVE BEEN CREATED
        notification = another_user.reload.mailbox.inbox[0].messages[0]
        notification.subject.should == "jilluser wants to transfer a file to you"
        notification.body.should == "jilluser wants to transfer a file to you.\n" +
          "Click here: to review it: /dashboard/transfers"
      end
      it "should give an error if the user is not found" do
        lambda { 
          post :create, generic_file_id: file.id, proxy_deposit_request: {transfer_to: 'foo' }
        }.should_not change(ProxyDepositRequest, :count)
        assigns[:proxy_deposit_request].errors[:transfer_to].should == ['must be an existing user']
        response.should render_template('new')
        assigns[:generic_file].id.should == file.id
      end
    end

    describe "#accept" do
      context "when I am the receiver" do
        before do
          @incoming_file = GenericFile.new.tap do |f|
            f.apply_depositor_metadata(another_user.user_key)
            f.save!
            f.request_transfer_to(user)
          end
        end
        it "should be successful" do
          put :accept, id: user.proxy_deposit_requests.first
          response.should redirect_to transfers_path
          flash[:notice].should == "Transfer complete"
          assigns[:proxy_deposit_request].status.should == 'accepted'
        end
      end

      context "accepting one that isn't mine" do
        before do
          @incoming_file = GenericFile.new.tap do |f|
            f.apply_depositor_metadata(user.user_key)
            f.save!
            f.request_transfer_to(another_user)
          end
        end
        it "should not allow me" do
          put :accept, id: another_user.proxy_deposit_requests.first
          response.should redirect_to root_path
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end

    describe "#reject" do
      context "when I am the receiver" do
        before do
          @incoming_file = GenericFile.new.tap do |f|
            f.apply_depositor_metadata(another_user.user_key)
            f.save!
            f.request_transfer_to(user)
          end
        end
        it "should be successful" do
          put :reject, id: user.proxy_deposit_requests.first
          response.should redirect_to transfers_path
          flash[:notice].should == "Transfer rejected"
          assigns[:proxy_deposit_request].status.should == 'rejected'
        end
      end

      context "accepting one that isn't mine" do
        before do
          @incoming_file = GenericFile.new.tap do |f|
            f.apply_depositor_metadata(user.user_key)
            f.save!
            f.request_transfer_to(another_user)
          end
        end
        it "should not allow me" do
          put :reject, id: another_user.proxy_deposit_requests.first
          response.should redirect_to root_path
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end

    describe "#destroy" do
      context "when I am the sender" do
        before do
          @incoming_file = GenericFile.new.tap do |f|
            f.apply_depositor_metadata(user.user_key)
            f.save!
            f.request_transfer_to(another_user)
          end
        end
        it "should be successful" do
          delete :destroy, id: another_user.proxy_deposit_requests.first
          response.should redirect_to transfers_path
          flash[:notice].should == "Transfer canceled"
        end
      end

      context "accepting one that isn't mine" do
        before do
          @incoming_file = GenericFile.new.tap do |f|
            f.apply_depositor_metadata(another_user.user_key)
            f.save!
            f.request_transfer_to(user)
          end
        end
        it "should not allow me" do
          delete :destroy, id: user.proxy_deposit_requests.first
          response.should redirect_to root_path
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end

  end
end
