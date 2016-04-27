class SecNet

  def initialize(dir)
    load(dir)
  end

  def followees(follower_id)
    @f_net[follower_id]
  end

  def followers(followee_id)
    @g_net[followee_id]
  end

  def friends(user_id)
    followers(user_id) & followees(user_id)
    # @f_net[user_id].select { |g| @f_net[g].include? user_id }
  end

  def load(dir)
    input  = File.open(dir, 'r+')

    h_k_count = 0
    line_num = 0
    start_time = Time.now
    # self = []
    @f_net = []
    @g_net = []
    input.each_line do |line|
      edge = line.split(",").map { |u| u.to_i }

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
  end

end
