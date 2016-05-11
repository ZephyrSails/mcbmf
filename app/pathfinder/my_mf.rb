class MyMf
  attr_accessor :dir, :mf_dir, :lda_output_dir, :num_topics, :namespace, :args

  def initialize(dir, mf_name, lda_output_dir, options)
    @dir            = dir
    @mf_dir         = "#{dir}/#{mf_name}"
    Dir.mkdir "#{@mf_dir}" unless File.exists? "#{@mf_dir}"
    @lda_output_dir  = lda_output_dir
    @num_topics     = options[:lda_options][:num_topics]
    @namespace      = options[:mf_options][:namespace]
    @args           = options[:mf_options][:args]
    @mutual_mf      = options[:mf_options][:mutual_mf]
  end

  def run()
    arg_str = ""
    @args.each do |key, value|
      arg_str += " --#{key}=#{value}"
    end

    # @eva

    for i in 0...@num_topics do
      training_file   = " --training-file=#{@lda_output_dir}/edges_in_#{i}.dat"
      prediction_file = " --prediction-file=#{@mf_dir}/mf_result_in_#{i}.dat"
      file_str = "#{training_file}#{prediction_file}"

      puts "mono lib/cs/#{@namespace}.exe #{file_str} #{arg_str}"
      return_str = %x{mono lib/cs/#{@namespace}.exe #{file_str} #{arg_str}}
    end

    return @mf_dir
  end

  #
  # Input:
  # dir/lda/output_user/g_c & f_c
  #
  def preprocess(user)
    output_dir = "#{@lda_output_dir}"
    input_dir = "#{@dir}/lda/output_user"
    Dir.mkdir "#{output_dir}" unless File.exists? "#{output_dir}"

    for i in 0...@num_topics do
      f_c_file = File.open("#{input_dir}/f_c_#{i}.dat", "r+")
      f_c = []
      f_c_file.each_line do |line|
        f_c_pair = line.split(":")
        # f_c << [f_c_pair[0].to_i, f_c_pair[1].to_f]
        f_c << f_c_pair[0].to_i
      end
      f_c_file.close

      g_c_file = File.open("#{input_dir}/g_c_#{i}.dat", "r+")
      g_c = []
      g_c_file.each_line do |line|
        g_c << line.to_i
      end
      g_c_file.close

      o_file = File.open("#{output_dir}/edges_in_#{i}.dat", 'w')
      # doc_list = f_c.transpose.first
      # doc_list = f_c
      # puts "f_c: #{f_c.count}, g_c #{g_c.count}"
      # adsfdsfasdfasd
      f_c.each do |doc|
        # puts "user.followees_of(doc): #{user.followees_of(doc)}, g_c[i]: #{g_c[i].count}"
        # puts doc
        followees = user.followees_of(doc) & g_c
        # puts followees
        followees -= user.friends_of(doc) if @mutual_mf == false
        # followees = User.find_by(id: doc).followees.pluck(:id) & @g_c[i]
        followees.each do |followee|
          # puts "#{doc},#{followee}"
          # dasfdsaadsfasd
          o_file.puts "#{doc},#{followee}"
        end
      end
      o_file.close
    end

    # load_lda_user()
    # output_lda()
  end

  #
  # Save the result of lda to file.
  #
  def output_lda()
    output_path = "#{@lda_output_dir}"
    Dir.mkdir "#{output_path}" unless File.exists? "#{output_path}"

    @f_c.each_with_index do |community, c_index|
      o_file = File.open("#{output_path}/edges_in_#{c_index}.dat", 'w')

      doc_list = community.transpose.first
      doc_list.each do |doc|
        followees = @user.followees_of(doc) & @g_c[c_index]
        followees -= @user.friends_of(doc) if @options[:mutual_mf] == false
        # followees = User.find_by(id: doc).followees.pluck(:id) & @g_c[c_index]
        followees.each do |followee|
          o_file.puts "#{doc},#{followee}"
        end
      end

      o_file.close
    end
    output_path
  end

  #
  # This function is never used, use Evaluater instead
  #
  def eva(return_str)
    # "training data: 2426 users, 5115 items, 15621 events, sparsity 99.87412\ntest data:     812 users, 957 items, 1715 events, sparsity 99.7793\nBPRMF num_factors=10 bias_reg=0 reg_u=0.0025 reg_i=0.0025 reg_j=0.00025 num_iter=30 learn_rate=0.05 uniform_user_sampling=True with_replacement=False update_j=True \ntraining_time 00:00:00.3930830 AUC 0.76095 prec@5 0.02635 recall@5 0.11289 NDCG 0.23057 num_items 5549 num_lists 812 testing_time 00:00:02.0510760\n"
    eva_hash = {}
    training_data = str[/training data: (.*?)\n/, 1].strip.split(" ")
    test_data = str[/test data: (.*?)\n/, 1].strip.split(" ")
    eva_hash[:users_num] = training_data[0].to_i + test_data[0].to_i
    eva_hash[:items_num] = training_data[2].to_i + test_data[2].to_i
    eva_hash[:edges_num] = training_data[4].to_i + test_data[4].to_i
    eva_hash[:sparsity]  = training_data[7]

  end

  # def call_mymedialite(arg_string)
  #   output_dir  = "#{@dir}/mf_output"
  #   recommender = options[:recommender]
  #   args        = options[:args]
  #
  #
  #
  #   %x{mono lib/cs/item_recommendation.exe --training-file=#{} #{arg_string}}
  #   # %x{mono lib/cs/item_recommendation.exe --training-file=#{output_path}/edges_in_0.dat --test-ratio=0.2 --recommender=BPRMF}
  #   # %{mono item_recommendation.exe --help}
  #   # (%x{mono #{File.dirname(__FILE__)}/encrypt.exe #{string}}).split("\n")
  # end

  #
  # Just a test
  #   2.2.3 :355 >   tinker[0].sum
  #   0.8920800000000001
  #   2.2.3 :356 > tinker[1].sum
  #   0.9011
  #   2.2.3 :357 >
  # The answer is no good, yet
  #
  def vs
    tinker = [[], []]
    for i in 0..9 do
      prec1 = (%x{mono lib/cs/item_recommendation.exe --training-file=data/atlas/lda1/output/edges_in_#{i}.dat --test-ratio=0.2 --recommender=BPRMF})[/prec@5 (.*?) num/, 1].to_f
      prec3 = (%x{mono lib/cs/item_recommendation.exe --training-file=data/atlas/lda3/output/edges_in_#{i}.dat --test-ratio=0.2 --recommender=BPRMF})[/prec@5 (.*?) num/, 1].to_f
      puts "#{i}: prec1: #{prec1}, prec3: #{prec3}"
      tinker[0] += [prec1]
      tinker[1] += [prec3]
    end
    tinker
  end

end
