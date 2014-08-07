require_relative '../feature_spec_helper'

include Selectors::Dashboard

describe 'The Dashboard' do

  let!(:current_user) { create :user }
  let!(:second_user) { create(:user, display_name: "First Proxy") }
  let!(:third_user) { create(:user, display_name: "Second Proxy") }

  before do
    sign_in_as current_user
    go_to_dashboard
  end

  it "shows the user's statistics" do
    page.should have_content("Your Statistics")
    page.should have_content("Files you've deposited")
    page.should have_content("People you follow")
    page.should have_content("People who are following you")
  end

  it "displays information about the user" do
    page.should have_content "Joe Example"
    page.should have_link "View Profile"
    page.should have_link "Edit Profile"
  end

  it "shows recent activity" do
    page.should have_content "User Activity"
    page.should have_content "User has no recent activity"
  end

  describe 'proxy portal' do

    context "with multiple current proxies" do

      before do
        create_proxy_using_partial(second_user, third_user)
      end

      it "should list each proxy if both are authorized" do
        within("#authorizedProxies") do
          page.should have_content(second_user.display_name)
          page.should have_content(third_user.display_name)
        end
        go_to_dashboard
        within("#authorizedProxies") do
          page.should have_content(second_user.display_name)
          page.should have_content(third_user.display_name)
        end

        #should remove a proxy
        first(".remove-proxy-button").click
        go_to_dashboard
        within("#authorizedProxies") do
          page.should_not have_content(second_user.display_name)
          page.should have_content(third_user.display_name)
        end
      end

    end

  end

end
