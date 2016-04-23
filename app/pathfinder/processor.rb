class Processor
  attr_accessor :group_name, :dir

  #
  # Create a test instance
  # Data file dir structure:
  # /data/group_name/ (dir)
  # => edges.dat
  # => test_edges.dat
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

  options = {
    :load_options => {
      :source       => "data/edges.csv",
      :mod          => 50,
      :mod_offset   => 7,
      :test_rate    => 0.1,
      :test_friend? => true
    },
    :lda_options => {
      :minus_friends => true,
      :more_than     => 0,
      :num_topics    => 10,
      :f_c_thresh    => 0.1,
      :g_c_base      => 2
    },
    :mf_options => {
      :namespace   => "item_recommendation", # or "rating_prediction"
      :num_topics  => 10,
      :args => {
        "recommender"           => "BPRMF",
        "predict-items-number"  => "5",
        "measures"              => "AUC, prec@5, recall@5 NDCG"
      }
    }
  }

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
    @output_path = mylda.output_lda()
  end

  #
  # Matrix Factorization!
  # Input:
  # => @output_path, the dir that containing edges filtered by lda
  # Output:
  # => Prediction list
  #
  def mf_process()
    my_mf = MyMf.new(@dir, "mf", @output_path, options[:mf_options])
    my_mf.run()

  end

end
