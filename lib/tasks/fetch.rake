namespace :fetch do
  Width = `tput cols`.to_i

  def progress done, total, prefix=''
    prefix   += ' ' unless prefix.empty?
    percent   = done.to_f / total
    available = Width - 2 - prefix.length
    full      = (available * percent).to_i
    empty     = available - full
    prefix + '[' + '=' * full + ' ' * empty + ']'
  end

  desc 'Fetch a batch of gem dependencies from RubyGems'
  task :dependencies => :environment do
    GemData.unfetched.find_in_batches batch_size: 250 do |gems|
      deps = Gems.dependencies *gems.map(&:name)
      deps_hash = deps.each_with_object({}) do |dep, h|
        h[ [dep[:name], dep[:number]] ] = dep[:dependencies]
      end

      total = GemData.unfetched.count.to_s
      count = gems.count
      gems.each_with_index do |gem, i|
        print "\r#{progress(i+1, count, total)}"
        deps = deps_hash[ [gem.name, gem.version] ]
        gem.update fetched: true, dependencies: deps
      end
    end
  end

  desc 'Get info data for gems'
  task :info => :environment do
    GemData.where("spec = 'null'").find_each do |gem|
      puts gem.name
      spec = Gems.info gem.name
      gem.update spec: spec
    end
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
end
