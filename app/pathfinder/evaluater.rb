class Evaluater
  require 'csv'
  attr_accessor :test_file, :result_file, :test_arr, :result_arr, :test_hash, :result_hash

  def initialize(dir)
    @test_file   = "#{dir}/test_edges.dat"
    @result_file = "#{dir}/result_edges.dat"

    @test_arr    = CSV.read(@test_file)
    @result_arr  = CSV.read(@result_file)
  end

  def to_s(first=999999)
    "Precision: #{percision(first)}, Recall: #{recall(first)}, F1: #{f1(first)}, conversion_rate: #{conversion_rate(first)}"
  end

  # def loadfile
  #   test_file = File.open(@test_file, "r+")
  #   test.each do
  #
  # end

  def conversion_rate(first=999999)
    @test_hash = Hash.new([])
    @result_hash = Hash.new([])
    @test_arr.each do |follower, followee|
      # puts "#{follower}, #{followee}"
      @test_hash[follower] += [followee]
    end
    @result_arr[0...first].each do |follower, followee|
      @result_hash[follower] += [followee]
    end

    conversion_count = 0
    @test_hash.each do |follower, followees|
      conversion_count += 1 unless (@test_hash[follower] & @result_hash[follower]).empty?
    end
    conversion_count / @test_hash.count.to_f
  end

  def recall(first=999999)
    # test_arr = @test_arr[0..] if first != 0
    puts "#{(@test_arr & @result_arr[0...first]).count} / #{@test_arr.count}"
    (@test_arr & @result_arr[0...first]).count.to_f / @test_arr.count
  end

  def percision(first=999999)
    puts "#{(@test_arr & @result_arr[0...first]).count} / #{@result_arr[0...first].count}"
    (@test_arr & @result_arr[0...first]).count.to_f / @result_arr[0...first].count
  end

  def f1(first=999999)
    2 * (recall(first) * percision(first)) / (recall(first) + percision(first))
  end

end
