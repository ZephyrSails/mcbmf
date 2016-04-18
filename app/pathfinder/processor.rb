class Processor
  attr_accessor :group_name, :dir

  #
  # Create a test instance
  #
  def initialize(group_name)
    @group_name = group_name
    @dir  = "data/#{group_name}"
  end

  #
  # Input:
  #
  # Output:
  #
  def process()
    Dir.mkdir "#{@dir}" unless File.exists? "#{@dir}"

    options = { more_than: 0 }
    options = { minus_friends: true, more_than: 0 }
    f_arr, user_arr = User.get_followees_matrix(options)
    mylda = MyLda.new(@dir, "lda3", 0.1, f_arr, user_arr, 10, 2)
    mylda.run
    output_path = self.output_lda(mylda)

  end

  #
  # Save the result of lda to file.
  #
  def output_lda(mylda)
    output_path = "#{mylda.lda_data_dir}/output"
    Dir.mkdir "#{output_path}" unless File.exists? "#{output_path}"

    mylda.f_c.each_with_index do |community, c_index|
      o_file = File.open("#{output_path}/edges_in_#{c_index}.dat", 'w')

      doc_list = community.transpose.first
      doc_list.each do |doc|
        followees = User.find_by(id: doc).followees.pluck(:id) & mylda.g_c[c_index]
        followees.each do |followee|
          o_file.puts "#{doc},#{followee}"
        end
      end

      o_file.close
    end
    output_path
  end

end
