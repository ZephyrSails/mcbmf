class CbLda
  attr_accessor :lda_data_dir, :g_arr, :f_c_thresh, :num_topics, :f_list, :lda, :g_list, :f_arr
  attr_accessor :f_c, :g_c

  #
  # Create a lda group, save the parameters
  # E.g:
  #   options = { minus_friends: true, more_than: 0 }
  #   f_list, user_arr = User.get_followees_matrix(options)
  #   mylda = MyLda.new("lda_test2", "lda1", 0.05, f_list, user_arr, 20)
  #   mylda.run
  #
  def initialize(data_dir, lda_name, f_list, g_arr, g_list, f_arr, options)
    @lda_data_dir = "#{data_dir}/#{lda_name}"
    @f_list       = f_list
    @g_arr        = g_arr
    @g_list       = g_list
    @f_arr        = f_arr
    @f_c_thresh   = options[:f_c_thresh]
    @num_topics   = options[:num_topics]
    @g_c_base     = options[:g_c_base]
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
    @g_c = self.dispatch_followees(norm_gamma)
    puts "lda finished, time spent #{Time.now - begin_at}"
  end

  #
  # Get follower-followee pair ready to meet lda-ruby required format.
  # Meanwhile, map user id to vocabulary list.
  # Input:
  # => @g_arr: containing all users in corpus
  # Output:
  # => lda_ap.dat(corpus): formal corpus file required by lda-ruby
  # => lda_vocab.dat: see prep_vocab()
  #
  def prep_lda()
    Dir.mkdir "#{@lda_data_dir}" unless File.exists? "#{@lda_data_dir}"
    o_file = File.open("#{@lda_data_dir}/lda_ap.dat", 'w')
    vocab = []

    @g_arr.each do |followees|
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
    @f_arr.each do |followers|
      lda_string = "#{followers.length}"
      followers.each do |g|
        index = vocab.index(g)
        if index
          lda_string += " #{index}:1"
        else
          lda_string += " #{vocab.length}:1"
          vocab << g
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
    o_file = "#{@lda_data_dir}/lda_vocab.dat"
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
    corpus = Lda::DataCorpus.new("#{@lda_data_dir}/lda_ap.dat")

    lda = Lda::Lda.new(corpus) # create an Lda object for training
    lda.num_topics = @num_topics
    # lda.em_max_iter
    lda.em("random")           # run EM algorithm using random starting points
    lda.load_vocabulary("#{@lda_data_dir}/lda_vocab.dat")
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
  # => @f_c_thresh: read from @f_c_thresh
  # Output:
  # => f_c: follower communities [topic_num][followers_in_that_topic]
  #
  def dispatch_followers(norm_gamma)
    # f_c stands for follower communities.
    f_c = [[]] * @lda.num_topics
    f_norm_gamma = norm_gamma[0...f_list.length]
    f_norm_gamma.each_with_index do |doc, d_index|
      doc.each_with_index do |pr_z_d, z_index|
        # puts "#{pr_z_d}, #{z_index} [#{@lda.vocab[d_index]}, #{pr_z_d}] #{pr_z_d > @f_c_thresh}" if pr_z_d > @f_c_thresh
        if pr_z_d > @f_c_thresh
          f_c[z_index] += [[@f_list[d_index], pr_z_d]]
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
  def dispatch_followees(norm_gamma)
    g_c = [[]] * @lda.num_topics
    g_norm_gamma = norm_gamma[f_list.length..-1]
    g_norm_gamma.each_with_index do |doc, d_index|
      doc.each_with_index do |pr_z_d, z_index|
        # puts "#{pr_z_d}, #{z_index} [#{@lda.vocab[d_index]}, #{pr_z_d}] #{pr_z_d > @f_c_thresh}" if pr_z_d > @f_c_thresh
        if pr_z_d > @f_c_thresh
          g_c[z_index] += [[@g_list[d_index], pr_z_d]]
        end
      end
    end
    g_c
  end

  #
  # Save the result of lda to file.
  #
  def output_lda()
    output_path = "#{@lda_data_dir}/output"
    Dir.mkdir "#{output_path}" unless File.exists? "#{output_path}"

    @f_c.each_with_index do |community, c_index|
      o_file = File.open("#{output_path}/edges_in_#{c_index}.dat", 'w')

      doc_list = community.transpose.first
      doc_list.each do |doc|
        followees = User.find_by(id: doc).followees.pluck(:id) & @g_c[c_index].transpose[0]
        followees.each do |followee|
          o_file.puts "#{doc},#{followee}"
        end
      end

      o_file.close
    end
    output_path
  end

end
