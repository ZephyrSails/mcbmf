class MyMf

  def initialize(dir, mf_name, lda_input_dir, options)
    @mf_dir         = "#{dir}/#{mf_name}"
    @lda_input_dir  = lda_input_dir
    @num_topics     = options[:num_topics]
    @namespace      = options[:namespace]
    @args           = options[:args]
  end

  def run()
    arg_str = ""
    @args.each do |key, value|
      arg_str += " --#{key}=#{value}"
    end

    for i in 0...@num_topics do
      training_file   = " --training-file=#{@lda_input_dir}/edges_in_#{i}.dat"
      prediction_file = " --prediction-file=#{@mf_dir}/mf_result_in_#{i}.dat"
      file_str = "#{training_file}#{prediction_file}"

      return_str = %x{mono lib/cs/#{@namespace}.exe #{file_str} #{arg_string}}
    end
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
