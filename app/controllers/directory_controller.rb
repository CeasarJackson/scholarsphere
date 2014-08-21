class DirectoryController < ApplicationController

  # returns true if the user exists and false otherwise
  def user
    render json: User.directory_attributes(params[:uid])
  end

  def user_attribute
    if params[:attribute] == "groups"
      res = User.groups(params[:uid])
    else
      res = User.directory_attributes(params[:uid], params[:attribute])
    end
    render json: res
  end

  def user_groups
    render json: User.groups(params[:uid])
  end

  def group
    Group.exists?(params[:cn])
  end
end
