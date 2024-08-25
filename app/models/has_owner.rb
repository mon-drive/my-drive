class HasOwner < ApplicationRecord
  belongs_to :owner
  # `item` può essere un file o una cartella, quindi non specifichiamo una relazione diretta.
end
