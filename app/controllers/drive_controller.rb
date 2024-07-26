class DriveController < ApplicationController
    before_action :authenticate_user!
    before_action :set_item, only: [:rename, :share, :export, :properties]

    require 'google/apis/drive_v3'
    require 'googleauth'

    require 'httparty'
    require 'json'

    def dashboard
      drive_service = initialize_drive_service
      @current_folder = params[:folder_id] || 'root'
      @all_items = get_files_and_folders(drive_service)
      if params[:folder_id] == 'bin'
        @current_folder_name = 'Cestino'
      else
        @current_folder_name = @current_folder == 'root' ? 'Root' : get_folder_name(drive_service, @current_folder)
        @parent_folder = get_parent_folder(drive_service, @current_folder) unless @current_folder == 'root'
      end
      @root_folder_name = get_root_name(drive_service)
      if params[:search].present?
        @current_folder = 'null'
        @items = search_files(drive_service, params[:search])
      else
        if params[:folder_id] == 'bin'
          @current_folder = 'bin'
          @items = get_files_and_folders_in_bin(drive_service)
        else
          @items = get_files_and_folders_in_folder(drive_service, @current_folder)
        end
      end
      storage_info()

    end

    def setting
      # Logica per le impostazioni
      drive_service = initialize_drive_service
      @user = current_user
    end

    def rename
      if @item.update(item_params)
        respond_to do |format|
          format.json { render json: { success: true, name: @item.name } }
        end
      else
        respond_to do |format|
          format.json { render json: { success: false, errors: @item.errors.full_messages } }
        end
      end
    end

    def share
      # Logica per condividere l'elemento
    end

    def export
      # Logica per esportare l'elemento
    end

    def properties
      respond_to do |format|
        format.json { render json: { success: true, properties: @item.attributes } }
      end
    end

    #carica il file su virustotal e se non è infetto lo carica su google drive
    def scan
      file_id = params[:file]
      puts "avvio scan"
      if file_id.nil?
        puts "nessun file selezionato"
        redirect_to dashboard_path, alert: "Nessun file selezionato per il caricamento."
        return
      end
      @current_folder = params[:folder_id] || 'root'
      response = upload_scan(file_id)
      puts response
      #se la risposta è 200 allora il file è stato caricato correttamente
      if response.code == 200
        scan_id = JSON.parse(response.body)['data']['id']
        puts "mo scanziono"
        analyze_response = analyze(scan_id)

        while JSON.parse(analyze_response.body)['data']['attributes']['status'] == 'queued' || JSON.parse(analyze_response.body)['data']['attributes']['status'] == 'in_progress'
          sleep(15)
          analyze_response = analyze(scan_id)
          puts JSON.parse(analyze_response.body)['data']['attributes']['status']
        end
        #se la risposta è 200 allora il file è stato analizzato correttamente
        if analyze_response.code == 200
          malicious_count = JSON.parse(analyze_response.body)['data']['attributes']['stats']['malicious']
          #suspicious_count = JSON.parse(analyze_response.body)['data']['attributes']['stats']['suspicious']
          #se il file è infetto non lo carica su google drive
          if malicious_count > 0
            puts malicious_count
            redirect_to dashboard_path, alert: "File infetto, non è possibile caricarlo. Risulta malevolo su #{malicious_count} motori di ricerca."
          else
            puts "file pulito"
            upload(file_id)
            redirect_to dashboard_path(folder_id: @current_folder), notice: "File caricato con successo"
          end
        else
          puts "errore analisi"
          error = JSON.parse(analyze_response.body)['error']['message']
          redirect_to dashboard_path, alert: "Si è verificato un errore: #{error}"
        end
      else
        puts "errore caricamento"
        error = JSON.parse(response.body)['error']['message']
        redirect_to dashboard_path, alert: "Si è verificato un errore: #{error}"
      end

    end

    #carica il file su virustotal
    def upload_scan(file)
      api_key=Figaro.env.VIRUSTOTAL_API_KEY
      url="https://www.virustotal.com/api/v3/files"
      HTTParty.post(url,
        headers: { 'x-apikey' => api_key },
        body: { file: file }
      )
    end

    #analizza il file su virustotal partendo dall'id ottenuto dopo l'upload su virustotal
    def analyze(id)
      api_key = Figaro.env.VIRUSTOTAL_API_KEY
      url = "https://www.virustotal.com/api/v3/analyses/#{id}"
      HTTParty.get(url,
        headers: { 'x-apikey' => api_key }
      )
    end


    def upload(file)
      # Initialize the API
      drive_service = Google::Apis::DriveV3::DriveService.new

      # Use the stored token to authorize
      drive_service.authorization = google_credentials

      # Verify file is present
      # if params[:file].present?
        # Upload file to Google Drive
      metadata = {
        name: params[:file].original_filename,
        parents: [@current_folder],
        mime_type: params[:file].content_type
      }
      file = drive_service.create_file(metadata, upload_source: params[:file].tempfile, content_type: params[:file].content_type)
      #redirect_to dashboard_path, notice: 'File uploaded to Google Drive successfully'
    end

    def create_folder
      folder_name = params[:folder_name]
      if folder_name.blank?
        redirect_to dashboard_path, alert: "Il nome della cartella non può essere vuoto."
        return
      end

      # Logica per creare la cartella, ad esempio tramite un'API di Google Drive
      # Supponiamo che ci sia una funzione create_folder_in_drive(folder_name) che crea la cartella

      @current_folder = params[:folder_id] || 'root'

      begin
        create_folder_in_drive(folder_name)
        redirect_to dashboard_path(folder_id: @current_folder), notice: "Cartella '#{folder_name}' creata con successo."
      rescue => e
        redirect_to dashboard_path, alert: "Si è verificato un errore durante la creazione della cartella: #{e.message}"
      end
    end

    def storage_info
      begin
        drive_service = initialize_drive_service
        storage_info = get_storage_info

        @total_space = storage_info[:total_space]
        @used_space = storage_info[:used_space]
      rescue => e
        render json: { error: "Si è verificato un errore: #{e.message}" }, status: :unprocessable_entity
      end
    end

    def delete_item
      drive_service = initialize_drive_service
      item_id = params[:item_id]
      folder_id = params[:folder_id] # Recupera il parametro folder_id
      
      begin
        drive_service.delete_file(item_id)
        respond_to do |format|
          format.html { redirect_to dashboard_path(folder_id: folder_id), notice: 'Elemento eliminato con successo.' }
          format.json { render json: { message: 'Elemento eliminato con successo.' }, status: :ok }
        end
      rescue => e
        respond_to do |format|
          format.html { redirect_to dashboard_path(folder_id: folder_id), alert: "Errore nell'eliminazione dell'elemento: #{e.message}" }
          format.json { render json: { error: "Errore nell'eliminazione dell'elemento: #{e.message}" }, status: :unprocessable_entity }
        end
      end
    end

    private

    def initialize_drive_service
      drive_service = Google::Apis::DriveV3::DriveService.new
      drive_service.authorization = google_credentials
      drive_service
    end

    def get_files_and_folders_in_folder(drive_service, folder_id)
      all_items = []
      next_page_token = nil

      begin
        response = drive_service.list_files(
          q: "'#{folder_id}' in parents and trashed = false",
          fields: 'nextPageToken, files(id, name, mimeType, parents)',
          spaces: 'drive',
          page_token: next_page_token
        )
        all_items.concat(response.files)
        next_page_token = response.next_page_token
      end while next_page_token.present?

      all_items
    end

    def get_files_and_folders_in_bin(drive_service)
      all_items = []
      next_page_token = nil

      begin
        response = drive_service.list_files(
          q: "trashed = true",
          fields: 'nextPageToken, files(id, name, mimeType, parents)',
          spaces: 'drive',
          page_token: next_page_token
        )
        all_items.concat(response.files)
        next_page_token = response.next_page_token
      end while next_page_token.present?

      all_items
    end

    def search_files(drive_service, query)
      all_items = []
      next_page_token = nil

      begin
        response = drive_service.list_files(
          q: "name contains '#{query}' and trashed = false",
          fields: 'nextPageToken, files(id, name, mimeType, parents)',
          spaces: 'drive',
          page_token: next_page_token
        )
        all_items.concat(response.files)
        next_page_token = response.next_page_token
      end while next_page_token.present?

      all_items
    end

    def get_files_and_folders(drive_service)
      all_items = []
      next_page_token = nil

      begin
        response = drive_service.list_files(
          q: 'trashed = false',
          fields: 'nextPageToken, files(id, name, mimeType, parents)',
          spaces: 'drive',
          page_token: next_page_token
        )
        all_items.concat(response.files)
        next_page_token = response.next_page_token
      end while next_page_token.present?

      all_items
    end

    def get_parent_folder(drive_service, folder_id)
      return if folder_id == 'root'

      folder = drive_service.get_file(folder_id, fields: 'id, name, parents')
      parents = folder.parents || []

      parents.empty? ? nil : drive_service.get_file(parents.first, fields: 'id, name')
    end

    def get_folder_name(drive_service, folder_id)
      folder = drive_service.get_file(folder_id, fields: 'name')
      folder.name
    end

    def get_root_name(drive_service)
      folder = drive_service.get_file('root', fields: 'name')
      folder.name
    end

    def create_folder_in_drive(folder_name)
      # Implementa la logica per creare una cartella in Google Drive o altro servizio
      drive_service = initialize_drive_service
      puts "\n\n\n\n"
      puts @current_folder
      puts "\n\n\n\n"
      metadata = {
        name: folder_name,
        parents: [@current_folder],
        mime_type: "application/vnd.google-apps.folder"
      }
      file = drive_service.create_file(metadata, content_type: "application/vnd.google-apps.folder")
    end

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
        client.fetch_access_token!
        current_user.update(
          oauth_token: client.access_token,
          refresh_token: client.refresh_token,
          oauth_expires_at: Time.at(client.expires_at)
        )
      end
    end

    def get_storage_info
      drive_service = initialize_drive_service
      about = drive_service.get_about(fields: 'storageQuota')
      {
        total_space: about.storage_quota.limit.to_i,
        used_space: about.storage_quota.usage.to_i
      }
    end

    def authenticate_user!
      redirect_to root_path unless current_user
    end

    def set_item
      @item = Item.find(params[:id])
    end

    def item_params
      params.require(:item).permit(:name)
    end

  end
