require 'neography'

namespace :gems do
  Width = `tput cols`.to_i

  def progress done, total, prefix=''
    prefix   += ' ' unless prefix.empty?
    percent   = done.to_f / total
    available = Width - 2 - prefix.length
    full      = (available * percent).to_i
    empty     = available - full
    prefix + '[' + '=' * full + ' ' * empty + ']'
  end


  desc 'Seed initial fetch data'
  task :start do
    gems = `gem list --remote`.lines.map do |line|
      name, version = line.split ' '
      if line =~ /^(\S+) \(([\d.]+).*\)$/
        GemData.where(name: $1, version: $2).first_or_create!
      else
        puts line
      end
    end
  end


  desc 'Get info data for gems'
  task :info => :environment do
    GemData.("spec = 'null'").find_each do |gem|
      puts gem.name
      delay = 1

      begin
        spec = Gems.info gem.name
      rescue => e
        puts "#{e} ... Retrying in #{delay}"
        sleep delay
        delay *= 2 unless delay > 5.minutes
        retry
      end

      gem.update spec: spec
    end
  end


  desc 'Populate Neo4j graph from saved gem specs'
  task :graph => :environment do
    raise "There are unspec'd gems" if GemData.where("spec = 'null'").exists?

    neo = ActiveNode::Neo.db

    puts 'Cleaning up existing nodes'
    %w( Gem Author ).each do |label|
       neo.execute_query "MATCH (n:#{label})-[r]-() DELETE n,r"
    end

    puts 'Building indexes'
    neo.execute_query "CREATE INDEX ON :Gem(name)"
    neo.execute_query "CREATE INDEX ON :Author(name)"

    scope = GemData.find_each
    count = scope.count

    batch = []

    puts 'Populating graph nodes'
    scope.each_with_index do |g,i|
      print "\r#{progress i, count}"

      s = g.spec

      batch.push [ :execute_query,
        "MERGE (a:Gem {name:{name}})", { name: g.name } ]
      g.spec['authors'].split(',').each do |auth|
        batch.push [ :execute_query,
          "MERGE (a:Author {name:{name}})", { name: auth } ]
      end

      if batch.length > 100
        neo.batch *batch
        batch.clear
      end
    end

    neo.batch(*batch) if batch.any?


    puts 'Building relations'
    scope.each_with_index do |g,i|
      print "\r#{progress i, count}"

      spec  = g.spec
      auths = spec.delete 'authors'
      deps  = spec.delete 'dependencies'

      deps['runtime'].each do |dep|
        batch.push [ :execute_query,
          "MATCH (a:Gem {name:{name}}), (b:Gem {name:{dep_name}})
           MERGE (a)-[:depends]->(b)",
          { name: g.name, dep_name: dep['name'] } ]
      end

      deps['development'].each do |dep|
        batch.push [ :execute_query,
          "MATCH (a:Gem {name:{name}}), (b:Gem {name:{dep_name}})
           MERGE (a)-[:dev_depends]->(b)",
          { name: g.name, dep_name: dep['name'] } ]
      end

      auths.split(',').each do |auth|
        batch.push [ :execute_query,
          "MATCH (a:Author {name:{auth}}), (b:Gem {name:{gem}})
           MERGE (a)-[:wrote]->(b)",
          { auth: auth, gem: g.name } ]
      end

      if batch.length > 100
        neo.batch *batch
        batch.clear
      end
    end

    # Flush the last batch
    neo.batch(*batch) if batch.any?
  end

end
