class UserArr < Array

  def initialize(net, first_followees)
    super(1, first_followees)
    @net = net
  end

  def followees
    self
  end

  def friends
    self.select { |u| @net[] }

  end

end
