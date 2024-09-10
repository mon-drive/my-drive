require 'rails_helper'

RSpec.describe User, type: :model do
  describe "#has_sufficient_space?" do
    it "returns true if the user has enough space" do
      user = User.new(used_space: 5, total_space: 10)
      expect(user.has_sufficient_space?).to be true
    end

    it "returns false if the user doesn't have enough space" do
      user = User.new(used_space: 11, total_space: 10)
      expect(user.has_sufficient_space?).to be false
    end
  end
end
