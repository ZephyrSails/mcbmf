module Loader
  # read from .csv to database
  def self.filter(mod = 7, input_name = "filter_by_f_edges", operation = nil)
    file_index  = 0
    input_name  = "edges"

    count = 0
    edges_count = 0
    k_count = 0
    i_file = "data/#{input_name}.csv"

    o_file = "data/small_edges.csv"

    output = File.open(o_file, 'w')
    # until !File.exist? i_file

      input  = File.open(i_file, 'r+')
      input.each_line do |line|
        edge = line.split(",")
        edges_count += 1
        if (edge[0].to_i % 50 == mod) && (edge[1].to_i % 50 == mod)
          count += 1
          output.puts line
          if count > 1000
            count = 0
            k_count += 1
            puts k_count * 1000
          end
        end
      end
      puts edges_count

      output.close

    #   file_index += 0
    #   i_file = "data/#{input_name}/#{input_name}_#{file_index}.csv"
    # end

  end

  def self.load(input_name=0)
    file_index  = 0
    input_name  = "small_edges.csv"
    file = "data/#{input_name}"
    # file = "data/#{input_name}/#{input_name}_#{file_index}.csv"
    input       = File.open(file, 'r+')

    h_k_count = 0
    line_num = 0
    start_time = Time.now
    input.each_line do |line|
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
        print "#{h_k_count*10000}, spent #{interval}"
      end
    end
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
