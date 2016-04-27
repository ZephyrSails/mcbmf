class UserNetwork < Array

  def load(dir)
    input  = File.open(dir, 'r+')

    h_k_count = 0
    line_num = 0
    start_time = Time.now
    # self = []
    input.each_line do |line|
      edge = line.split(",").map { |u| u.to_i }

      if self[edge[0]] == nil
        self[edge[0]] = [edge[1]]
        # self[edge[0]] = UserArr.new(self, edge[1])
      else
        self[edge[0]] << edge[1]
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

  def followes(follower_id)
    self[follower_id]
  end

end
