class Evaluater
  require 'csv'
  attr_accessor :test_file, :result_file, :test_arr, :result_arr, :test_hash, :result_hash

  MAX = 10000

  def initialize(dir)
    @test_file   = "#{dir}/test_edges.dat"
    @result_file = "#{dir}/result_edges.dat"

    @test_arr    = CSV.read(@test_file)
    @result_arr  = CSV.read(@result_file)
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
    conversion_count / @test_hash.count.to_f
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
    # dcg(top_n) / idcg(top_n)
  end

end
