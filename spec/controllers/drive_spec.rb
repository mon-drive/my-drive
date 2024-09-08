require 'rails_helper'

RSpec.describe DriveController, type: :controller do
  describe '#scan' do
    context 'when no file is selected' do
      before do
        post :scan, params: { file: nil }
      end

      it 'redirects to the dashboard with an alert message' do
        expect(response).to redirect_to(/dashboard/)
      end
    end
  end
end
