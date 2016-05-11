class Processor
  attr_accessor :group_name, :dir, :options, :f_c, :lda_output_path, :mf_output_path
  attr_accessor :mylda, :my_mf, :recom, :eva, :user

  #
  # Create a test instance
  # Data file dir structure:
  # /data/group_name/ (dir)
  # => edges.dat
  # => test_edges.dat
  # => result_edges.dat
  # => lda/
  #    => lda_ap.dat
  #    => lda_vocab.dat
  #    => output/
  #       => edges_in_0.dat
  #          ...
  #       => edges_in_n.dat
  # => mf/
  #   => output/
  #      => prediction.dat
  #         ...
  #      => prediction.dat
  #
  # Options:
  #   load_options:
  #   => :source, :string   => Data source.
  #   => :mod, :int         => How many data been load from original data,
  #                            Higher the mod, less the data loaded.
  #   => :mod_offset, int   => Decide mod_offset, not very important.
  #   => :test_rate, :float => proportion of data used as test data.
  #   => :test_friend?, :boolean => false if you do not want to test
  #                                bidirectional relationship, in other words,
  #                                only the unidirectional relationships will be
  #                                tested in this way.
  #
  #   lda_options:
  #   => :minus_friends => Do not consider bidirectional relationship in lda.
  #   => :more_than     => Do not include this document unless it has more words
  #                        than this value.
  #   => :f_c_thresh    => Threshold for Pr(z|d), if Pr(z|d) surpass this value,
  #                        we put this follower(d) is within this community(z).
  #   => :num_topics    => How many topic we want to discover.
  #   => :g_c_base      => Integer used to decide how many followees(words) we
  #                        want to put in each communities. E.g :g_c_base=>2
  #                        roughly means we want to dispatch one followees to 2
  #                        comunities in average.
  #
  def initialize(group_name)
    # @sec_net      = sec_net
    # @group_name   = options
    @dir          = "data/#{group_name}"
    @options      = load_options()

    Dir.mkdir "#{@dir}" unless File.exists? "#{@dir}"
  end

  def store_options
    File.open("#{@dir}/options.yml", "w") do |file|
      file.write @options.to_yaml
    end
  end

  def load_options
    @options = YAML::load_file("#{@dir}/options.yml")
    # @options = options.inspect
  end

  def run()
    start_at = Time.now
    preprocess()
    lda_process()
    mf_process()
    recommend()
    evaluate()
    puts "total spent: #{Time.now - start_at}"
  end

  #
  # Load file, split file, preprocess, etc..
  #
  def preprocess()
    # forget about preprocess, you only need SecNet

    @user = SecNet.new()
    if @options[:load_options][:reload]
      Loader.filter(@dir, @options[:load_options])
      @user.load_file("#{@dir}/source.dat") #
      @user.split_for_test("#{@dir}/test_edges.dat", @options[:load_options])
      @user.output_to("#{@dir}/edges.dat")
    else
      @user.load_file("#{@dir}/edges.dat")
    end

    # pro.user = SecNet.new()
    # pro.user.load_file("#{pro.dir}/source.dat") #
    # pro.user.split_for_test("#{pro.dir}/test_edges.dat", pro.options[:load_options])
    # pro.user.output_to("#{pro.dir}/edges.dat")


    # Loader.filter(@dir, @options[:load_options])
    # Loader.load_data(@dir)
    # Loader.split_for_test(@dir, @options[:load_options])
  end

  #
  # Lda is used to dispatch follower and followees to comunities.
  #
  def lda_process()
    # Eros.output_friends("#{@dir}")
    # options = { minus_friends: true, more_than: 0 }

    # f_arr, user_arr = User.get_followees_matrix(@options[:lda_options])
    # f_arr, user_arr = @user.get_followees_matrix(@options[:lda_options])
    # pro.mylda = MyLda.new(pro.user, pro.dir, "lda", pro.options[:lda_options]);0
    # pro.f_c = pro.mylda.run();0
    # pro.lda_output_path = pro.mylda.output_lda()
    @mylda = MyLda.new(@user, @dir, "lda", @options[:lda_options])

    @f_c = @mylda.run()

    # pro.f_c = @mylda.dispatch_followers(@mylda.lda.gamma)
    # @f_c = @mylda.f_c
    @lda_output_path = @mylda.output()
  end

  def cbmf_lda_process()
    f_list, g_arr, g_list, f_arr = User.get_cbmf_matrix(@options[:lda_options])
    @mylda = CbLda.new(@dir, "lda", f_list, g_arr, g_list, f_arr, @options[:lda_options])
    @mylda.run()
    @f_c = @mylda.f_c
    @mylda.output()
  end

  #
  # Matrix Factorization!
  # Input:
  # => @output_path, the dir that containing edges filtered by lda
  # Output:
  # => Prediction list
  #
  def mf_process()
    # pro.my_mf = MyMf.new(pro.dir, "mf", "#{dir}/lda/output", pro.options)
    # pro.mf_output_path = pro.my_mf.run()
    @my_mf = MyMf.new(@dir, "mf", "#{dir}/lda/output", @options)
    @my_mf.preprocess(@user)
    @my_mf.run()
  end

  #
  # Recommend
  # %x{mono lib/cs/item_recommendation.exe --test-ratio=0.1 --recommender=BPRMF --measures='AUC,prec@5,recall@5,NDCG' --training-file=data/tinker2/lda/output/edges_in_9.dat}
  def recommend()
    # pro.recom = Recommender.new(pro.dir, pro.mf_output_path, pro.f_c, pro.options);0
    # pro.recom.run
    @recom = Recommender.new(@dir, "#{dir}/mf", @f_c, @options)
    @recom.run()
  end

  def evaluate()
    # eva = Evaluater.new(pro.dir);0
    @eva = Evaluater.new(@dir)
    @eva.save_report
  end

end
