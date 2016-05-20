class Evaluater
  require 'csv'
  attr_accessor :test_file, :result_file, :test_arr, :result_arr, :test_hash, :result_hash, :hash, :result_arr

  MAX = 10000

  def initialize(dir,other=false)
    @dir         = dir
    if other == false
      @test_file = "#{dir}/test_edges.dat"
      @result_file = "#{dir}/result_edges.dat"
    else
      @test_file = "data/other/test_edges.dat"
      @result_file = "data/other/#{dir}.output"
    end

    @test_arr    = CSV.read(@test_file)
    @result_arr  = CSV.read(@result_file)
    @other       = other
    Time.now
  end

  def to_s(top_n=MAX)
    "Precision: #{precision(top_n)}, Recall: #{recall(top_n)}, F1: #{f1(top_n)}, conversion_rate: #{conversion_rate(top_n)}"
  end

  #
  # Calculate the conversion_rate of top_n result
  #
  def conversion_rate(top_n=MAX)
    @test_hash = Hash.new([])
    @result_hash = Hash.new([])
    @test_arr.each do |follower, followee|
      # puts "#{follower}, #{followee}"
      @test_hash[follower] += [followee]
    end
    @result_arr[0...top_n].each do |follower, followee|
      @result_hash[follower] += [followee]
    end

    conversion_count = 0
    @test_hash.each do |follower, followees|
      conversion_count += 1 unless (@test_hash[follower] & @result_hash[follower]).empty?
    end
    # (conversion_count / test_hash.count.to_f)
    conversion_count / @test_hash.count.to_f
    # conversion_count / @test_hash.count.to_f
  end

  #
  # Calculate the recall of top_n result
  #
  def recall(top_n=MAX)
    # test_arr = @test_arr[0..] if top_n != 0
    puts "#{(@test_arr & @result_arr[0...top_n]).count} / #{@test_arr.count}"
    (@test_arr & @result_arr[0...top_n]).count.to_f / @test_arr.count
  end

  #
  # Calculate the precision of top_n result
  #
  def precision(top_n=MAX)
    puts "#{(@test_arr & @result_arr[0...top_n]).count} / #{@result_arr[0...top_n].count}"
    (@test_arr & @result_arr[0...top_n]).count.to_f / @result_arr[0...top_n].count
  end

  #
  # Calculate f1 score
  # f1 = (2 * precision * recall) / (precision * recall)
  #
  def f1(top_n=MAX)
    2 * (recall(top_n) * precision(top_n)) / (recall(top_n) + precision(top_n))
  end

  #
  # Used by dcg calculation
  # See detail at https://en.wikipedia.org/wiki/Discounted_cumulative_gain
  #
  def get_rel_arr(top_n=MAX)
    result_arr = @result_arr[0...top_n]
    rel_arr    = Array.new(top_n, 0)

    result_arr.each_with_index do |result_line, index|
      rel_arr[index] = 1 if @test_arr.include? result_line
    end
    rel_arr
  end

  #
  # Used by dcg calculation
  # Actuall it's reciprocal of log' arr, but call it this way is simpler ;)
  # See detail at https://en.wikipedia.org/wiki/Discounted_cumulative_gain
  #
  def get_log_arr(top_n=MAX)
    (1..top_n).inject([]) { |arr, i| arr + [1/Math.log2(i+1)] }
  end

  #
  # Calculate dcg (Discounted cumulative gain)
  # Please use ndcg instead.
  # See detail at https://en.wikipedia.org/wiki/Discounted_cumulative_gain
  #
  def dcg(top_n=MAX)
    rel_arr = get_rel_arr(top_n)
    log_arr = get_log_arr(top_n)
    product(rel_arr, log_arr)
    # (0...top_n).inject(0) { |product, i| product + rel_arr[i]*log_arr[i] }
  end

  #
  # Calculate idcg (Idealized Discounted cumulative gain)
  # Please use ndcg instead.
  # See detail at https://en.wikipedia.org/wiki/Discounted_cumulative_gain
  #
  def idcg(top_n=MAX)
    rel_arr = get_rel_arr(top_n).sort.reverse
    log_arr = get_log_arr(top_n)
    product(rel_arr, log_arr)
    # (0...top_n).inject(0) { |product, i| product + rel_arr[i]*log_arr[i] }
  end

  #
  # Multiply two array, like matrix, but should be faster
  #
  def product(arr1, arr2)
    (0...arr1.count).inject(0) { |product, i| product + arr1[i]*arr2[i] }
  end

  #
  # Calculate ndcg (Normalized Discounted cumulative gain)
  # Please use this, do not use dcg and idcg.
  # See detail at https://en.wikipedia.org/wiki/Discounted_cumulative_gain
  #
  def ndcg(top_n=MAX)
    rel_arr   = get_rel_arr(top_n)
    i_rel_arr = rel_arr.sort.reverse
    log_arr   = get_log_arr(top_n)
    dcg       = product(rel_arr, log_arr)
    idcg      = product(i_rel_arr, log_arr)
    dcg / idcg
  end

  def group_recall(group_arr)
    group_arr.collect do |n|
      (@test_arr & @result_arr[0...n]).count.to_f / @test_arr.count
    end
  end


  def group_precision(group_arr)
    group_arr.collect do |n|
      (@test_arr & @result_arr[0...n]).count.to_f / @result_arr[0...n].count
    end
  end

  def group_f1(recall_arr, precision_arr)
    [*0...recall_arr.count].collect {|i|2*(recall_arr[i]*precision_arr[i])/(recall_arr[i]+precision_arr[i])}
  end

  def group_ndcg(group_arr)
    all_rel_arr = get_rel_arr(group_arr.last)
    # i_rel_arr   = rel_arr.sort.reverse
    log_arr     = get_log_arr(group_arr.last)

    length = group_arr.count
    arr = []
    group_arr.each do |top_n|
      rel_arr   = all_rel_arr[0..top_n]
      i_rel_arr = rel_arr.sort.reverse
      dcg       = product(rel_arr, log_arr)
      idcg      = product(i_rel_arr, log_arr)
      arr << (dcg / idcg)
    end
    arr
  end
  #
  # def dcg(top_n=MAX)
  #   rel_arr = get_rel_arr(top_n)
  #   log_arr = get_log_arr(top_n)
  #   product(rel_arr, log_arr)
  #   # (0...top_n).inject(0) { |product, i| product + rel_arr[i]*log_arr[i] }
  # end
  # def idcg(top_n=MAX)
  #   rel_arr = get_rel_arr(top_n).sort.reverse
  #   log_arr = get_log_arr(top_n)
  #   product(rel_arr, log_arr)
  #   # (0...top_n).inject(0) { |product, i| product + rel_arr[i]*log_arr[i] }
  # end
  # def ndcg(top_n=MAX)
  #   rel_arr   = get_rel_arr(top_n)
  #   i_rel_arr = rel_arr.sort.reverse
  #   log_arr   = get_log_arr(top_n)
  #   dcg       = product(rel_arr, log_arr)
  #   idcg      = product(i_rel_arr, log_arr)
  #   dcg / idcg
  # end

  def group_conversion_rate(group_arr)
    test_hash = Hash.new([])
    test_arr.each do |follower, followee|
      # puts "#{follower}, #{followee}"
      test_hash[follower] += [followee]
    end

    result_hash = Hash.new([])
    length = group_arr.count
    group_arr = [0] + group_arr
    conversion_rate_arr = []
    for i in 1...length do
      result_arr[group_arr[i-1]...group_arr[i]].each do |follower, followee|
        result_hash[follower] += [followee]
      end

      conversion_count = 0
      test_hash.each do |follower, followees|
        conversion_count += 1 unless (test_hash[follower] & result_hash[follower]).empty?
      end
      conversion_rate_arr << (conversion_count / test_hash.count.to_f)
    end
    conversion_rate_arr
  end

  def save_report(linspace_count=10)
    test_count = @test_arr.count
    group_arr = linspace(0, test_count*2, linspace_count)

    o_file = File.open("#{@dir}/report.dat", 'w')
    o_file.puts "--test_edges.count:"
    o_file.puts test_count
    o_file.puts "--recalls:"
    puts "--recalls:"
    o_file.puts recall_arr = group_recall(group_arr)
    o_file.puts "--precisions:"
    puts "--precisions:"
    o_file.puts precision_arr = group_precision(group_arr)
    o_file.puts "--f1s:"
    puts "--f1s:"
    o_file.puts group_f1(recall_arr, precision_arr)
    o_file.puts "--conversion_rates:"
    puts "--conversion_rates:"
    o_file.puts group_conversion_rate(group_arr)

    # o_file.puts "--ndcgs:"
    # puts "--ndcgs:"
    # o_file.puts group_ndcg(group_arr)

    o_file.close
  end

  def linspace(low, high, num)
    [*1..num].collect { |i| low + i * (high-low)/num }
  end

  ##############################################################################

  def read_result
    file = File.new(@result_file, "r")

    @hash = Hash.new([])

    file.each do |line|
      pair = line.split(":")
      @hash[pair[0]] = pair[1].split(",").map { |a| a.strip }
    end
    @hash
    file.close
  end

  def read_other_result
    file = File.new(@result_file, "r")

    @hash = Hash.new([])

    file.each do |line|
      pair = line.split("[").first.strip
      @hash[pair] = line[/.*\[(.*?)\]/, 1].split(",").map { |pair| pair.split(":")[0].strip }
      # @hash[pair[0]] = pair[1].split(",").map { |a| a.strip }
    end
    @hash
    file.close
  end

  def top_k_report(top_k=5)
    test_count = @test_arr.count
    read_result if @other == false
    read_other_result if @other == true

    if @other == false
      o_file = File.open("#{@dir}/report.dat", 'w')
    else
      o_file = File.open("data/other/report_#{@dir}.dat", 'w')
    end
    o_file.puts "--test_edges.count:"
    o_file.puts test_count
    o_file.puts "--recalls:"
    puts "--recalls:"
    o_file.puts recall_arr = top_k_recall(top_k)
    o_file.puts "--precisions:"
    puts "--precisions:"
    o_file.puts precision_arr = top_k_precision(top_k)
    o_file.puts "--f1s:"
    puts "--f1s:"
    o_file.puts group_f1(recall_arr, precision_arr)
    o_file.puts "--conversion_rates:"
    puts "--conversion_rates:"
    o_file.puts top_k_conversion_rate(top_k)
    o_file.puts "--ndcgs:"
    puts "--ndcgs:"
    o_file.puts top_k_ndcg(top_k)

    o_file.close
  end

  def top_k_ndcg(top_k=5)
    @test_hash = Hash.new([])
    @test_arr.each do |follower, followee|
      @test_hash[follower] += [followee]
    end
    log_arr = get_log_arr(top_k)
    # log_arr = [1.0, 0.6309297535714575, 0.5, 0.43067655807339306, 0.38685280723454163]
    ndcg_arr = []
    @hash.each do |follower, followees|
      all_rel_arr = Array.new(top_k, 0)
      followees.each_with_index do |followee, index|
        all_rel_arr[index] = 1 if @test_hash[follower].include? followee
      end
      arr = []
      for i in 1..top_k do
        rel_arr   = all_rel_arr[0..i]
        if rel_arr.sum == 0
          arr << 0
          next
        end
        i_rel_arr = rel_arr.sort.reverse
        dcg       = product(rel_arr, log_arr)
        idcg      = product(i_rel_arr, log_arr)
        arr << (dcg / idcg)
      end
      # puts arr
      ndcg_arr << arr # unless arr.sum == 0
    end
    # ndcg_arr
    ndcg_arr.transpose.collect { |a| a.sum / a.count }
  end

  def top_k_recall(top_k=5)
    result_arr = []
    [*0...top_k].collect do |n|
      result_arr += @hash.to_a.transpose[0].zip(@hash.to_a.transpose[1].transpose[n])
      (@test_arr & result_arr).count.to_f / @test_arr.count
    end
  end

  def top_k_precision(top_k=5)
    result_arr = []
    [*0...top_k].collect do |n|
      result_arr += @hash.to_a.transpose[0].zip(@hash.to_a.transpose[1].transpose[n])
      (@test_arr & result_arr).count.to_f / result_arr.count
    end
  end

  def top_k_conversion_rate(top_k=5)
    test_hash = Hash.new([])
    test_arr.each do |follower, followee|
      # puts "#{follower}, #{followee}"
      test_hash[follower] += [followee]
    end

    # result_hash = Hash.new([])
    # length = group_arr.count
    # group_arr = [0] + group_arr
    conversion_rate_arr = []
    for i in 0...top_k do

      # result_arr[group_arr[i-1]...group_arr[i]].each do |follower, followee|
      #   result_hash[follower] += [followee]
      # end

      conversion_count = 0
      test_hash.each do |follower, followees|
        conversion_count += 1 unless (test_hash[follower] & @hash[follower][0..i]).empty?
      end
      conversion_rate_arr << (conversion_count / test_hash.count.to_f)
    end
    conversion_rate_arr
  end



  # def group_f1(recall_arr, precision_arr)
  #   [*0...recall_arr.count].collect {|i|2*(recall_arr[i]*precision_arr[i])/(recall_arr[i]+precision_arr[i])}
  # end

end
