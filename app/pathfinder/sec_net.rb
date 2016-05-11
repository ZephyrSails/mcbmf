class SecNet
  attr_accessor :f_net, :g_net, :user

  def initialize(dir=nil)
    load_file(dir) unless dir==nil
    @depth = 0
    # load(dir)
  end

  def build_user_stack
    @user = []
    length = [@f_net.length, @g_net.length].max
    for i in 0...length do
      @user << i if !followees_of(i).empty? or !followers_of(i).empty?
    end
  end

  def random_user_stack(percent)
    top_n = @user.length * percent
    @user.shuffle[0...top_n]
  end

  def quick_subset(percent, threshold=10)
    build_user_stack
    puts "stack built"

    h_k_count = 0
    line_num = 0
    start_time = Time.now
    @user.each do |user|
      line_num += 1
      if line_num > 10000
        line_num = 0
        h_k_count += 1
        puts "#{h_k_count*10000}, spent #{Time.now - start_time}"
        start_time = Time.now
      end

      next unless rand <= percent

      followees_of(user).each do |followee|
        delete_edge(user, followee)
      end
      followers_of(user).each do |follower|
        delete_edge(follower, user)
      end
    end

    hard_filter(threshold)
  end

  def subset(percent, threshold=10)
    build_user_stack
    puts "stack built"
    users = random_user_stack(percent)
    puts "user shuffled"
    h_k_count = 0
    line_num = 0
    start_time = Time.now

    @user.each do |user|

      if !(users.include?(user))
        followees_of(user).each do |followee|
          delete_edge(user, followee)
        end
        followers_of(user).each do |follower|
          delete_edge(follower, user)
        end
      else
        followees_of(user).each do |followee|
          delete_edge(user, followee) unless users.include? followee
        end
        followers_of(user).each do |follower|
          delete_edge(follower, user) unless users.include? follower
        end
      end
      line_num += 1
      if line_num > 10000
        line_num = 0
        h_k_count += 1
        puts "#{h_k_count*10000}, spent #{Time.now - start_time}"
        start_time = Time.now
      end
    end

    hard_filter(threshold)
  end

  def split_for_test(dir, options)
    test_rate   = options[:test_rate]
    test_friend = options[:test_friend?]
    test_file   = File.open(dir, 'w')

    h_k_count = 0
    line_num = 0
    start_time = Time.now

    @f_net.each_with_index do |followees, follower|
      next if !followees

      followees -= friends_of(follower) unless test_friend

      next if followees.empty?

      followees.each do |followee|
        if (rand < test_rate)
          test_file.puts "#{follower},#{followee}"
          delete_edge(follower, followee)
        end

        line_num += 1
        if line_num > 1000000
          line_num = 0
          h_k_count += 1
          puts "#{h_k_count*1000000}, spent #{Time.now - start_time}"
          start_time = Time.now
        end
      end

    end

    test_file.close
  end

  #
  # Calculate how many followers(user) contained in a sec_net
  #
  def count_user
    count = 0
    @f_net.each do |followees|
      count += 1 unless !followees or followees.empty?
    end
    count
  end

  #
  # Calculate how many followees(item) contained in a sec_net
  #
  def count_item
    count = 0
    @g_net.each do |followers|
      count += 1 unless !followers or followers.empty?
    end
    count
  end

  #
  # Calculate how many relation(edge) contained in a sec_net
  #
  def count_edge
    count = 0
    @f_net.each_with_index do |followees, follower|
      count += followees_of(follower).count
    end
    count
  end

  #
  # Calculate sparsity before you throw this sec_net to mf
  #
  def count_sparsity
    (1 - count_edge.to_f/(count_user*count_item))*100
  end

  def hard_filter(threshold=10)
    h_k_count = 0
    line_num = 0

    start_time = Time.now
    for follower in 0..@f_net.length do
    # @f_net.each_with_index do |followees, follower|
      hard_cut_edge(follower, threshold)
      line_num += 1
      if line_num > 1000000
        line_num = 0
        h_k_count += 1
        puts "#{h_k_count*1000000}, spent #{Time.now - start_time}"
        start_time = Time.now
      end
    end
    count_edge
  end

  def hard_cut_edge(user, threshold)

    g_length = followees_of(user).length
    f_length = followers_of(user).length
    @depth += 1
    # puts "#{@depth += 1}, #{g_length}, #{f_length}"
    if (f_length == 0 && g_length == 0) or @depth > 1000
      @depth -= 1
      return
    end

    if f_length < threshold || g_length < threshold

      for i in 0...followees_of(user).count do
        followee = followees_of(user).first
        unless !followee
          # puts followee
          delete_edge(user, followee)
          hard_cut_edge(followee, threshold)
        end
      end

      for i in 0...followers_of(user).count do
        follower = followers_of(user).first
        unless !follower
          # puts follower
          delete_edge(follower, user)
          hard_cut_edge(follower, threshold)
        end
      end
    end

    @depth -= 1
  end

  def filter(threshold=10)
    h_k_count = 0
    line_num = 0

    start_time = Time.now
    for follower in 0..@f_net.length do
    # @f_net.each_with_index do |followees, follower|
      cut_edge(follower, threshold)
      line_num += 1
      if line_num > 1000000
        line_num = 0
        h_k_count += 1
        puts "#{h_k_count*1000000}, spent #{Time.now - start_time}"
        start_time = Time.now
      end
    end
    count_edge
  end

  #
  # Cut user who has less edges than threshold
  # user.followees_of 515007
  #
  def cut_edge(user, threshold)
    edge_count = followees_of(user).length + followers_of(user).length
    # @depth += 1
    # puts "#{@depth}, #{edge_count}" if edge_count != 0
    if edge_count == 0
      # @depth -= 1
      return
    end

    if edge_count < threshold
      for i in 0...followees_of(user).count do
        followee = followees_of(user).first
        unless !followee
          # puts followee
          delete_edge(user, followee)
          cut_edge(followee, threshold)
        end
      end
      for i in 0...followers_of(user).count do
        follower = followers_of(user).first
        unless !follower
          # puts follower
          delete_edge(follower, user)
          cut_edge(follower, threshold)
        end
      end
      # followees_of(user).each do |followee|
      #   delete_edge(user, followee)
      #   # cut_edge(followee, threshold)
      # end
      # followers_of(user).each do |follower|
      #   delete_edge(follower, user)
      #   # cut_edge(follower, threshold)
      # end
      # puts "#{user}, #{followees_of(user).length + followers_of(user).length}"
      # puts followees_of(user).length + followers_of(user).length
    end
    # @depth -= 1
  end

  def output_to(dir)
    o_file = File.open(dir, 'w')

    @f_net.each_with_index do |followees, follower|
      next if !followees
      followees.each do |followee|
        o_file.puts "#{follower},#{followee}"
      end
    end
    o_file.close
  end

  def delete_edge(follower, followee)
    @f_net[follower].delete(followee)
    @g_net[followee].delete(follower)
  end

  def get_followees_matrix(options)
    g_arr = []
    f_arr = []

    @f_net.each_with_index do |followees, user|
      # next if !followees
      next if !followees
      followees -= friends_of(user) unless options[:mutual_lda]
      next if followees.empty? or (options[:more_than] != nil and followees.length <= options[:more_than])

      g_arr << followees
      f_arr << user
    end

    [f_arr, g_arr]
  end

  def followees_of(follower_id)
    # [] if @f_net[follower_id]
    @f_net[follower_id] == nil ? [] : @f_net[follower_id]
  end

  def followers_of(followee_id)
    @g_net[followee_id] == nil ? [] : @g_net[followee_id]
  end

  def friends_of(user_id)
    followers_of(user_id) & followees_of(user_id)
  end

  def load_file(dir, mod=nil, mod_offset=nil)
    input  = File.open(dir, 'r+')

    h_k_count = 0
    line_num = 0


    start_time = Time.now
    # self = []
    @f_net = []
    @g_net = []
    input.each_line do |line|
      edge = line.split(",").map { |u| u.to_i }
      # if mod!=0
      next unless !mod or (edge[0]%mod==mod_offset and edge[1]%mod==mod_offset)

      if @f_net[edge[0]] == nil
        @f_net[edge[0]] = [edge[1]]
        # self[edge[0]] = UserArr.new(self, edge[1])
      else
        @f_net[edge[0]] << edge[1]
      end

      if @g_net[edge[1]] == nil
        @g_net[edge[1]] = [edge[0]]
        # self[edge[0]] = UserArr.new(self, edge[1])
      else
        @g_net[edge[1]] << edge[0]
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

  end

end
