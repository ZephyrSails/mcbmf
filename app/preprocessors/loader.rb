module Loader

  #
  # Read from .csv to database.
  # Input:
  #   load_options:
  #   => :source, :string   => Data source file.
  #   => :mod, :int         => How many data been load from original data,
  #                            Higher the mod, less the data loaded.
  #   => :mod_offset, int   => Decide mod_offset, not very important.
  #   => :test_rate, :float => proportion of data used as test data.
  # Output:
  #   dir/edges.dat: Include all edges used in this test instance
  #
  def self.filter(dir, options)

    mod          = options[:mod]
    mod_offset   = options[:mod_offset]
    # g_num_thresh = options[:g_num_thresh]
    input  = File.open(options[:source], 'r+')
    output = File.open("#{dir}/source.dat", 'w')

    # Used to count.
    count = 0
    edges_count = 0
    k_count = 0

    # until !File.exist? i_file

    input.each_line do |line|
      edge = line.split(",")
      # edges_count += 1
      if (edge[0].to_i % mod == mod_offset) && (edge[1].to_i % mod == mod_offset)
        edges_count += 1
        count += 1
        output.puts line


        if count > 1000
          count = 0
          k_count += 1
          puts k_count * 1000
        end
      end
    end
    puts "Filter result: #{edges_count} edges survived."

    output.close
  end

  def self.filter_by_followees(dir, options)

    g_num_thresh = options[:g_num_thresh]
    input  = File.open(options[:source], 'r+')
    output = File.open("#{dir}/edges_#{g_num_thresh}.dat", 'w')

    # Used to count.
    count       = 0
    edges_count = 0
    k_count     = 0

    followees_group = [nil, []]

    input.each_line do |line|
      edge = line.split(",")

      if edge[0] == followees_group[0]
        followees_group[1] << edge[1]
      else
        if followees_group[1].count > g_num_thresh
          followees_group[1].each do |g|
            output.puts "#{followees_group[0]},#{g}"
          end
        end
        followees_group = [edge[0], [edge[1]]]
      end
      edges_count += 1
      count += 1
      if count > 10000
        count = 0
        k_count += 1
        puts k_count * 10000
      end
    end
    puts "Filter result: #{edges_count} edges survived."

    output.close
  end

  def self.load_to_array(dir)
    input  = File.open(dir, 'r+')

    arr = []
    h_k_count = 0
    line_num = 0
    start_time = Time.now
    # arr = []
    input.each_line do |line|
      edge = line.split(",").map { |u| u.to_i }

      if arr[edge[0]] == nil
        arr[edge[0]] = [edge[1]]
      else
        arr[edge[0]] << edge[1]
      end

      line_num += 1
      if line_num > 1000000
        line_num = 0
        h_k_count += 1
        puts "#{h_k_count*1000000}, spent #{Time.now - start_time}"
        start_time = Time.now

      end
    end
    input.close
    arr
  end

  # start_at = Time.now
  # # arr = Array.new(10000000);
  # arr[91316661] = 1
  # puts "spents #{Time.now - start_at}"


  #
  # Load data to ActiveRecord database.
  # Input:
  #   dir/edges.dat: Data file, generated by Loader.filter.
  #   file_name: Default as edges.dat, as Output in Loader.filter, but you can
  #              change it to whatever you like.
  # Output:
  #   ActiveRecord in rails database: edges, nodes, modulized for process.
  #                                   Loaded from dir/edges.dat.
  #
  def self.load_data(dir, file_name="edges.dat", start_at=0)
    # test_rate   = options[:test_rate]
    input       = File.open("#{dir}/#{file_name}", 'r+')
    # test_file   = File.open("#{dir}/test_edges.dat", 'w')

    # Used to count time and edges.
    h_k_count = 0
    line_num = 0
    start_time = Time.now

    input.each_line do |line|
      next if (h_k_count*10000 + line_num) < start_at
      # if rand > test_rate
      edge = line.split(",")

      follower = User.get!(edge[0].to_i)
      followee = User.get!(edge[1].to_i)

      follower.follow!(followee)

      line_num += 1
      if line_num > 10000
        line_num = 0
        h_k_count += 1
        interval = (Time.now - start_time)
        start_time = Time.now
        puts "#{h_k_count*10000}, spent #{interval}"
      end
      # else
      #   test_file.puts line
      # end
    end
    input.close
  end

  #
  # Split some data for test
  # Input:
  # => ActiveRecord database
  # => :test_rate, :float => proportion of data used as test data.
  # => :test_friend?, :boolean => false if you do not want to test
  #                               bidirectional relationship. In other words,
  #                               only the unidirectional relationships will be
  #                               tested in this way.
  # Output:
  # => dir/test_edges.dat: Edges removed from database, stored as file.
  #                        Will be used to evaluate the result
  #
  def self.split_for_test(dir, options)
    test_rate     = options[:test_rate]
    test_friend   = options[:test_friend?]
    test_file     = File.open("#{dir}/test_edges.dat", 'w')

    Edge.all.each do |edge|
      follower = edge.follower
      followee = edge.followee

      if (rand < test_rate)
        if test_friend or (!test_friend and !(followee.following?(follower)))
          test_file.puts "#{follower.id},#{followee.id}"
          Edge.delete edge
        end
      end

      # if test_friend? # Test everyone
      #   if rand < test_rate
      #     test_file.puts "#{follower},#{followee}"
      #     Edges.delete edge
      #   end
      #
      # else # Don't test friends, only unidirectional
      #   if !(followee.following?(follower)) # Unidirectional
      #     if rand < test_rate
      #       test_file.puts "#{follower},#{followee}"
      #       Edges.delete edge
      #     end
      #   end
      #
      # end

    end
    test_file.close
  end

  def self.add_index_to_users
    index = 0
    User.all.each do |user|
      if (user.followees - user.friends).length != 0
        user.update(index: index)
        index += 1
        puts index
      end
    end
  end

end
