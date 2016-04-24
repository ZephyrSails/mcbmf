class MyMf

  def initialize(dir, mf_name, lda_output_dir, options)
    @mf_dir         = "#{dir}/#{mf_name}"
    Dir.mkdir "#{@mf_dir}" unless File.exists? "#{@mf_dir}"
    @lda_output_dir  = lda_output_dir
    @num_topics     = options[:lda_options][:num_topics]
    @namespace      = options[:mf_options][:namespace]
    @args           = options[:mf_options][:args]
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
