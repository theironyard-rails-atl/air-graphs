namespace :graph do
  desc 'Reset graph to the famous seven bridges of Konigsberg'
  task :konigsberg => :environment do
    Land.delete_all

    north, south, east, west = %w(North South East West).map do |direction|
      Land.create! name: direction
    end

    north.connect! west, name: :a
    north.connect! west, name: :b
    north.connect! east, name: :c

    south.connect! west, name: :d
    south.connect! west, name: :e
    south.connect! east, name: :f

    east.connect!  west, name: :g
  end
end
