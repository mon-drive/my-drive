require 'rails_helper'

RSpec.describe DriveController, type: :controller do
  describe '#scan' do
    let(:file) { fixture_file_upload('test_file.txt', 'text/plain') }
    let(:valid_upload_response) { { 'data' => { 'id' => 'scan_id' } } }
    let(:valid_analyze_response_completed) { { 'data' => { 'attributes' => { 'status' => 'completed', 'stats' => { 'malicious' => 0 } } } } }
    let(:valid_analyze_response_failed) { { 'data' => { 'attributes' => { 'status' => 'failed' } } } }
    let(:valid_analyze_response_malicious) { { 'data' => { 'attributes' => { 'status' => 'completed', 'stats' => { 'malicious' => 3 } } } } }
    let(:error_response) { { 'error' => { 'message' => 'Some error' } } }
    let(:upload_scan_response) { { 'data' => { 'id' => 'scan_id' } } }
    let(:analyze_response) { { 'data' => { 'attributes' => { 'status' => 'completed', 'stats' => { 'malicious' => 0 } } } } }

    before do
      allow(controller).to receive(:upload_scan).and_return(upload_scan_response)
      allow(controller).to receive(:analyze).and_return(analyze_response)
      allow(controller).to receive(:upload).with('scan_id').and_return(true)
    end

    context 'when file upload is successful and scan is completed without malicious content' do
      let(:params) { { file: file } }
      let(:upload_scan_response) { valid_upload_response }
      let(:analyze_response) { valid_analyze_response_completed }


      before do
        post :scan, params: { file: file }
      end

      it 'uploads the file and redirects with a success message' do
        expect(response).to redirect_to(dashboard_path(folder_id: $current_folder))
        expect(flash[:notice]).to eq('File caricato con successo')
      end
    end

    context 'when file upload is successful but scan detects malicious content' do
      let(:params) { { file: file } }
      let(:upload_scan_response) { valid_upload_response }
      let(:analyze_response) { valid_analyze_response_malicious }

      before { post :scan, params: { file: file } }

      it 'redirects to the dashboard with a malicious content alert' do
        expect(response).to redirect_to(dashboard_path(folder_id: $current_folder))
        expect(flash[:alert]).to eq('File infetto, non è possibile caricarlo. Risulta malevolo su 3 motori di ricerca.')
      end
    end

    context 'when file upload is successful but scan fails' do
      let(:params) { { file: file } }
      let(:upload_scan_response) { valid_upload_response }
      let(:analyze_response) { valid_analyze_response_failed }

      before { post :scan, params: { file: file } }

      it 'redirects to the dashboard with a timeout alert' do
        expect(response).to redirect_to(dashboard_path(folder_id: $current_folder))
        expect(flash[:alert]).to eq("L'analisi non è stata completata in tempo. Per favore, riprova più tardi.")
      end
    end
  end
end
