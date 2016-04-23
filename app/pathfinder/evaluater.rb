class Evaluater
  require 'csv'
  attr_accessor :test_file, :result_file, :test_arr, :result_arr, :test_hash, :result_hash

  def initialize(dir)
    @test_file   = "#{dir}/test_edges.dat"
    @result_file = "#{dir}/result_edges.dat"

    @test_arr    = CSV.read(@test_file)
    @result_arr  = CSV.read(@result_file)
  end

  # def loadfile
  #   test_file = File.open(@test_file, "r+")
  #   test.each do
  #
  # end

  def conversion_rate
    @test_hash = Hash.new([])
    @result_hash = Hash.new([])
    @test_arr.each do |follower, followee|
      # puts "#{follower}, #{followee}"
      @test_hash[follower] += [followee]
    end
    @result_arr.each do |follower, followee|
      @result_hash[follower] += [followee]
    end

    conversion_count = 0
    @test_hash.each do |follower, followees|
      conversion_count += 1 unless (@test_hash[follower] & @result_hash[follower]).empty?
    end
    conversion_count / @test_hash.count.to_f
  end

  def recall
    (@test_arr & @result_file).count.to_f / @test_arr.count
  end

  def percision
    (@test_arr & @result_file).count.to_f / @result_file.count
  end

  def f1
    2 * (recall * percision) / (recall + percision)
  end

end
