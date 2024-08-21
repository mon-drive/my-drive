class HasPermission < ApplicationRecord
  belongs_to :permission
  belongs_to :item, polymorphic: true
  # `item` può essere un file o una cartella, quindi non specifichiamo una relazione diretta.
end
