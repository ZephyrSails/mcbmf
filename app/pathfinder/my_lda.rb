module MyLda
  def self.preprocess_lda
    o_file = File.open("data/lda_ap.dat", 'w')
    vocab = []
    User.all.each do |user|
      # lda_string = "#{user.id}"
      followees = user.followees - user.friends
      lda_string = "#{followees.length}"

      if followees.count > 0
        followees.each do |f|
          index = vocab.index(f.id)
          if index
            lda_string += " #{index}:1"
          else
            lda_string += " #{vocab.length}:1"
            vocab << f.id
          end
        end
        o_file.puts lda_string
        puts user.index
      end
      puts user.index
    end
    o_file.close

    v_file = File.open("data/lda_vocab.dat", 'w')
    vocab.each do |v|
      v_file.puts v
    end
    v_file.close
  end

  def self.preprocess_vocab
    o_file = "data/lda_vocab.dat"
    output = File.open(o_file, 'w')

    User.all.each do |user|
      output.puts user.id
      puts user.id
    end
    output.close
  end

  def self.process
    corpus = Lda::DataCorpus.new("data/lda_ap.dat")
    lda = Lda::Lda.new(corpus)    # create an Lda object for training
    lda.num_topics = 20
    lda.em_max_iter
    lda.em("random")              # run EM algorithm using random starting points
    lda.load_vocabulary("data/lda_vocab.txt")
    lda.print_topics(20)          # print all topics with up to 20 words per topic
  end

end
