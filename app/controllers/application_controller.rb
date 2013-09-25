class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter {
    session[:login] ||= uniq_string
    @user_data = UserData.find_or_create_by(login: session[:login]).set_default_params
    player.unzip
  }

  after_filter {
    player.zip
    @user_data.save!
  }

  def player
    user_data.player
  end
  helper_method :player

  def user_data
    @user_data.data
  end
  helper_method :user_data

  def uniq_string
    rand(999_999_999_999_999).to_s(36)
  end
end
