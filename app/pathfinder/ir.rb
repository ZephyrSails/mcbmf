class Ir

  def initialize(name)
    @name = name
  end

  def item_prediction
    %x{mono lib/cs/item_recommendation.exe --training-file=#{output_path}/edges_in_0.dat --test-ratio=0.2 --recommender=BPRMF}
    # %{mono item_recommendation.exe --help}
    (%x{mono #{File.dirname(__FILE__)}/encrypt.exe #{string}}).split("\n")
  end

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
