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
    self.name ||= 'dgames'
    self.hamsters ||= []
    self.field_hamsters ||= []
    self
  end

  def move_to_field(rank, num)
    hams = hamsters_with_rank(rank).first(num)
    self.hamsters -= hams
    self.field_hamsters += hams
  end

  def escape(rank)
    hams = field_hamsters_with_rank(rank)
    self.field_hamsters -= hams
    self.hamsters += hams
  end

  def battle
    hams = field_hamsters
    hams.shuffle!
    (hams.size / 2).times do |i|
      a = hams[i * 2]
      b = hams[i * 2 + 1]
      r = rand(3)
      next if r == 0
      a.add_exp
      b.kill
    end
    hams.reject!(&:dead?)
    #hams.sort!
  end

  def hamsters_with_rank(rank)
    hamsters.select {|e| e.rank == rank }
  end

  def field_hamsters_with_rank(rank)
    field_hamsters.select {|e| e.rank == rank }
  end

  def create_hamster(params = {})
    field_hamsters << Hamster.new(params).set_default_params
  end
end

class Hamster < OpenStruct
  def set_default_params
    self.rank ||= 0
    self.wins ||= 0
    self.uid ||= rand(999_999_999_999)
    self
  end

  def dead?
    @is_dead == true
  end

  def kill
    @is_dead = true
  end

  def add_exp()
    self.wins += 1
    if self.wins >= 3
      self.wins = 0
      self.rank += 1
    end  
  end

  def self.rank_name(rank)
    %w(野生ハム 村人 たね集め 足軽 ドワーフ メイドさん 鍛冶屋 狩人 戦士 遊び人 - - - - - - 将軍 キング)[rank]
  end
end
