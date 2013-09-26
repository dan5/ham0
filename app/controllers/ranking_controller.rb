class RankingController < ApplicationController
  def index
    @players = UserData.all.sort_by {|e| -e.data.player.score }.map {|e| [e.data.player, e.login] }
  end

  def login
    session[:login] = params[:login]
    redirect_to '/'
  end
end
