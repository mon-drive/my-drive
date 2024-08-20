class DriveController < ApplicationController
    before_action :authenticate_user!
    before_action :fetch_google_profile_image

    require 'google/apis/drive_v3'
    require 'googleauth'

    require 'httparty'
    require 'json'
    require 'zip'

    def dashboard
      drive_service = initialize_drive_service
      @current_folder = params[:folder_id] || 'root'
      @all_items = get_files_and_folders(drive_service)

      @root_folder_name = get_root_name(drive_service)
      @root_folder_id = get_root_id(drive_service)
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

      temp = UserFile.find_by(file_id: file_id)
      if temp.nil?
        temp = Folder.find_by(folder_id: file_id)
        if not temp.nil?
          ShareFolder.create(folder_id: file_id, user_id: current_user.id)
        end
      else
        #ShareFile.create(file_id: file_id, user_id: current_user.id)
      end

      respond_to do |format|
        format.json { render json: { success: true, message: 'File condiviso con successo.' } }
      end
    end

    def export
      file_id = params[:id]
      type = params[:type]
      drive_service = initialize_drive_service

      if type == 'SELF'
        download_file(drive_service, file_id)
        return
      end

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

        api_key = Figaro.env.CLOUDMERSIVE_API_KEY

        url = case type
              when 'PDF'
                'https://api.cloudmersive.com/convert/autodetect/to/pdf'
              when 'DOCX'
                'https://api.cloudmersive.com/convert/odt/to/docx'
              when 'XLSX'
                'https://api.cloudmersive.com/convert/ods/to/xlsx'
              when 'PPTX'
                'https://api.cloudmersive.com/convert/odp/to/pptx'
              when 'JPEG'
                'https://api.cloudmersive.com/convert/autodetect/to/jpg'
              when 'PNG'
                'https://api.cloudmersive.com/convert/autodetect/to/png'
              end

        # Esegui la richiesta HTTP al servizio di conversione
        response = HTTParty.post(
          url,
          headers: { 'Apikey' => api_key },
          multipart: true,
          body: { inputFile: File.new(local_file_path) }
        )

        if response.success?
          case type
          when 'PDF', 'DOCX', 'XLSX', 'PPTX'
            # Genera un nome file unico per il file convertito
            converted_file_name = "#{File.basename(file_name, '.*')}_converted.#{type.downcase}"

            # Invia il file convertito al browser
            send_data(
              response.body,
              filename: converted_file_name,
              type: response.headers['content-type'],
              disposition: 'attachment'
            )
          when 'JPEG'
            # Ottieni la risposta come array di immagini JPEG
            jpeg_response = response.parsed_response
            jpeg_pages = jpeg_response['JpgResultPages']

            # Salva e invia ogni immagine JPEG convertita
            jpeg_pages.each_with_index do |page, index|
              jpeg_data = Base64.decode64(page['Content'])
              converted_file_name = "#{File.basename(file_name, '.*')}_converted_#{index + 1}.jpeg"
              send_data(
                jpeg_data,
                filename: converted_file_name,
                type: 'image/jpeg',
                disposition: 'attachment'
              )
            end
          when 'PNG'
            # Ottieni la risposta come hash con l'URL dell'immagine PNG convertita
            png_response = response.parsed_response
            if png_response.key?('PngResultPages')
              png_url = png_response['PngResultPages'].first['URL']

              # Scarica l'immagine PNG e invia al browser
              png_data = HTTParty.get(png_url).body
              send_data(
                png_data,
                filename: "#{File.basename(file_name, '.*')}_converted.png",
                type: 'image/png',
                disposition: 'attachment'
              )
            else
              render json: { error: 'Conversione a PNG fallita' }, status: :unprocessable_entity
            end
          end
          #Convert.create(file_id: file_id, premium_user_id: current_user.id)
        else
          render json: { error: "Conversione fallita: #{response.code} #{response.message}" }, status: :unprocessable_entity
        end
      rescue Google::Apis::ClientError => e
        render json: { error: "Errore Google Drive: #{e.message}" }, status: :bad_request
      rescue CloudmersiveConvertApiClient::ApiError => e
        render json: { error: "Errore Cloudmersive: #{e.message}" }, status: :unprocessable_entity
      rescue => e
        render json: { error: "Errore imprevisto: #{e.message}" }, status: :internal_server_error
      ensure
        # Pulisci i file temporanei
        File.delete(local_file_path) if File.exist?(local_file_path)
      end
    end

    def download_file(drive_service, file_id)
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

      # Invia il file al browser
      send_file local_file_path, filename: file_name
    end


    def properties
      # Initialize drive service
      drive_service = initialize_drive_service

      # Get file id
      file_id = params[:id]

      # Save file data
      file = drive_service.get_file(file_id, fields: 'owners, permissions')
      myFile = UserFile.find_by(file_id: file_id)
      if myFile.nil?
        myFile = Folder.find_by(folder_id: file_id)
      end

      if file.mime_type == 'application/vnd.google-apps.folder'
        # Calcola la dimensione, il numero di file e cartelle ricorsivamente
        result = calculate_folder_stats(drive_service, file_id)
        total_size = result[:size]
        folder_number = result[:folder_count]
        file_number = result[:file_count]
      else
        total_size = file.size.to_i
        folder_number = 0
        file_number = 1
      end

      # Render the response as JSON
      file_properties = {
        id: myFile.id,
        name: myFile.name,
        mime_type: myFile.mime_type,
        size: total_size,
        created_time: myFile.created_time.to_s,
        modified_time: myFile.modified_time.to_s,
        owners: file.owners.map { |owner| { display_name: owner.display_name, email: owner.email_address } },
        permissions: file.permissions,
        folders: folder_number,
        files: file_number,
        shared: myFile.shared,
      }

      render json: file_properties

    rescue Google::Apis::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    # Funzione ricorsiva per calcolare la dimensione totale della cartella, il numero di file e cartelle
    def calculate_folder_stats(drive_service, folder_id)
      total_size = 0
      folder_count = 0
      file_count = 0

      # Ottieni tutti gli elementi nella cartella
      all_items = get_files_and_folders_in_folder(drive_service, folder_id)

      all_items.each do |item|
        if item.mime_type == 'application/vnd.google-apps.folder'
          # Se è una cartella, incremento il conteggio delle cartelle e faccio una chiamata ricorsiva
          folder_count += 1
          result = calculate_folder_stats(drive_service, item.id)
          total_size += result[:size]
          folder_count += result[:folder_count]
          file_count += result[:file_count]
        else
          # Se è un file, incremento il conteggio dei file e aggiungo la sua dimensione al totale
          file_count += 1
          total_size += item.size.to_i if item.size
        end
      end

      { size: total_size, folder_count: folder_count, file_count: file_count }
    end



    def extension
      #initialize drive service
      drive_service = initialize_drive_service

      #get file id
      file_id = params[:id]

      #save file data
      file = drive_service.get_file(file_id, fields: 'fileExtension')

      # Render the response as JSON
      file_properties = {
        type: file.file_extension,
      }
      render json: file_properties
      rescue Google::Apis::ClientError => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    def export_folder
      folder_id = params[:id]

      # Autenticazione con Google Drive API
      drive_service = initialize_drive_service

      # Crea una nuova cartella temporanea per l'esportazione
      temp_dir = Dir.mktmpdir

      # Funzione ricorsiva per scaricare i file e le sottocartelle
      def download_files_from_folder(service, folder_id, parent_path)
        # Recupera i file e le cartelle nella cartella specificata
        drive_files = get_files_and_folders_in_folder(service, folder_id)

        drive_files.each do |file|
          if file.mime_type == 'application/vnd.google-apps.folder'
            # Crea una nuova cartella nel percorso temporaneo per la sottocartella
            new_folder_path = File.join(parent_path, file.name)
            FileUtils.mkdir_p(new_folder_path)

            # Scarica i file all'interno della sottocartella
            download_files_from_folder(service, file.id, new_folder_path)
          else
            # Scarica i file all'interno della cartella corrente
            file_path = File.join(parent_path, file.name)
            begin
              service.get_file(file.id, download_dest: file_path)
            rescue Google::Apis::ClientError => e
              puts "Error downloading file: #{file.name} - #{e.message}"
              next
            end
          end
        end
      end

      # Avvia il download dei file dalla cartella principale
      download_files_from_folder(drive_service, folder_id, temp_dir)

      # Crea il file ZIP nella cartella temporanea
      zip_filename = "#{drive_service.get_file(folder_id).name}.zip"
      zip_filepath = File.join(temp_dir, zip_filename)

      # Aggiunta dei file allo ZIP mantenendo la struttura delle cartelle
      Zip::File.open(zip_filepath, Zip::File::CREATE) do |zipfile|
        Dir.glob("#{temp_dir}/**/*").each do |file|
          unless File.directory?(file)
            zipfile.add(file.sub("#{temp_dir}/", ''), file)
          end
        end
      end

      # Invia il file ZIP come risposta
      send_data(File.read(zip_filepath), type: 'application/zip', filename: zip_filename)
    ensure
      # Rimuovi la cartella temporanea
      FileUtils.remove_entry(temp_dir) if temp_dir
    end


    #carica il file su virustotal e se non è infetto lo carica su google drive
    def scan
      file_id = params[:file]
      if file_id.nil?
        redirect_to dashboard_path, alert: "Nessun file selezionato per il caricamento."
        return
      end
      @current_folder = params[:folder_id] || 'root'

      begin
        file_path = params[:file].path

        response_upload = upload_scan(file_path)

        if response_upload['data'] && response_upload['data']['id']
          scan_id = response_upload['data']['id']

          analyze_response = nil
          20.times do  # Prova per un massimo di 5 volte

            analyze_response = analyze(scan_id)
            status = analyze_response['data']['attributes']['status']
            break if ['completed', 'failed'].include?(status)
            sleep(10)  # Attendi 20 secondi tra ogni tentativo
          end

          if analyze_response['data'] && analyze_response['data']['attributes']
            if analyze_response['data']['attributes']['status'] == 'completed'
              malicious_count = analyze_response['data']['attributes']['stats']['malicious']
              if malicious_count > 0
                redirect_to dashboard_path(folder_id: @current_folder), alert: "File infetto, non è possibile caricarlo. Risulta malevolo su #{malicious_count} motori di ricerca."
              else
                upload(file_id)
                redirect_to dashboard_path(folder_id: @current_folder), notice: "File caricato con successo"
              end
            else
              redirect_to dashboard_path(folder_id: @current_folder), alert: "L'analisi non è stata completata in tempo. Per favore, riprova più tardi."
            end
          else
            error = analyze_response['error'] ? analyze_response['error']['message'] : "Errore sconosciuto durante l'analisi"
            redirect_to dashboard_path(folder_id: @current_folder), alert: "Si è verificato un errore: #{error}"
          end
        else
          error = response_upload['error'] ? response_upload['error']['message'] : "Errore sconosciuto durante il caricamento"
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

      begin
        file = File.open(file_path, 'rb')

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
        zip_buffer = create_zip_from_folder(params[:files])

        temp_file = Tempfile.new(['scan', '.zip'])
        temp_file.binmode
        temp_file.write(zip_buffer)
        temp_file.rewind

        response_upload = upload_scan(temp_file.path)

        if response_upload['data'] && response_upload['data']['id']
          scan_id = response_upload['data']['id']

          analyze_response = nil
          sleep(5)
          20.times do  # Prova per un massimo di 5 volte

            analyze_response = analyze(scan_id)
            status = analyze_response['data']['attributes']['status']
            break if ['completed', 'failed'].include?(status)
            sleep(10)  # Attendi 20 secondi tra ogni tentativo
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
        if params[:folder_id] == 'bin'
          drive_service.delete_file(item_id)
          respond_to do |format|
            format.html { redirect_to dashboard_path(folder_id: folder_id), notice: 'Elemento eliminato con successo.' }
            format.json { render json: { message: 'Elemento eliminato con successo.' }, status: :ok }
          end
          return
        end

        file_metadata = {
          trashed: true
        }
        drive_service.update_file(item_id, file_metadata, fields: 'trashed')
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

    def empty_bin
      drive_service = initialize_drive_service
      items = get_files_and_folders_in_bin(drive_service)

      items.each do |item|
        drive_service.delete_file(item.id)
      end

      redirect_to dashboard_path(folder_id: 'bin'), notice: 'Cestino svuotato con successo.'
    end

    def move_item
      drive_service = initialize_drive_service
      item_id = params[:item_id]
      folder_id = params[:folder_id]

      # Ottieni le informazioni dell'elemento
      item = drive_service.get_file(item_id, fields: 'mimeType, name')

      if item.mime_type == 'application/vnd.google-apps.folder'
        # L'elemento è una cartella

        folder_metadata = {
          name: item.name,
          mime_type: 'application/vnd.google-apps.folder',
          parents: [folder_id]
        }

        # Crea una nuova cartella in folder_id
        new_folder = drive_service.create_file(folder_metadata, fields: 'id')

        # Recupera tutti i file e cartelle all'interno della cartella originale
        child_files = drive_service.list_files(q: "'#{item_id}' in parents or sharedWithMe = true", fields: 'files(id, name)')

        # Sposta ogni file nella nuova cartella
        child_files.files.each do |child_file|
          drive_service.update_file(child_file.id, add_parents: new_folder.id, remove_parents: item_id)
        end

        drive_service.delete_file(item_id)

      else
        # L'elemento è un file

        # Sposta il file semplicemente nella cartella specificata
        drive_service.update_file(item_id, add_parents: folder_id, remove_parents: get_current_parents(drive_service, item_id))
      end
      redirect_to dashboard_path, notice: 'Elemento spostato con successo.'
    end

    def update_name
      @user = User.find(current_user.id)

      if @user.update(username: params[:username])
        render json: { success: true }
      else
        render json: { success: false }, status: :unprocessable_entity
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
          q: "'#{folder_id}' in parents and trashed = false or sharedWithMe = true",
          fields: 'nextPageToken, files(id, name, mimeType,size, parents,fileExtension,iconLink,webViewLink)',
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
          q: "name contains '#{query}' and trashed = false or sharedWithMe = true",
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
          q: 'trashed = false or sharedWithMe = true',
          fields: 'nextPageToken, files(id, name, mime_type, parents, trashed, size, created_time, modified_time, owners, permissions, shared)',
          spaces: 'drive',
          page_token: next_page_token
        )
        all_items.concat(response.files)
        next_page_token = response.next_page_token
      end while next_page_token.present?

      all_items.each do |item|
        idString = item.id.to_s
        if item.mime_type == 'application/vnd.google-apps.folder'
          unless Folder.exists?(folder_id: idString)
            Folder.create(
              folder_id: idString,
              name: item.name,
              mime_type: item.mime_type,
              size: item.size,
              owners: item.owners,
              created_time: item.created_time,
              modified_time: item.modified_time,
              permissions: item.permissions,
              shared: item.shared
            )
            Possess.create(user_id: current_user.id, folder_id: idString)
          end
        else
          unless UserFile.exists?(file_id: idString)
            UserFile.create(
              file_id: idString,
              name: item.name,
              mime_type: item.mime_type,
              size: item.size,
              created_time: item.created_time,
              modified_time: item.modified_time,
              permissions: item.permissions,
              shared: item.shared
            )
            Contains.create(file_id = idString, folder_id = item.parents[0])
          end
        end
      end



      all_items
    end

    def get_parent_folder(drive_service, folder_id)
      return if folder_id == 'root'

      folder = drive_service.get_file(folder_id, fields: 'id, name, parents')
      parents = folder.parents || []

      parents.empty? ? nil : drive_service.get_file(parents.first, fields: 'id, name')
    end

    def get_current_parents(drive_service, item_id)
      file = drive_service.get_file(item_id, fields: 'parents')
      file.parents.join(',')
    end

    def get_folder_name(drive_service, folder_id)
      folder = drive_service.get_file(folder_id, fields: 'name')
      folder.name
    end

    def get_root_name(drive_service)
      folder = drive_service.get_file('root', fields: 'name')
      folder.name
    end

    def get_root_id(drive_service)
      folder = drive_service.get_file('root', fields: 'id')
      folder.id
    end

    def create_folder_in_drive(folder_name)
      # Implementa la logica per creare una cartella in Google Drive o altro servizio
      drive_service = initialize_drive_service
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

    def fetch_google_profile_image
      auth = request.env['omniauth.auth']
      @google_profile_image = session[:image]
    end

  end
