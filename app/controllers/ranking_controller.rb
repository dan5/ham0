class RankingController < ApplicationController
  def index
    @players = UserData.all.sort_by {|e| e.data.player.score.to_i }.map {|e| [e.data.player, e.login] }.reverse
  end

  def login
    session[:login] = params[:login]
    redirect_to '/'
  end
end
