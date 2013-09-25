class GameController < ApplicationController
  def index
  end

  def add
    num = params[:num].to_i
    num.times do
      player.create_hamster
    end
    redirect_to '/'
  end

  def update
    player.update
    redirect_to '/'
  end

  def hunt
    player.hunt
    redirect_to '/'
  end

  def act
    player.act params[:rank].to_i
    redirect_to '/'
  end

  def field
    player.move_to_field params[:rank].to_i, params[:num].to_i
    redirect_to '/'
  end

  def escape
    player.escape params[:rank].to_i
    redirect_to '/'
  end

  def battle
    player.battle
    redirect_to '/'
  end

  def reset
    user_data.player = nil
    redirect_to '/'
  end
end
