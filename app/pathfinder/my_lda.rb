class MyLda
  attr_accessor :lda_data_dir, :user_array, :f_c_thresh, :num_topics, :f_arr, :lda
  attr_reader :f_c, :g_c, :options

  #
  # Create a lda group, save the parameters
  # E.g:
  #   options = { minus_friends: true, more_than: 0 }
  #   f_arr, user_arr = User.get_followees_matrix(options)
  #   mylda = MyLda.new("lda_test2", "lda1", 0.05, f_arr, user_arr, 20)
  #   mylda.run
  #
  def initialize(user, data_dir, lda_name, options)
    @user         = user
    @lda_data_dir = "#{data_dir}/#{lda_name}"

    @f_c_thresh   = options[:f_c_thresh]
    @num_topics   = options[:num_topics]
    @g_c_base     = options[:g_c_base]
    @options      = options
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
    prep_lda()
    puts "prep_lda finished, time spent #{Time.now - begin_at}"

    begin_at = Time.now
    @lda = process_lda()
    puts "process_lda finished, time spent #{Time.now - begin_at}"
    begin_at = Time.now

    norm_gamma = normalize_gamma(@lda.gamma)
    @f_c = dispatch_followers(norm_gamma)
    @g_c = dispatch_followees
    puts "lda dispatch finished, time spent #{Time.now - begin_at}"

    return @f_c
  end

  #
  # Get follower-followee pair ready to meet lda-ruby required format.
  # Meanwhile, map user id to vocabulary list.
  # Input:
  # => @user_arr: containing all users in corpus
  # Output:
  # => lda_ap.dat(corpus): formal corpus file required by lda-ruby
  # => lda_vocab.dat: see prep_vocab()
  #
  def prep_lda()
    @f_arr, @user_arr = @user.get_followees_matrix(@options)

    Dir.mkdir "#{@lda_data_dir}" unless File.exists? "#{@lda_data_dir}"
    o_file = File.open("#{@lda_data_dir}/lda_ap.dat", 'w')
    vocab = []

    @user_arr.each do |followees|
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
    puts "start to load corpus at: #{begin_at = Time.now}"
    corpus = Lda::DataCorpus.new("#{@lda_data_dir}/lda_ap.dat")
    # corpus = Lda::DataCorpus.new("#{pro.mylda.lda_data_dir}/lda_ap.dat");0
    puts "load corpus finished, spent #{Time.now - begin_at}"


    puts "start to init lda at: #{begin_at = Time.now}"
    lda = Lda::Lda.new(corpus) # create an Lda object for training
    lda.num_topics = @num_topics
    puts "init lda finished, spent #{Time.now - begin_at}"

    # lda.em_max_iter
    puts "start to em at: #{begin_at = Time.now}"
    lda.em("random")           # run EM algorithm using random starting points
    lda.load_vocabulary("#{@lda_data_dir}/lda_vocab.dat")
    # normalize_gamma
    puts "em finished, spent #{Time.now - begin_at}"
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
    norm_gamma.each_with_index do |doc, d_index|
      doc.each_with_index do |pr_z_d, z_index|
        # puts "#{pr_z_d}, #{z_index} [#{@lda.vocab[d_index]}, #{pr_z_d}] #{pr_z_d > @f_c_thresh}" if pr_z_d > @f_c_thresh
        if pr_z_d > @f_c_thresh
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
    g_c = @lda.top_words(g_count).values
    g_c.each do |c|
      c.map! { |g| g.to_i }
    end
    g_c
  end

  #
  # Save the result of lda to file.
  #
  def output_lda()
    output_path = "#{@lda_data_dir}/output_user"
    Dir.mkdir "#{output_path}" unless File.exists? "#{output_path}"

    @f_c.each_with_index do |community, c_index|
      o_file = File.open("#{output_path}/f_c_#{c_index}.dat", 'w')

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
  # Store f_c and g_c of each group
  # Different from output_lda, which output the edges of each community
  # We will leave this process to mf process
  #
  def output()

    output_path = "#{@lda_data_dir}/output_user"

    Dir.mkdir "#{output_path}" unless File.exists? "#{output_path}"
    @f_c.each_with_index do |community, c_index|
      f_c_file = File.open("#{output_path}/f_c_#{c_index}.dat", 'w')

      community.each do |f_c_pair|
        # puts "lda: outputing f_c_#{c_index}"
        f_c_file.puts "#{f_c_pair[0]}:#{f_c_pair[1]}"
      end

      f_c_file.close
    end

    @g_c.each_with_index do |community, c_index|
      g_c_file = File.open("#{output_path}/g_c_#{c_index}.dat", 'w')

      community.each do |g_c|
        # puts "lda: outputing g_c_#{c_index}"
        g_c_file.puts "#{g_c}"
      end

      g_c_file.close
    end

  end

end
