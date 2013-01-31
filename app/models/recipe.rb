class Recipe < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :stock_list_items
  belongs_to :items
end
