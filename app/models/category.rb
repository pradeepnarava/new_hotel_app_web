# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Category < ActiveRecord::Base
   resourcify
  attr_accessible :name
  validates :name, :presence => true
  validates :name, :uniqueness => true
  has_many :items
end
