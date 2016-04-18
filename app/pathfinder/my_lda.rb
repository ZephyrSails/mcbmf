class MyLda
  attr_accessor :group_name, :user_array, :f_threshold, :num_topics, :f_arr, :lda
  attr_reader :f_c, :g_c

  #
  # Create a lda group, save the parameters
  # E.g:
  #   options = { minus_friends: true, more_than: 0 }
  #   f_arr, user_arr = User.get_followees_matrix(options)
  #   mylda = MyLda.new("lda_test2", 0.05, f_arr, user_arr, 20)
  #   mylda.run
  #
  def initialize(group_name, f_threshold, f_arr, user_array, num_topics=20)
    @group_name   = group_name
    @f_arr        = f_arr
    @user_array   = user_array
    @f_threshold  = f_threshold
    @num_topics   = num_topics
  end

  #
  # Use lda to dispatch followers & followees to communities, take care.
  #
  # Output_files:
  # => followers.csv: storing Pr(z|f) matrix [followers_num * topic_num]
  #          ( inspired from Pr(topic|doc) )
  # => followees.csv: storing Pr(g|z) matrix [topic_num * followees_num]
  #          ( inspired from Pr(words|topic) )
  #
  # Output_readers:
  #   ( readers allows you to read following attributes from MyLda object
  #     see https://rubymonk.com/learning/books/4-ruby-primer-ascent/chapters/45-more-classes/lessons/110-instance-variables )
  # => norm_gamma: normalized gamma, interpreted as Pr(z|f)
  # => vocab:      vocabulary map list, used to map simplized id used by
  #                ruby-lda back to original user id
  #
  def run
    begin_at = Time.now
    self.prep_lda()
    @lda = self.process_lda()
    norm_gamma = self.normalize_gamma(@lda.gamma)
    @f_c = self.dispatch_followers(norm_gamma)
    @g_c = self.dispatch_followees
    puts "lda finished, time spent #{Time.now - begin_at}"
  end

  #
  # Get follower-followee pair ready to meet lda-ruby required format.
  # Meanwhile, map user id to vocabulary list.
  # Input:
  # => @user_array: containing all users in corpus
  # Output:
  # => lda_ap.dat(corpus): formal corpus file required by lda-ruby
  # => lda_vocab.dat: see prep_vocab()
  #
  def prep_lda()
    Dir.mkdir "data/#{@group_name}" unless File.exists? "data/#{@group_name}/"
    o_file = File.open("data/#{@group_name}/lda_ap.dat", 'w')
    vocab = []

    @user_array.each do |followees|
      lda_string = "#{followees.length}"
      followees.each do |f|
        index = vocab.index(f)
        if index
          lda_string += " #{index}:1"
        else
          lda_string += " #{vocab.length}:1"
          vocab << f
        end
      end
      o_file.puts lda_string
    end

    o_file.close

    self.prep_vocab(vocab)
  end

  #
  # Store vocabulary list.
  # Input:
  # => vocab: containing all words in corpus (vocabulary)
  # Output:
  # => lda_vocab.dat: formal lda_vocab file reqired by ruby-lda.
  #
  def prep_vocab(vocab)
    o_file = "data/#{@group_name}/lda_vocab.dat"
    output = File.open(o_file, 'w')

    vocab.each do |v|
      output.puts v
    end
    output.close
  end

  #
  # Run ruby-lda EM algorithm with input files, return lda object
  #
  def process_lda()
    corpus = Lda::DataCorpus.new("data/#{@group_name}/lda_ap.dat")

    lda = Lda::Lda.new(corpus) # create an Lda object for training
    lda.num_topics = @num_topics
    # lda.em_max_iter
    lda.em("random")           # run EM algorithm using random starting points
    lda.load_vocabulary("data/#{@group_name}/lda_vocab.dat")
    # normalize_gamma
    lda
    # lda.print_topics(20)     # print all topics with up to 20 words per topic
  end

  #
  # Normalize gamma in lda Object, so it could be interpreted as Pr(z|f)
  #
  def normalize_gamma(gamma)
    gamma.inject([]) do |arr, doc|
      sum = doc.sum
      arr << doc.collect { |z| z / sum }
      arr
    end
  end

  #
  # Dispatch followers to each communities.
  # Input:
  # => @norm_gamma: see normalize_gamma(gamma)
  # => @f_threshold: read from @f_threshold
  # Output:
  # => f_c: follower communities [topic_num][followers_in_that_topic]
  #
  def dispatch_followers(norm_gamma)
    # f_c stands for follower communities.
    f_c = [[]] * @lda.num_topics
    allll = []
    norm_gamma.each_with_index do |doc, d_index|
      doc.each_with_index do |pr_z_d, z_index|
        # puts "#{pr_z_d}, #{z_index} [#{@lda.vocab[d_index]}, #{pr_z_d}] #{pr_z_d > @f_threshold}" if pr_z_d > @f_threshold
        if pr_z_d > @f_threshold
          # f_c[z_index] << @lda.vocab[d_index]
          allll << d_index if @f_arr[d_index] == nil
          f_c[z_index] += [[@f_arr[d_index], pr_z_d]]
        end
      end
    end
    f_c
  end

  #
  # Dispatch followees to each communities.
  # Input:
  # => g_count: top x followees we want to keep in each communities
  # => @lda.beta: used by lda.top_words
  # Output:
  # => g_c: followee communities [topic_num][followees_in_that_topic]
  #
  def dispatch_followees
    g_count = @lda.vocab.count * 2 / @lda.num_topics
    g_c = @lda.top_words(g_count)
    g_c
  end

end
