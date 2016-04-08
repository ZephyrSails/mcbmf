class User < ActiveRecord::Base
  # has_many :edges, dependent: :destroy
  # #
  # has_many :followers, through: :edges, :source => :user
  # has_many :followees, through: :edges, :source => :user

  # has_many :microposts, dependent: :destroy
  # has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  # has_many :followed_users, through: :relationships, source: :followed

  # has_many :microposts, dependent: :destroy
  # has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  # has_many :followed_users, through: :relationships, source: :followed
  # has_many :reverse_relationships, foreign_key: "followed_id",
  #                                  class_name:  "Relationship",
  #                                  dependent:   :destroy
  # has_many :followers, through: :reverse_relationships, source: :follower

  has_many :edges, foreign_key: "follower_id", dependent: :destroy
  has_many :followees, through: :edges, source: :followee

  has_many :reverse_edges, foreign_key: "followee_id",
                            class_name:  "Edge",
                            dependent:   :destroy
  has_many :followers, through: :reverse_edges, source: :follower

  def count_friends
    User.all.each.inject 0 do |a, f|
      # puts f.id
      begin
        a += f.friends.count.to_i
        a
      rescue
        puts f.id
      end
    end
    # .
    # .
    # .
  end

  def friends
    self.followees.inject([]) do |a, f|
      a << f if f.is_friend_of? self
      a
    end
  end

  def is_friend_of? (other_user)
    self.followees.include? other_user
  end

  def friends_of_friends
    friends = self.friends

    result = friends.inject([]) do |array, friend|
      # array += User.find_by(id: friend).friends
      array += friend.friends
      array
    end
    result.uniq - friends
  end

  def User.get!(id)
    (user = User.find_by(id: id)) == nil ? User.create(id: id) : user
  end

  def following?(other_user)
    edges.find_by_followee_id(other_user.id)
  end

  def follow!(other_user)
    begin
      edges.create!(followee_id: other_user.id)
    rescue
    end
  end

  def unfollow!(other_user)
    edges.find_by_followee_id(other_user.id).destroy
  end
  # has_many :followers, :class_name => 'Edges', :foreign_key => 'user_id'
  # has_many :edges, :class_name => 'Edges', :foreign_key => 'follower_id'

  # has_many :followers, :class_name => 'Edges', :foreign_key => 'user_id', dependent: :destroy
  # has_many :followees, :class_name => 'Edges', :foreign_key => 'follower_id', dependent: :destroy
  # has_many :followers, :through => :followees, :source => :user

  # has_many :edges
  # has_many :followers, through: :edges
end
