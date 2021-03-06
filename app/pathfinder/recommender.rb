class Recommender
  attr_accessor :dir, :mf_output_path, :f_c, :num_topics, :recommend_num, :hash

  def initialize(dir, mf_output_path, options)
    @dir            = dir
    @mf_output_path = mf_output_path
    @num_topics     = options[:lda_options][:num_topics]
    @f_c            = load_f_c
    @recommend_num  = options[:recommend_options][:recommend_num]
  end

  def load_f_c
    f_c = []
    for i in 0...@num_topics do
      topic = []
      file = File.open("#{dir}/lda/output_user/f_c_#{i}.dat")
      file.each do |line|
        topic << line.split(":").map.with_index { |str,at| at==0 ? str.to_i : str.to_f }
      end
      file.close
      f_c << topic
    end
    f_c
  end

  def run(k=5)
    @hash = sum_score

    result_file = File.open("#{@dir}/result_edges.dat", "w")

    # score_hash = recommend_based_on_score
    # score_hash.each do |line|
    #   result_file.puts line[0]
    # end

    hash.each do |key, value|
      # .sort_by {|k, v| v}.reverse
      # value.sort_by {|k, v| v}.reverse.transpose[0].join(",")
      result_file.puts "#{key}:#{value.sort_by {|k, v| v}.reverse.transpose[0][0...k].join(",")}" if value.count >= k
      # result_file.puts "#{key}:#{value.to_a.transpose[0][0...k].join(",")}"
    end

    result_file.close
  end

  def recommend_based_on_score
    score_hash = {}
    @hash.each do |follower, followees|
      followees.each do |followee, score|
        score_hash["#{follower},#{followee}"] = score
      end
    end
    score_hash.sort_by {|k,v| v}.reverse
  end

  def sum_score
    hash = Hash.new
    for i in 0...@num_topics do
      hash = decode_to_hash("#{@mf_output_path}/mf_result_in_#{i}.dat", @f_c[i].to_h, hash)
    end
    hash
  end

  #
  # Decode from file to hash.
  # File format looks like:
  #   6457	[45957:6.545828,1208557:5.545657,184207:4.252441,1956557:3.941712,655157:3.693564]
  #   6907	[45957:6.542907,184207:4.216556,1956557:3.973593,655157:3.727264,1971557:3.590944]
  #   ...
  # Input:
  # => filename.
  # => hash: accumulate the process result of multiple files to one hash.
  # => f_c_weight: weight used to represent Pr(c|f)
  # Output:
  # => hash, after decode of one file, add the result to inputing hash.
  #
  def decode_to_hash(dir, f_c_weight, hash)
    file = File.open(dir, "r")

    hash = Hash.new(0) if hash == {}

    file.each do |line|
      follower = line[/^(.*?)\t/, 1].to_i
      followees = line[/\[(.*?)\]/, 1].split(/[:,\,]/)

      hash[follower] = Hash.new(0) if hash[follower] == 0

      # follower_hash = Hash.new(0) if
      # puts followees
      followees.each_slice(2) do |a|
        # puts a
        # puts a[0]
        # puts a[1]
        # puts "follower: #{follower}"
        # puts "f_c_weight[follower] #{f_c_weight[follower]}"

        hash[follower][a[0].to_i] += a[1].to_f * f_c_weight[follower]
      end
      # hash[follower] = follower_hash
    end
    file.close
    hash
  end

end
