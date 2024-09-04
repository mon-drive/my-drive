class HasParent < ApplicationRecord
  belongs_to :parent
  belongs_to :item, polymorphic: true
end
