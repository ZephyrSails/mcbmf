class Processor
  attr_accessor :group_name, :dir, :options, :f_c, :lda_output_path, :mf_output_path

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


  def initialize(group_name, options)
    @group_name   = group_name
    @dir          = "data/#{group_name}"
    @options      = options

    Dir.mkdir "#{@dir}" unless File.exists? "#{@dir}"
  end



  def preprocess()
    Loader.filter(@dir, @options[:load_options])
    Loader.load_data(@dir)
    Loader.split_for_test(@dir, @options[:load_options])
  end

  #
  # Input:
  #
  # Output:
  #
  def lda_process()
    # Eros.output_friends("#{@dir}")
    # options = { minus_friends: true, more_than: 0 }
    f_arr, user_arr = User.get_followees_matrix(@options[:lda_options])
    mylda = MyLda.new(@dir, "lda", f_arr, user_arr, @options[:lda_options])
    mylda.run()
    # pro.f_c = mylda.dispatch_followers(mylda.lda.gamma)
    @f_c = mylda.f_c
    @lda_output_path = mylda.output_lda()
  end

  #
  # Matrix Factorization!
  # Input:
  # => @output_path, the dir that containing edges filtered by lda
  # Output:
  # => Prediction list
  #
  def mf_process()
    # pro.options[:mf_options][:args]["predict-items-number"] = 20
    # my_mf = MyMf.new(pro.dir, "mf", pro.lda_output_path, pro.options)
    my_mf = MyMf.new(@dir, "mf", @lda_output_path, @options)
    @mf_output_path = my_mf.run()
  end

  #
  # Recommend
  # %x{mono lib/cs/item_recommendation.exe --test-ratio=0.1 --recommender=BPRMF --measures='AUC,prec@5,recall@5,NDCG' --training-file=data/tinker2/lda/output/edges_in_9.dat}
  def recommend()
    # recom = Recommender.new(pro.dir, pro.mf_output_path, pro.f_c, pro.options)
    recom = Recommender.new(@dir, @mf_output_path, @f_c, @options)
    recom.run()
  end

  def evaluate()
    # eva = Evaluater.new(pro.dir)
    eva = Evaluater.new(@dir)
  end

end
