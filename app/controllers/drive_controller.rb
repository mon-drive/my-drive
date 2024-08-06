class DriveController < ApplicationController
    before_action :authenticate_user!

    require 'google/apis/drive_v3'
    require 'googleauth'

    require 'httparty'
    require 'json'
    require 'zip'
    require 'cloudmersive-convert-api-client'

    def dashboard
      drive_service = initialize_drive_service
      @current_folder = params[:folder_id] || 'root'
      @all_items = get_files_and_folders(drive_service)
      @root_folder_name = get_root_name(drive_service)
      if params[:folder_id] == 'bin'
        @current_folder_name = 'Cestino'
      else
        @current_folder_name = @current_folder == 'root' ? @root_folder_name : get_folder_name(drive_service, @current_folder)
        @parent_folder = get_parent_folder(drive_service, @current_folder) unless @current_folder == 'root'
      end
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
      #initialize drive service
      drive_service = initialize_drive_service

      #get file id and new name and metadata
      file_id = params[:id]
      new_name = params[:item][:name]

      puts "\n\n\n\n"
      puts "File ID: #{file_id}"
      puts "New Name: #{new_name}"
      puts "\n\n\n\n"

      file_metadata = Google::Apis::DriveV3::File.new(name: new_name)

      drive_service.update_file(file_id, file_metadata, fields: 'name')

    end

    def share
      # Logica per condividere l'elemento
      drive_service = initialize_drive_service

      file_id = params[:file_id]
      email = params[:email]
      role = params[:permission]
      notify = params[:notify]
      message = params[:message]

      permission = Google::Apis::DriveV3::Permission.new(
        type: 'user',
        role: role,
        email_address: email
      )

      drive_service.create_permission(file_id, permission, email_message: message, send_notification_email: notify)

      respond_to do |format|
        format.json { render json: { success: true, message: 'File condiviso con successo.' } }
      end
    end

    def export
      file_id = params[:id]
      drive_service = initialize_drive_service

      begin
        # Recupera il file da Google Drive
        file_metadata = drive_service.get_file(file_id, fields: 'id, name, mimeType')
        file_name = file_metadata.name
        file_content = StringIO.new
        drive_service.get_file(file_id, download_dest: file_content)

        # Scrivi il file scaricato su disco locale
        local_file_path = Rails.root.join('tmp', file_name)
        File.open(local_file_path, 'wb') do |file|
          file.write(file_content.string)
        end

        # Configura Cloudmersive
        CloudmersiveConvertApiClient.configure do |config|
          config.api_key['Apikey'] = Figaro.env.CLOUDMERSIVE_API_KEY
        end

        # Converti il documento in PDF usando HTTParty
        api_key = Figaro.env.CLOUDMERSIVE_API_KEY
        response = HTTParty.post(
          'https://api.cloudmersive.com/convert/autodetect/to/pdf',
          headers: { 'Apikey' => api_key },
          body: { inputFile: File.new(local_file_path) }
        )

        if response.success?
          # Genera un nome file unico per il PDF
          pdf_file_name = "#{File.basename(file_name, '.*')}_converted.pdf"

          # Invia il file PDF al browser
          send_data(
            response.body,
            filename: pdf_file_name,
            type: 'application/pdf',
            disposition: 'attachment'
          )
        else
          render json: { error: "Conversione fallita: #{response.code} #{response.message}" }, status: :unprocessable_entity
        end

      rescue Google::Apis::ClientError => e
        render json: { error: "Errore Google Drive: #{e.message}" }, status: :bad_request
      rescue => e
        render json: { error: "Errore imprevisto: #{e.message}" }, status: :internal_server_error
      ensure
        # Pulisci i file temporanei
        File.delete(local_file_path) if File.exist?(local_file_path)
      end
    end


    def properties
      #initialize drive service
      drive_service = initialize_drive_service

      #get file id
      file_id = params[:id]

      #save file data
      file = drive_service.get_file(file_id, fields: 'id, name, mime_type, size, created_time, modified_time, owners, permissions, shared')

      # Render the response as JSON
      file_properties = {
        id: file.id,
        name: file.name,
        mime_type: file.mime_type,
        size: file.size,
        created_time: file.created_time.to_s,
        modified_time: file.modified_time.to_s,
        owners: file.owners.map { |owner| { display_name: owner.display_name, email: owner.email_address } },
        permissions: file.permissions,
        shared: file.shared,
      }
      render json: file_properties
      rescue Google::Apis::ClientError => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    #carica il file su virustotal e se non è infetto lo carica su google drive
    def scan
      file_id = params[:file]
      puts "Avvio scan"
      if file_id.nil?
        redirect_to dashboard_path, alert: "Nessun file selezionato per il caricamento."
        return
      end
      @current_folder = params[:folder_id] || 'root'

      begin
        file_path = params[:file].path
        puts "File path: #{file_path}"

        response_upload = upload_scan(file_path)

        if response_upload['data'] && response_upload['data']['id']
          scan_id = response_upload['data']['id']
          puts "Scan ID received: #{scan_id}"

          analyze_response = nil

          5.times do  # Prova per un massimo di 5 volte

            analyze_response = analyze(scan_id)
            status = analyze_response['data']['attributes']['status']
            puts "Analysis status: #{status}"
            break if ['completed', 'failed'].include?(status)
            sleep(20)  # Attendi 20 secondi tra ogni tentativo
          end

          if analyze_response['data'] && analyze_response['data']['attributes']
            if analyze_response['data']['attributes']['status'] == 'completed'
              malicious_count = analyze_response['data']['attributes']['stats']['malicious']
              puts "Malicious count: #{malicious_count}"
              if malicious_count > 0
                redirect_to dashboard_path(folder_id: @current_folder), alert: "File infetto, non è possibile caricarlo. Risulta malevolo su #{malicious_count} motori di ricerca."
              else
                puts "File pulito"
                upload(file_id)
                redirect_to dashboard_path(folder_id: @current_folder), notice: "File caricato con successo"
              end
            else
              redirect_to dashboard_path(folder_id: @current_folder), alert: "L'analisi non è stata completata in tempo. Per favore, riprova più tardi."
            end
          else
            error = analyze_response['error'] ? analyze_response['error']['message'] : "Errore sconosciuto durante l'analisi"
            puts "Analysis error: #{error}"
            redirect_to dashboard_path(folder_id: @current_folder), alert: "Si è verificato un errore: #{error}"
          end
        else
          error = response_upload['error'] ? response_upload['error']['message'] : "Errore sconosciuto durante il caricamento"
          puts "Upload error: #{error}"
          redirect_to dashboard_path(folder_id: @current_folder), alert: "Si è verificato un errore: #{error}"
        end
      rescue => e
        puts "Error in scan: #{e.message}"
        puts e.backtrace.join("\n")
        redirect_to dashboard_path(folder_id: @current_folder), alert: "Si è verificato un errore durante la scansione: #{e.message}"
      end
    end

    #carica il file su virustotal
    def upload_scan(file_path)
      api_key = Figaro.env.VIRUSTOTAL_API_KEY
      url = "https://www.virustotal.com/api/v3/files"

      puts "Attempting to upload file: #{file_path}"
      puts "File exists: #{File.exist?(file_path)}"
      puts "File size: #{File.size(file_path)} bytes"

      begin
        file = File.open(file_path, 'rb')
        puts "File opened successfully"

        response = HTTParty.post(url,
          headers: {
            'x-apikey' => api_key
          },
          multipart: true,
          body: {
            file: file
          },
          debug_output: $stdout # This will log the full HTTP request and response
        )

        puts "VirusTotal API Response: #{response.body}"
        JSON.parse(response.body)
      rescue => e
        puts "Error in upload_scan: #{e.message}"
        puts e.backtrace.join("\n")
        { 'error' => { 'message' => e.message } }
      ensure
        file.close if file
      end
    end

    def analyze(id)
      api_key = Figaro.env.VIRUSTOTAL_API_KEY
      url = "https://www.virustotal.com/api/v3/analyses/#{id}"
      response = HTTParty.get(url,
        headers: { 'x-apikey' => api_key }
      )
      JSON.parse(response.body)
    end


    def upload(file)
      # Initialize the API
      drive_service = initialize_drive_service

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

    def folder_scan
      folder_name = params[:folder_name]
      if folder_name.blank?
        redirect_to dashboard_path, alert: "Nessuna cartella selezionata per il caricamento."
        return
      end

      begin
        puts "Files received: #{params[:files].inspect}"
        zip_buffer = create_zip_from_folder(params[:files])
        puts "Zip buffer created, size: #{zip_buffer.bytesize} bytes"

        temp_file = Tempfile.new(['scan', '.zip'])
        temp_file.binmode
        temp_file.write(zip_buffer)
        temp_file.rewind
        puts "Temporary file created: #{temp_file.path}"

        response_upload = upload_scan(temp_file.path)

        if response_upload['data'] && response_upload['data']['id']
          scan_id = response_upload['data']['id']
          puts "Scan ID received: #{scan_id}"

          analyze_response = nil

          5.times do  # Prova per un massimo di 5 volte

            analyze_response = analyze(scan_id)
            status = analyze_response['data']['attributes']['status']
            puts "Analysis status: #{status}"
            break if ['completed', 'failed'].include?(status)
            sleep(20)  # Attendi 20 secondi tra ogni tentativo
          end

          if analyze_response['data'] && analyze_response['data']['attributes']
            if analyze_response['data']['attributes']['status'] == 'completed'
              malicious_count = analyze_response['data']['attributes']['stats']['malicious']
              puts "Malicious count: #{malicious_count}"
              if malicious_count > 0
                redirect_to dashboard_path, alert: "Cartella infetta, non è possibile caricarla. Risulta malevola su #{malicious_count} motori di ricerca."
                return
              else
                upload_folder
                redirect_to dashboard_path, notice: "Cartella caricata con successo"
                return
              end
            else
              redirect_to dashboard_path, alert: "L'analisi non è stata completata in tempo. Per favore, riprova più tardi."
              return
            end
          else
            error = analyze_response['error'] ? analyze_response['error']['message'] : "Errore sconosciuto durante l'analisi"
            puts "Analysis error: #{error}"
            redirect_to dashboard_path, alert: "Si è verificato un errore: #{error}"
            return
          end
        else
          error = response_upload['error'] ? response_upload['error']['message'] : "Errore sconosciuto durante il caricamento"
          puts "Upload error: #{error}"
          redirect_to dashboard_path, alert: "Si è verificato un errore: #{error}"
          return
        end
      rescue => e
        puts "Error in folder_scan: #{e.message}"
        puts e.backtrace.join("\n")
        redirect_to dashboard_path, alert: "Si è verificato un errore durante la scansione: #{e.message}"
        return
      ensure
        temp_file.close
        temp_file.unlink if temp_file
        puts "Temporary file deleted"
      end
    end

    def create_zip_from_folder(files)
      Zip::OutputStream.write_buffer do |zip|
        files.each do |file|
          puts "Adding file to zip: #{file.original_filename}"
          next unless file.respond_to?(:original_filename) && file.respond_to?(:read)
          zip.put_next_entry(file.original_filename)
          zip.write file.read
        end
      end.string
    end

    def upload_folder

      drive_service = initialize_drive_service

      folder_name = params[:folder_name]

      if folder_name.blank?
        redirect_to dashboard_path, alert: 'Nome della cartella non fornito.'
        return
      end

      # Crea la cartella su Google Drive
      folder_metadata = {
        name: folder_name,
        mime_type: 'application/vnd.google-apps.folder',
        parents: [params[:folder_id]]
      }
      folder = drive_service.create_file(folder_metadata, fields: 'id')

      # Itera su tutti i file nella cartella e caricali su Google Drive
      params[:files].each do |file|
        file_metadata = {
          name: file.original_filename,
          parents: [folder.id],
          mime_type: file.content_type
        }
        drive_service.create_file(file_metadata, upload_source: file.tempfile, content_type: file.content_type)
      end

      #redirect_to dashboard_path, notice: 'Cartella caricata su Google Drive con successo'
      #return
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
        return
      rescue => e
        redirect_to dashboard_path, alert: "Si è verificato un errore durante la creazione della cartella: #{e.message}"
        return
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

    def item_params
      params.require(:item).permit(:name)
    end

  end
