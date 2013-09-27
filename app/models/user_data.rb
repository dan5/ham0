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
  attr_accessor :items, :foods, :golds, :wilds, :seeds, :action_num
  attr_accessor :score
  def set_default_params
    @name ||= 'dgames'
    @hamsters ||= []
    @field_hamsters ||= []
    @items ||= []
    @foods ||= 100
    @golds ||= 10000
    @wilds ||= 10
    @seeds ||= 10
    @action_num ||= 1000
    @score ||= 0
    self
  end

  def zip
    num = hamsters.size + field_hamsters.size
    @score = (0..10).inject(0) {|t, rank| t + all_hamsters_with_rank(rank).size ** rank }
    @hamsters_data = hamsters.map(&:zip).join
    @field_hamsters_data = field_hamsters.map(&:zip).join
    @hamsters = nil
    @field_hamsters = nil
  end

  def rounded_score
    @score.to_f.round(1)
  end

  def unzip
    @hamsters = (@hamsters_data or "").scan(/../).map {|v| Hamster.unzip(v) }
    @field_hamsters = (@field_hamsters_data or "").scan(/../).map {|v| Hamster.unzip(v) }
  end

  def update
    @action_num += 10
    @wilds += 10
    @seeds += 10
  end

  def use_item(rank)
    num = items[rank].to_i
    if num > 0
      if item_act = Hamster::Data.values[rank][:item_act]
        if used_num = item_act.call(self, num)
          items[rank] -= used_num
        else
          items[rank] = 0
        end
      end
    end
  end

  def hunt
    @action_num -= 1
    n = [@wilds, @golds].min
    n.times { create_hamster }
    @golds -= n
    @wilds -= n
    @wilds = [@wilds, 10].max
  end

  def harvest
    @action_num -= 1
    @foods += @seeds
    @seeds = 10
  end

  def work
    @action_num -= 1
    eat
    if @foods > 0
      (0..10).each do |rank|
        n = hamsters_with_rank(rank).size
        items[rank] ||= 0
        items[rank] += n / 10.0
        items[rank] = [items[rank], 99].min
      end
    end
  end

  def battle
    @action_num -= 1
    eat
    hams = field_hamsters
    hams.shuffle!
    (hams.size / 2).times do |i|
      a = hams[i * 2]
      b = hams[i * 2 + 1]
      r = rand(3)
      next if r == 0
      a, b = b, a if rand(100) < 50 + b.str_plus - a.str_plus
      a.add_exp
      b.kill
    end
    hams.reject!(&:dead?)
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

  def all_hamsters_with_rank(rank)
    hamsters_with_rank(rank) + field_hamsters_with_rank(rank)
  end

  def hamsters_with_rank(rank)
    hamsters.select {|e| e.rank == rank }
  end

  def field_hamsters_with_rank(rank)
    field_hamsters.select {|e| e.rank == rank }
  end

  def create_hamster
    field_hamsters << Hamster.new
  end

  private

  def eat
    @foods -= (@hamsters.size + @field_hamsters.size) / 100 + 1
    @foods = [@foods, 0].max
  end
end

class Hamster
  Data = {
    野良ハム: {
      item: '壺',
      item_act: lambda {|c, num| c.wilds += 10 * num; num }
    },
    タネ農家: {
      item: 'タネ',
      item_act: lambda {|c, num| c.seeds += 10 * num; num }
    },
    狩人: {
      item: '弓矢',
      item_act: lambda {|c, num| c.wilds += 100 * num; num }
    },
    スミス: {
      item: '銅の剣',
      item_act: lambda {|c, num|
        hams = c.field_hamsters.first(num)
        hams.each do |ham|
          ham.str_plus = 7 * 3
        end
        hams.size
      }
    },
    ドワーフ: {
      item: '金塊',
      item_act: lambda {|c, num| c.golds += 100 * num; num }
    },
    猛獣使い: {},
    足軽: {},
    メイド: {},
    戦士: {},
    遊び人: {},
    将軍: {},
    アイドル: {},

    キング: {
      item: '平和',
    },
  }

  attr_accessor :rank, :wins, :str_plus

  def initialize(rank = 0, wins = 0, str_plus = 0)
    @rank = rank
    @wins = wins
    @str_plus = str_plus
  end

  def zip
    p0 = 48 + rank * 3 + wins
    p1 = 48 + str_plus
    [p0, p1].pack("Cc")
  end

  def self.unzip(v)
    p0, p1 = v.unpack("Cc").map {|e| e - 48 }
    Hamster.new(p0 / 3, p0 % 3, p1)
  end

  def display
    case
    when str_plus == 0 then wins.to_s
    when str_plus > 0 then "#{wins}(+#{str_plus})"
    when str_plus < 0 then "#{wins}(#{str_plus})"
    end
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
end
