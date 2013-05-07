module UserLogin

  def login_as(login)
      driver_name = "rack_test_authenticated_header_#{login}".to_s
      Capybara.register_driver(driver_name) do |app|
        Capybara::RackTest::Driver.new(app, headers: { 'REMOTE_USER' => login })
      end
      user = User.find_or_create_by_login(login)
      User.find_by_login(login).should_not be_nil
      Capybara.current_driver = driver_name
  end  

  
  def login_js
    
    Devise::Strategies::HttpHeaderAuthenticatable.class_eval do
    
      # Called if the user doesn't already have a rails session cookie
      def valid?
        true
      end
     
      def authenticate!
        remote_user = 'jilluser'
        u = User.find_by_login(remote_user)
        if u.nil?
          u = User.create(:login => remote_user)
          u.populate_attributes
        end
        u.ldap_available = true
        u.save
        success!(u)
      end
    end
    
  end
  
end