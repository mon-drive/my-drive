class HomeController < ApplicationController
  def index
    if session[:user_id]
      @google_profile_image = current_user.profile_picture
    end
  end
end
