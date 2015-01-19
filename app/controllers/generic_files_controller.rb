class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior
  include Behaviors::PermissionsNotificationBehavior

  around_action :notify_users_of_permission_changes, only: [:destroy,:create,:update]
  skip_before_action :has_access?, only: [:stats]
  
  # TODO: load and authorize resource are causing problems (#9678)
  #skip_load_resource(only: [:show])
  #before_filter :load_resource_from_solr, only: [:show]
  #authorize_resource only: [:show]
  #def load_resource_from_solr
  #  @generic_file = ::GenericFile.load_instance_from_solr(params[:id])
  #  @generic_file
  #end

  def notify_users_of_permission_changes
    previous_permissions = @generic_file.permissions unless @generic_file.nil?
    yield
    current_permissions = @generic_file.permissions unless @generic_file.nil?
    permission_state = evaluate_permission_state(previous_permissions,current_permissions)
    notify_users(permission_state)
  end
end
