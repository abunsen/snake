require 'io/console'
require 'io/wait'

class GameController
  def self.read_input
    gets.chomp
  end

  def self.alt_input
    result = ''
    $stdin.raw do |stdin|
      c = stdin.getc
      result << c
      result << 2.times.map { stdin.getc }.join if c == "\e"
    end
    result
  end

  def self.char_if_pressed
    begin
      system "stty raw -echo" # turn raw input on
      c = nil
      if $stdin.ready?
        c = $stdin.getc
      end
      c.chr if c
    ensure
      system "stty -raw echo" # turn raw input off
    end
  end

  def self.accept_move
    c = self.char_if_pressed

    case c
    when " "
      "start"
    when "w"
      "up"
    when "s"
      "down"
    when "a"
      "left"
    when "d"
      "right"
    when "\u0003"
      puts "exiting..."
      exit 0
    else
      nil
    end
  end
end

class SnakeGame
  attr_accessor :snake, :apple
  @@valid_movements =["up", "right", "down", "left"]

  def initialize
    @window_size = [20, 80]
    @snake = {body: [], direction: "left"}
    @apple = [rand(0..@window_size.first), rand(0..@window_size.last)] 
    reset_grid
  end 

  def place_apple
    @grid[@apple.first][@apple.last] = "ó"
  end

  def replace_apple
    @apple = [rand(0..@window_size.first), rand(0..@window_size.last)]
    place_apple
  end

  def change_snake_direction(dir)
    @snake[:direction] = dir if @@valid_movements.include? dir
  end

  def create_snake
    i = rand(0..@window_size.last)
    row = rand(0..@window_size.first)
    5.times do
      @snake[:body] << [row, i]
      i += 1
    end
  end

  def draw_snake
    # handle head
    head = @snake[:body][0]
    @grid[head.first][head.last] = "%"

    # now body
    @snake[:body][1..-1].each do |coord|
      @grid[coord.first][coord.last] = "*"
    end
  end

  def move_snake
    args = {
      "up" => [0, lambda { |co| co.first-1 }],
      "right" => [1, lambda { |co| co.last+1 }],
      "down" => [0, lambda { |co| co.first+1 }],
      "left" => [1, lambda { |co| co.last-1 }],
    }

    # head needs to move according to rules above
    head = @snake[:body][0]
    next_coord = Marshal.load(Marshal.dump(head))
    head.send(:"[]=", args[@snake[:direction]].first, args[@snake[:direction]].last.call(head))

    # then body takes the place of item before it
    @snake[:body][1..-1].each_with_index do |coord, i|
      new_next_coord = Marshal.load(Marshal.dump(coord))
      coord[0] = next_coord.first
      coord[1] = next_coord.last
      next_coord = new_next_coord
    end
  end

  def draw_grid
    @grid.each do |row|
      puts "|#{row.join}|"
    end
  end

  def grow_snake
    # add new coordinate to snake body
    # @snake[:body] << [@snake[:body], ]
    puts "we should grow!"
  end

  def reset_grid
    @grid = []
    (@window_size.first+1).times do 
      row = []
      @window_size.last.times do 
        row << " "
      end
      @grid << row
    end
  end

  def is_playable
    true
  end

  def apple_is_eaten
    @snake[:body].include? @apple
  end
end

game = SnakeGame.new

# listen for input
Thread.new do
  while game.is_playable do
    move = GameController.accept_move
    game.change_snake_direction(move)
    sleep 1.0/2
  end
end

# puts "Direction is #{game.snake[:direction]}"

# run the game
game.create_snake
while game.is_playable
# 2.times do
  system "clear" or system "cls"
  game.reset_grid
  game.replace_apple
  until game.apple_is_eaten do   
    puts "Direction is #{game.snake[:direction]}"
    game.place_apple
    game.draw_snake
    game.move_snake
    puts "xxx"
    game.draw_grid
    game.reset_grid
    sleep 1.0/2
    system "clear" or system "cls"
  end
  game.grow_snake
end

# move = GameController.alt_input
# puts move