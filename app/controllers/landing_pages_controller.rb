class LandingPagesController < ApplicationController

  layout 'landing'

  def new
    @landing_page = LandingPage.new
  end

  def create
    @landing_page = LandingPage.new(params[:landing_page])
    @landing_page.request = request
    # not spam and a valid form
    if @landing_page.valid?
      UserMailer.response_for_information(@landing_page.email, @landing_page.name).deliver
      flash.now[:notice] = 'Thank you for your request. A ScholarSphere team member will be in touch with you shortly.'
      after_deliver
      render :new
    else
      flash[:error] = 'Sorry, this message was not sent successfully. '
      flash[:error] << @landing_page.errors.full_messages.map { |s| s.to_s }.join(",")
      render :new
    end
  rescue
    flash[:error] = 'Sorry, this message was not delivered.'
    render :new
  end

  # override to change what occurs after deliver
  def after_deliver
  end

end
