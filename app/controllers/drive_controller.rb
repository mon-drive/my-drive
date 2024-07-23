class DriveController < ApplicationController
    before_action :authenticate_user!

    require 'google/apis/drive_v3'
    require 'googleauth'

    def upload
      # Initialize the API
      drive_service = Google::Apis::DriveV3::DriveService.new
      # Use the stored token to authorize
      drive_service.authorization = google_credentials

      # Verify file is present
      if params[:file].present?
        # Upload file to Google Drive
        metadata = {
          name: params[:file].original_filename,
          mime_type: params[:file].content_type
        }
        file = drive_service.create_file(metadata, upload_source: params[:file].tempfile, content_type: params[:file].content_type)
        redirect_to root_path, notice: 'File uploaded to Google Drive successfully'
      else
        redirect_to root_path, alert: 'No file selected'
      end
    end

    private

    def file_params
      params.require(:file)
    end

    def google_credentials
      token = current_user.oauth_token
      refresh_token = current_user.refresh_token
      client_id = ENV['GOOGLE_CLIENT_ID']
      client_secret = ENV['GOOGLE_CLIENT_SECRET']

      Signet::OAuth2::Client.new(
        client_id: client_id,
        client_secret: client_secret,
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        access_token: token,
        refresh_token: refresh_token
      ).tap do |client|
        if client.expired?
          client.fetch_access_token!
          current_user.update(
            oauth_token: client.access_token,
            refresh_token: client.refresh_token,
            oauth_expires_at: Time.at(client.expires_at)
          )
        end
      end
    end

    def authenticate_user!
      redirect_to root_path unless current_user
    end
  end
