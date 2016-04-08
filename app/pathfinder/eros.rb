module Eros
  def self.common_friends
    o_file = "data/common_friends_count.csv"
    output = File.open(o_file, 'w')

    User.all.each do |user|
      record_string = "#{user.id}="
      record_array = []
      user.friends_of_friends.each do |fof|
        common_friends_count = (user.friends & fof.friends).count
        record_array << "#{fof.id}:#{common_friends_count}" if common_friends_count > 1
        # .update(common_friends_count: (edge.follower.friends & edge.followee.friends).count)
        # edge = Edge.find_by(followee_id: user.id, follower_id: fof.id)
        # edge_inverge = Edge.find_by(follower_id: user.id, followee_id: fof.id)

        # Edge.new() if !edge
      end
      record_string += record_array.join(",")
      output.puts record_string
      puts user.id
      # puts user.id
    end
    output.close

    # Edge.all.each do |edge|
    #   # reverse_edge = Edge.find_by(followee_id: edge.follower_id, follower_id: edge.followee_id)
    #   # next if !reverse_edge
    #   if edge.followee.is_friend_of? edge.follower
    #     edge.update(common_friends_count: (edge.follower.friends & edge.followee.friends).count)
    #     puts edge.id
    #   end
    #   # reverse_edge
    #   # edge.follower
    # end
  end
end
