class UserData < ActiveRecord::Base
  serialize :data

  def set_default_params
    self.data ||= OpenStruct.new
    self.data.player ||= Player.new
    self.data.player.set_default_params
    self
  end
end

require 'ostruct'

class Player < OpenStruct
  def set_default_params
    self.name = 'dgames'
    self
  end
end
