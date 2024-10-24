class User < ActiveRecord::Base

  #removing 9/16/2022 for rspec coverage as attr_accessible is deprecated for strong parameters
  #if Blacklight::Utils.needs_attr_accessible?
  #  attr_accessible :email, :password, :password_confirmation
  #end

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end
end
