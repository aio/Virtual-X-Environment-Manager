require 'digest/sha1'

class User < ActiveRecord::Base
  has_and_belongs_to_many :roles, 
                          :join_table => 'user_role_link', 
                          :association_foreign_key => 'role_id', 
                          :foreign_key => 'user_id'

  validates_length_of :login, :within => 3..40
  validates_length_of :password, :within => 5..40, :unless => :updating_roles?
  validates_presence_of :login, :salt
  validates_presence_of :password, :password_confirmation, :unless => :updating_roles?
  validates_uniqueness_of :login
  validates_confirmation_of :password
  
  attr_protected :id, :salt
  
  attr_accessor :password, :password_confirmation, :updating_roles
  
  @updating_roles = false
  
  def self.authenticate(login, pass)
    u=find(:first, :conditions=>["login = ?", login])
    return nil if u.nil?
    return u if User.encrypt(pass, u.salt)==u.hashed_password
    nil
  end
  
  def updating_roles?
    @updating_roles
  end
  
  def password=(pass)
    @password=pass
    self.salt = User.random_string(10) if !self.salt?
    self.hashed_password = User.encrypt(@password, self.salt)
  end
  
  def is_admin?
    self.roles.each do |role|
      return true if role.name == 'admin'
    end
    return false
  end
  
  protected
  
  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass+salt)
  end
  
  def self.random_string(len)
    #generat a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end
  

  
end
