require 'dynamoid'

class User
  include Dynamoid::Document
  field     :email_address, :string
  field     :name,          :string
  has_and_belongs_to_many   :stores
  has_and_belongs_to_many   :items

  belongs_to :userrequest

  def self.destroy(id)
    find(id).destroy
  end

  def self.delete_all
    all.each(&:delete)
  end
end
