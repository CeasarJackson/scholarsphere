ScholarSphere::Application.routes.draw do
  # "Recently added files" route for catalog index view
  match "catalog/recent" => "catalog#recent", :as => :catalog_recent

  # Statistics page
  match "stats" => "stats#list", :via => :get, :as => :stats

  root :to => "catalog#index"

  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  Hydra::BatchEdit.add_routes(self)

  # Resque monitoring routes 
  namespace :admin do 
    constraints ResqueAdmin do 
      mount Resque::Server, :at => "queues" 
    end 
  end 

  # Login/logout route to destroy session
  match 'logout' => 'sessions#destroy', :as => :destroy_user_session
  match 'login' => 'sessions#new', :as => :new_user_session

  devise_for :users
  mount Sufia::Engine => '/'

  # LDAP-related routes for group and user lookups
  match 'directory/user/:uid' => 'directory#user'
  match 'directory/user/:uid/:attribute' => 'directory#user_attribute'
  match 'directory/group/:cn' => 'directory#group', :constraints => { :cn => /.*/ }


  # Batch edit routes
  match 'batches/:id/edit' => 'batch#edit', :as => :batch_edit
  match 'batches/:id/' => 'batch#update', :as => :batch_generic_files

  # Contact form routes
  match 'contact' => 'contact_form#create', :via => :post, :as => :contact_form_index
  match 'contact' => 'contact_form#new', :via => :get, :as => :contact_form_index

  # Generic file routes
  resources :generic_files, :path => :files, :except => :index do
    member do
      get 'citation', :as => :citation
      post 'audit'
      post 'permissions'
      get 'proxy'
    end
  end

  # Dashboard routes (based partly on catalog routes)
  match 'dashboard' => 'dashboard#index', :as => :dashboard
  match 'dashboard/activity' => 'dashboard#activity', :as => :dashboard_activity
  match 'dashboard/facet/:id' => 'dashboard#facet', :as => :dashboard_facet

  # Static page routes (workaround)
  match ':action' => 'static#:action', :constraints => { :action => /about|help|terms|zotero|mendeley|agreement|subject_libraries|versions/ }, :as => :static

  # User profile & follows
  match 'users' => 'users#index', :as => :profiles
  match 'users/:uid' => 'users#show', :as => :profile
  match 'users/:uid/edit' => 'users#edit', :as => :edit_profile
  match 'users/:uid/update' => 'users#update', :as => :update_profile, :via => :put
  match "users/:uid/trophy" => "users#toggle_trophy", :as => :update_trophy_user, :via => :post
  match 'users/:uid/follow' => 'users#follow', :as => :follow_user
  match 'users/:uid/unfollow' => 'users#unfollow', :as => :unfollow_user

  # Downloads controller route
  resources :downloads, :only => "show"

  # Authority vocabulary queries route
  match 'authorities/:model/:term' => 'authorities#query'

  # advanced routes for advanced search
  match 'search' => 'advanced#index', :as => :advanced

 match 'single_use_link/generate_download/:id' => 'single_use_link#generate_download', :as => :generate_download_single_use_link
  match 'single_use_link/generate_show/:id' => 'single_use_link#generate_show', :as => :generate_show_single_use_link
  match 'single_use_link/show/:id' => 'single_use_link#show', :as => :show_single_use_link
  match 'single_use_link/download/:id' => 'single_use_link#download', :as => :download_single_use_link

  # Messages
  match 'notifications' => 'mailbox#index', :as => :mailbox
  match 'notifications/delete_all' => 'mailbox#delete_all', :as => :mailbox_delete_all
  match 'notifications/:uid/delete' => 'mailbox#delete', :as => :mailbox_delete

  # Catch-all (for routing errors)
  match '*error' => 'errors#routing'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
