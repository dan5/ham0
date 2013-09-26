require 'ostruct'

class UserData < ActiveRecord::Base
  serialize :data

  def set_default_params
    self.data ||= OpenStruct.new
    self.data.player ||= Player.new
    self.data.player.set_default_params
    self
  end
end

class Player
  attr_accessor :name
  attr_accessor :hamsters, :field_hamsters
  attr_accessor :items, :foods, :wilds, :action_num
  def set_default_params
    @name ||= 'dgames'
    @hamsters ||= []
    @field_hamsters ||= []
    @items ||= []
    @foods ||= 1000
    @wilds ||= 10
    @action_num ||= 1000
    self
  end

  def zip
    @hamsters_data = hamsters.map(&:zip).pack("C*")
    @field_hamsters_data = field_hamsters.map(&:zip).pack("C*")
    @hamsters = nil
    @field_hamsters = nil
  end

  def unzip
    @hamsters = (@hamsters_data or "").unpack("C*").map {|v| Hamster.unzip(v) }
    @field_hamsters = (@field_hamsters_data or "").unpack("C*").map {|v| Hamster.unzip(v) }
  end

  def update
    @action_num -= 1
    @wilds += 10
    @foods -= (@hamsters.size + @field_hamsters.size) / 100 + 1
    if @foods > 0
      (1..10).each do |rank|
        n = hamsters_with_rank(rank).size
        items[rank] ||= 0
        items[rank] += n / 10.0
        items[rank] = [items[rank], 99].min
      end
    else
      @foods = 0
    end
  end

  def hunt
    @action_num -= 1
    @wilds.times { create_hamster }
    @wilds = 10
  end

  def act(rank)
    @action_num -= 1
    num = items[rank].to_i
    if num > 0
      items[rank] -= 1
      if item_act = Hamster::Data.values[rank][:item_act]
        item_act.call(self)
      end
    end
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
    @action_num -= 1
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

  def create_hamster
    field_hamsters << Hamster.new(0, 0)
  end
end

class Hamster
  Data = {
    野良ハム: {},
    タネ農家: {
      item: 'タネ',
      item_act: lambda {|c| c.foods += 100 }
    },
    狩人: {
      item: '弓矢',
      item_act: lambda {|c| c.wilds += 100 }
    },
    ドワーフ: {
      item: '金塊',
      #item_act: lambda {|c| c.golds += 100 }
    },
    キング: {
      item: '平和',
      #item_act: lambda {|c| c.golds += 100 }
    },
  }

  attr_accessor :rank
  attr_accessor :wins

  def initialize(rank, wins)
    @rank = rank
    @wins = wins
  end

  def zip
    48 + rank * 3 + wins
  end

  def self.unzip(v)
    a = v - 48
    Hamster.new(a / 3, a % 3)
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
