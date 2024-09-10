class DriveController < ApplicationController
    before_action :authenticate_user!
    before_action :fetch_google_profile_image
    before_action :check_suspension, only: [:dashboard]

    require 'google/apis/drive_v3'
    require 'googleauth'

    require 'httparty'
    require 'json'
    require 'zip'

    $current_folder = ''

    def dashboard
      $current_folder = params[:folder_id] || 'root'
      @all_items = get_files_and_folders
      puts "Current folder: #{$current_folder}"

      @root_folder_name = get_root_name
      @root_folder_id = get_root_id

      @user = current_user
      @total_space = 1
      @used_space = 0
      if @user.total_space and @user.used_space
        @total_space = @user.total_space
        @used_space = @user.used_space
      end

      if params[:folder_id] == 'bin'
        $current_folder_name = 'Cestino'
      else
        $current_folder_name = $current_folder == 'root' ? @root_folder_name : get_folder_name($current_folder)
        @parent_folder = get_parent_folder($current_folder) unless $current_folder == 'root'
      end
      if params[:search].present?
        $current_folder = 'null'
        @items = search_files(params[:search])
      else
        if params[:folder_id] == 'bin'
          $current_folder = 'bin'
          @items = get_files_and_folders_in_bin
        else
          @items = get_files_and_folders_in_folder($current_folder)
        end
      end
    end

    def setting
      # Logica per le impostazioni
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
      file = UserFile.find_by(user_file_id: file_id)
      if file
        file.update(name: new_name)
      end

      json_response = { success: true, name: new_name, message: 'Nome file aggiornato con successo.' }
      render json: json_response
    end

    def share
      # Logica per condividere l'elemento
      drive_service = initialize_drive_service
      @user = current_user

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

      temp = UserFile.find_by(user_file_id: file_id)
      if temp.nil?
        temp = UserFolder.find_by(user_folder_id: file_id)
        if temp
          ShareFolder.create(user_folder_id: temp.id, user_id: @user.id)
        end
      else
        file = UserFile.find_by(user_file_id: file_id)
        ShareFile.create(user_file_id: file.id, user_id: @user.id)
      end

      respond_to do |format|
        format.json { render json: { success: true, message: 'File condiviso con successo.' } }
      end
    end

    def export

      unless current_user.premium_valid?
        render json: { error: 'Utente non premium' }, status: :forbidden
        return
      end

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
      # Get file id
      file_id = params[:id]

      # Save file data
      myFile = UserFile.find_by(user_file_id: file_id)
      if myFile.nil?
        myFile = UserFolder.find_by(user_folder_id: file_id)
      end

      owners = []
      hasOwner = HasOwner.where(item: myFile.id)
      hasOwner.each do |owner|
        own = Owner.find_by(id: owner.owner_id)
        owners << { display_name: own.displayName, email: own.emailAddress }
      end

      permissions = []
      hasPermission = HasPermission.where(item_id: myFile.id)
      hasPermission.each do |permission|
        perm = Permission.find_by(id: permission.permission_id)
        permissions << { role: perm.role, type: perm.permission_type, email: perm.emailAddress }
      end

      if myFile.mime_type == 'application/vnd.google-apps.folder'
        # Calcola la dimensione, il numero di file e cartelle ricorsivamente
        result = calculate_folder_stats(file_id)
        total_size = result[:size]
        folder_number = result[:folder_count]
        file_number = result[:file_count]
      else
        total_size = myFile.size
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
        owners: owners,
        permissions: permissions,
        folders: folder_number,
        files: file_number,
        shared: myFile.shared,
      }

      render json: file_properties

    rescue Google::Apis::ClientError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # Funzione ricorsiva per calcolare la dimensione totale della cartella, il numero di file e cartelle
    def calculate_folder_stats(folder_id)
      total_size = 0
      folder_count = 0
      file_count = 0

      # Ottieni tutti gli elementi nella cartella
      all_items = get_files_and_folders_in_folder(folder_id)

      all_items.each do |item|
        if item.mime_type == 'application/vnd.google-apps.folder'
          # Se è una cartella, incremento il conteggio delle cartelle e faccio una chiamata ricorsiva
          folder_count += 1
          result = calculate_folder_stats(item.user_folder_id)
          total_size += result[:size]
          folder_count += result[:folder_count]
          file_count += result[:file_count]
        else
          # Se è un file, incremento il conteggio dei file e aggiungo la sua dimensione al totale
          file_count += 1
          total_size += item.size if item.size
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
        drive_files = get_files_and_folders_in_folder(folder_id)

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
      #puts "Scan action called"
      file_id = params[:file]
      if file_id.nil?
          redirect_to dashboard_path, alert: "Nessun file selezionato per il caricamento."
        return
      end

      begin
        file_path = params[:file].path

        response_upload = upload_scan(file_path)
        #puts "Response upload"
        if response_upload['data'] && response_upload['data']['id']
          scan_id = response_upload['data']['id']

          analyze_response = nil
          20.times do  # Prova per un massimo di 5 volte

            analyze_response = analyze(scan_id)
            status = analyze_response['data']['attributes']['status']
            break if ['completed', 'failed'].include?(status)
            sleep(10)  # Attendi 20 secondi tra ogni tentativo
          end
          #puts "Analyze response"
          if analyze_response['data'] && analyze_response['data']['attributes']
            if analyze_response['data']['attributes']['status'] == 'completed'
              malicious_count = analyze_response['data']['attributes']['stats']['malicious']
              if malicious_count > 0
                redirect_to dashboard_path(folder_id: $current_folder), alert: t('virus.infected1') + "#{malicious_count}" + t('virus.infected2')
              else
                unless Rails.env.test?
                  upload(file_id)
                end
                redirect_to dashboard_path(folder_id: $current_folder), notice: t('virus.success')
              end
            else
              redirect_to dashboard_path(folder_id: $current_folder), alert: t('virus.timeout')
            end
          else
            error = analyze_response['error'] ? analyze_response['error']['message'] : t('virus.error')
            redirect_to dashboard_path(folder_id: $current_folder), alert: t(virus.message) + "#{error}"
          end
        else
          error = response_upload['error'] ? response_upload['error']['message'] : t('virus.error')
          redirect_to dashboard_path(folder_id: $current_folder), alert: t(virus.message) + "#{error}"
        end
      rescue => e
        puts "Error in scan: #{e.message}"
        puts e.backtrace.join("\n")
        redirect_to dashboard_path(folder_id: $current_folder), alert: t(virus.message) + " #{e.message}"
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


    def upload(file_id)
      # Initialize the API
      drive_service = initialize_drive_service

      puts params[:file]
      metadata = {
        name: params[:file].original_filename,
        parents: [$current_folder],
        mime_type: params[:file].content_type
      }
      file = drive_service.create_file(metadata, upload_source: params[:file].tempfile, content_type: params[:file].content_type)
      puts "File uploaded to Google Drive"
      file_db = UserFile.create(user_file_id: file.id, name: file.name, size: file.size.to_i, mime_type: file.mime_type, created_time: file.created_time, modified_time: file.modified_time)
      if $current_folder == 'root'
        folder = UserFolder.find_by(mime_type: 'root')
      else
        folder = UserFolder.find_by(user_folder_id: $current_folder)
      end
      parent = Parent.find_by(itemid: folder.user_folder_id)
      HasParent.create(item_id: file_db.id, item_type: 'UserFile', parent_id: parent.id)
      Contains.create(user_folder_id: folder.id, user_file_id: file_db.id)
      #update_database
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
                redirect_to dashboard_path(folder_id: $current_folder), notice: "Cartella caricata con successo"
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
      folder_db = UserFolder.create(user_folder_id: folder.id, name: folder_name, mime_type: 'application/vnd.google-apps.folder', created_time: folder.created_time, modified_time: folder.modified_time)
      parent = Parent.create(itemid: folder.id, num: 0)
      parent_folder = UserFolder.find_by(user_folder_id: $current_folder)
      if parent_folder.nil?
        parent_folder = UserFolder.find_by(mime_type: 'root')
      end
      puts "Current folder: #{$current_folder}"
      puts "Parent folder: #{parent_folder.name}"
      folder_parent = Parent.find_by(itemid: parent_folder.user_folder_id)
      HasParent.create(item_id: folder_db.id, item_type: 'UserFolder', parent_id: folder_parent.id)

      # Itera su tutti i file nella cartella e caricali su Google Drive
      params[:files].each do |fil|
        file_metadata = {
          name: fil.original_filename,
          parents: [folder.id],
          mime_type: fil.content_type
        }
        file = drive_service.create_file(file_metadata, upload_source: fil.tempfile, content_type: fil.content_type)
        file_db = UserFile.create(user_file_id: file.id, name: file.name, size: file.size.to_i, mime_type: file.mime_type, created_time: file.created_time, modified_time: file.modified_time)
        HasParent.create(item_id: file_db.id, item_type: 'UserFile', parent_id: parent.id)
        Contains.create(user_folder_id: folder_db.id, user_file_id: file_db.id)
      end

      #redirect_to dashboard_path, notice: 'Cartella caricata su Google Drive con successo'
      #return
    end

    def create_folder
      logger.info "create_folder action called"
      folder_name = params[:folder_name]
      if folder_name.blank?
        redirect_to dashboard_path, alert: "Il nome della cartella non può essere vuoto."
        return
      end

      # Logica per creare la cartella, ad esempio tramite un'API di Google Drive
      # Supponiamo che ci sia una funzione create_folder_in_drive(folder_name) che crea la cartella
      begin
        create_folder_in_drive(folder_name)
        redirect_to dashboard_path(folder_id: $current_folder), notice: "Cartella '#{folder_name}' creata con successo."
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
        @user.update(total_space: @total_space, used_space: @used_space)

      rescue => e
        render json: { error: "Si è verificato un errore: #{e.message}" }, status: :unprocessable_entity
      end
    end

    def delete_item
      drive_service = initialize_drive_service
      item_id = params[:item_id]
      folder_id = params[:folder_id] # Recupera il parametro folder_id

      puts "Deleting item: #{item_id} from folder: #{folder_id}"

      begin
        if folder_id == 'bin'
          drive_service.delete_file(item_id)
          item = UserFile.find_by(user_file_id: item_id) || UserFolder.find_by(user_folder_id: item_id)
          delete_aux(item_id)

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
        item = UserFile.find_by(user_file_id: item_id) || UserFolder.find_by(user_folder_id: item_id)
        item.update(trashed: true)
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
      items = get_files_and_folders_in_bin

      items.each do |item|
        if item.mime_type == 'application/vnd.google-apps.folder'
          drive_service.delete_file(item.user_folder_id)
          delete_aux(item.user_folder_id)
        else
          drive_service.delete_file(item.user_file_id)
          delete_aux(item.user_file_id)
        end
      end

      redirect_to dashboard_path(folder_id: 'bin'), notice: 'Cestino svuotato con successo.'
    end

    def move_item
      drive_service = initialize_drive_service
      item_id = params[:item_id]
      folder_id = params[:folder_id]

      # Ottieni le informazioni dell'elemento
      item = drive_service.get_file(item_id, fields: 'mimeType, name, parents')
      item_db = UserFile.find_by(user_file_id: item_id) || UserFolder.find_by(user_folder_id: item_id)
      has_parents = HasParent.where(item_id: item_db.id)
      has_parents.each do |parent|
        parent.destroy
      end
      folder = UserFolder.find_by(user_folder_id: folder_id)
      parent = Parent.find_by(itemid: folder_id)
      if item_db.mime_type == 'application/vnd.google-apps.folder'
        HasParent.create(item_id: item_db.id, item_type: 'UserFolder', parent_id: parent.id)
      else
        HasParent.create(item_id: item_db.id, item_type: 'UserFile', parent_id: parent.id)
      end

      if item.mime_type == 'application/vnd.google-apps.folder'
        # L'elemento è una cartella

        folder_metadata = {
          name: item.name,
          mime_type: 'application/vnd.google-apps.folder',
          parents: [folder_id]
        }

        parents = item.parents.join(',')

        drive_service.update_file(item_id, add_parents: folder_id, remove_parents: parents)

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

    def update_db(user)
      @user = user
      update_database
    end

    private

    def initialize_drive_service
      drive_service = Google::Apis::DriveV3::DriveService.new
      drive_service.authorization = google_credentials
      drive_service
    end

    def user_folders
      all_folders = []
      possess = Possess.where(user_id: current_user.id)
      possess.each do |item|
        folder = UserFolder.find_by(id: item.user_folder_id)
        if folder
          all_folders << folder.id
        end
      end
      puts "Number of folders: #{all_folders.length}"
      all_folders
    end

    def get_files_and_folders_in_folder(folder_id)
      all_items = []
      next_page_token = nil

      folders = user_folders

      if folder_id == 'root'
        roots = UserFolder.where(mime_type: 'root')
        home = nil
        roots.each do |root|
          puts folders.include?(root.id)
          if folders.include?(root.id)
            home = root
          end
        end
        if home.nil?
          update_database
          folders = user_folders
          roots = UserFolder.where(mime_type: 'root')
          home = nil
          roots.each do |root|
            if folders.include?(root.id)
              home = root
            end
          end
        end
        parent = Parent.find_by(itemid: home.user_folder_id)
      else
        folders = UserFolder.where(user_folder_id: folder_id)
        folders.each do |folder|
          if user_folders.include?(folder.id)
            parent = Parent.find_by(itemid: folder.user_folder_id)
          end
        end
      end
      if parent.nil?
        update_database
        if folder_id == 'root'
          parent = Parent.find_by(id: 1)
        else
          parent = Parent.find_by(itemid: folder_id)
        end
      end
      has_parents = HasParent.where(parent_id: parent.id)

      has_parents.each do |item|
        if item.item_type == 'UserFile'
          file = UserFile.find_by(id: item.item_id)
          if file && !file.trashed
            all_items << file
          end
        else
          folder = UserFolder.find_by(id: item.item_id)
          if folder && !folder.trashed
            puts folder.name
            all_items << folder
          end
        end
      end

      all_items
    end

    def get_files_and_folders_in_bin()
      all_items = []

      all_items = UserFolder.where(trashed: true) + UserFile.where(trashed: true)

      all_items
    end

    def search_files(query)
      drive_service = initialize_drive_service
      all_items = []
      next_page_token = nil

      begin
        response = drive_service.list_files(
          q: "name contains '#{query}' and trashed = false or sharedWithMe = true",
          fields: 'nextPageToken, files(id, name, mimeType, parents, webViewLink, iconLink)',
          spaces: 'drive',
          page_token: next_page_token
        )
        all_items.concat(response.files)
        next_page_token = response.next_page_token
      end while next_page_token.present?

      all_items
    end

    def get_files_and_folders()
      all_items = []

      possess = Possess.where(user_id: current_user.id)
      possess.each do |item|
        folder = UserFolder.find_by(id: item.user_folder_id, trashed: false)
        if folder
          all_items << folder
          contains = Contains.where(user_folder_id: folder.id)
          contains.each do |file|
            file_db = UserFile.find_by(id: file.user_file_id, trashed: false)
            if file_db
              all_items << file_db
            end
          end
        end
      end
      all_items
    end

    def get_parent_folder(folder_id)
      return if folder_id == 'root'

      folder = UserFolder.find_by(user_folder_id: folder_id)
      return if folder.mime_type == 'root'
      hasParent = HasParent.find_by(item_id: folder.id, item_type: 'UserFolder')

      parent = Parent.find_by(id: hasParent.parent_id)

      folder = UserFolder.find_by(user_folder_id: parent.itemid)

      folder
    end

    def get_current_parents(drive_service, item_id)
      file = drive_service.get_file(item_id, fields: 'parents')
      file.parents.join(',')
    end

    def get_folder_name(folder_id)
      folder = UserFolder.find_by(user_folder_id: folder_id)
      folder.name
    end

    def get_root_name()
      folder = UserFolder.find_by(mime_type: 'root')
      if folder
        folder.name
      else
        'Root'
      end
    end

    def get_root_id()
      folder = UserFolder.find_by(mime_type: 'root')
      if folder
        folder.user_folder_id
      else
        "id"
      end
    end

    def create_folder_in_drive(folder_name)
      # Implementa la logica per creare una cartella in Google Drive o altro servizio
      drive_service = initialize_drive_service
      metadata = {
        name: folder_name,
        parents: [$current_folder],
        mime_type: "application/vnd.google-apps.folder"
      }
      file = drive_service.create_file(metadata, content_type: "application/vnd.google-apps.folder")
      UserFolder.create(user_folder_id: file.id, name: folder_name, mime_type: 'application/vnd.google-apps.folder', size: 0, created_time: Time.current, modified_time: Time.current, shared: false)
      file
    end

    def file_params
      params.require(:file)
    end

    def google_credentials
      if @user.nil?
        @user = User.find(current_user.id)
      end
      token = @user.oauth_token
      refresh_token = @user.refresh_token
      client_id = ENV['GOOGLE_CLIENT_ID']
      client_secret = ENV['GOOGLE_CLIENT_SECRET']

      client = Signet::OAuth2::Client.new(
        client_id: client_id,
        client_secret: client_secret,
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        access_token: token,
        refresh_token: refresh_token
      )
      flag = false
      if @user.nil?
        flag = true
      end
      if !flag
        flag = @user.oauth_expires_at < Time.now
      end
      if flag
        client.fetch_access_token!
        @user.update(
          oauth_token: client.access_token,
          refresh_token: client.refresh_token,
          oauth_expires_at: Time.at(client.expires_at)
        )
      end
      client
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
      # Automatically authenticate with a service token if in test mode
      if Rails.env.test?
        # Simulate a service token login in test mode
        initialize_drive_service_rspec('mydrive-430108-980acf2b30ef.json')
        return # Skip further authentication
      end
      unless logged_in?
        redirect_to '/auth/google_oauth2' and return
      end
    end

    def initialize_drive_service_rspec(config_filename)
      authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(Rails.root.join('config', config_filename)),
        scope: ['https://www.googleapis.com/auth/drive']
      )
    
      authorization.fetch_access_token!
    
      drive_service = Google::Apis::DriveV3::DriveService.new
      drive_service.authorization = authorization
    
      session[:drive_service] = drive_service
      
    end
    
    def item_params
      params.require(:item).permit(:name)
    end

    def fetch_google_profile_image
      return if Rails.env.test?
      auth = request.env['omniauth.auth']
      @google_profile_image = @current_user.profile_picture
    end

    def delete_aux(file_id)
      file = UserFile.find_by(user_file_id: file_id)
      if file.nil?
        folder1 = UserFolder.find_by(user_folder_id: file_id)
        parent1 = Parent.find_by(itemid: file_id)
        possesses1 = Possess.find_by(user_folder_id: folder1.id)
        hasOwner1 = HasOwner.where(item: folder1.id)
        hasPermission1 = HasPermission.where(item_id: folder1.id)
        shareFolder1 = ShareFolder.where(user_folder_id: folder1.id)
        hasParent = HasParent.where(parent_id: parent1.id)
        hasParent.each do |item|
          if item.item_type == 'UserFile'
            file = UserFile.find_by(id: item.item_id)
            if file
              delete_aux(file.user_file_id)
              file.destroy
            end
          else
            folder = UserFolder.find_by(user_folder_id: item.item_id)
            possesses = Possess.find_by(user_folder_id: folder.id)
            parent = Parent.find_by(itemid: folder.user_folder_id)
            hasOwner = HasOwner.where(item: folder.id)
            hasPermission = HasPermission.where(item_id: folder.id)
            shareFolder = ShareFolder.where(user_folder_id: folder.id)
            delete_aux(item.user_folder_id)
            if possesses
              possesses.destroy
            end
            if parent
              parent.destroy
            end
            hasOwner.each do |owner|
              owner.destroy
            end
            hasPermission.each do |permission|
              if permission.item_type == 'UserFolder'
                permission.destroy
              end
            end
            shareFolder.each do |share|
              share.destroy
            end
            folder.destroy
          end
          item.destroy
        end
        if possesses1
          possesses1.destroy
        end
        hasOwner1.each do |owner|
          owner.destroy
        end
        hasPermission1.each do |permission|
          if permission.item_type == 'UserFolder'
            permission.destroy
          end
        end
        shareFolder1.each do |share|
          share.destroy
        end
        if parent1
          parent1.destroy
        end
        folder1.destroy
      else
        contains = Contains.find_by(user_file_id: file.id)
        hasOwner = HasOwner.where(item: file.id)
        hasPermission = HasPermission.where(item_id: file.id)
        shareFile = ShareFile.where(user_file_id: file.id)
        hasOwner.each do |owner|
          owner.destroy
        end
        hasPermission.each do |permission|
          if permission.item_type == 'UserFile'
            permission.destroy
          end
        end
        shareFile.each do |share|
          share.destroy
        end
        contains.destroy
        file.destroy
      end
    end

    def update_database
      drive_service = initialize_drive_service
      all_items = []
      next_page_token = nil

      begin
        response = drive_service.list_files(
          q: 'trashed = false or trashed = true or sharedWithMe = true',
          fields: 'nextPageToken, files(id, name, mime_type, parents, trashed, size, created_time, modified_time, owners, permissions, shared, webViewLink, iconLink, fileExtension)',
          spaces: 'drive',
          page_token: next_page_token
        )
        all_items.concat(response.files)
        next_page_token = response.next_page_token
      end while next_page_token.present?

      storage_info

      rootFolder = drive_service.get_file('root', fields: 'id, name, parents, trashed, size, created_time, modified_time, shared')

      root = UserFolder.find_by(user_folder_id: rootFolder.id)
      if root.nil?
        folder = UserFolder.create(user_folder_id: rootFolder.id, name: rootFolder.name, mime_type: 'root', size: rootFolder.size.to_i, created_time: rootFolder.created_time, modified_time: rootFolder.modified_time, shared: rootFolder.shared)
        Possess.create(user_id: @user.id, user_folder_id: folder.id)
      end

      all_items.each do |item|
        idString = item.id.to_s
        if item.mime_type == 'application/vnd.google-apps.folder'
          UserFolder.upsert({
            user_folder_id: idString,
            name: item.name,
            mime_type: item.mime_type,
            size: item.size.to_i,
            created_time: item.created_time,
            modified_time: item.modified_time,
            shared: item.shared,
            trashed: item.trashed,
            created_at: item.created_time,  # Aggiungi questo
            updated_at: item.modified_time   # Aggiungi questo
          }, unique_by: :user_folder_id)
          Parent.upsert({
            itemid: idString,
            num: 0,
            created_at: item.created_time,  # Aggiungi questo
            updated_at: item.modified_time   # Aggiungi questo
          }, unique_by: :itemid)
        else
          UserFile.upsert({
            user_file_id: idString,
            name: item.name,
            mime_type: item.mime_type,
            size: item.size.to_i,
            created_time: item.created_time,
            modified_time: item.modified_time,
            shared: item.shared,
            web_view_link: item.web_view_link,
            icon_link: item.icon_link,
            file_extension: item.file_extension,
            trashed: item.trashed,
            created_at: item.created_time,  # Aggiungi questo
            updated_at: item.modified_time   # Aggiungi questo
          }, unique_by: :user_file_id)
        end

        temp = 0
        itemid = UserFolder.find_by(user_folder_id: idString) || UserFile.find_by(user_file_id: idString)

        if itemid.mime_type == 'application/vnd.google-apps.folder'
          id = itemid.id
        else
          id = itemid.id
        end

        if item.parents
          item.parents.each do |parent|
            if item.mime_type == 'application/vnd.google-apps.folder'
              puts "parent " + parent.to_s
              puts "son " + item.name
            end
            result = Parent.upsert({
              itemid: parent.to_s,
              num: temp,
              created_at: item.created_time,  # Aggiungi questo
              updated_at: item.modified_time   # Aggiungi questo
            }, unique_by: :itemid)
            if result
              temp += 1
            end

            parent = Parent.find_by(itemid: parent.to_s)

            if item.mime_type == 'application/vnd.google-apps.folder'
              result = HasParent.upsert({
                item_id: id,
                parent_id: parent.id,
                item_type: 'UserFolder',
                created_at: item.created_time,  # Aggiungi questo
                updated_at: item.modified_time   # Aggiungi questo
              }, unique_by: %i[item_id parent_id item_type])
            else
              result = HasParent.upsert({
                item_id: id,
                parent_id: parent.id,
                item_type: 'UserFile',
                created_at: item.created_time,  # Aggiungi questo
                updated_at: item.modified_time   # Aggiungi questo
              }, unique_by: %i[item_id parent_id item_type])
            end
          end
        end

        if item.permissions
          item.permissions.each do |permission|
            Permission.upsert({
              permission_id: permission.id.to_s,
              permission_type: permission.type,
              role: permission.role,
              emailAddress: permission.email_address,
              created_at: item.created_time,  # Aggiungi questo
              updated_at: item.modified_time   # Aggiungi questo
            }, unique_by: :permission_id)
            permiss = Permission.find_by(permission_id: permission.id.to_s)
            if item.mime_type == 'application/vnd.google-apps.folder'
              hp = HasPermission.upsert({
                item_id: id,
                permission_id: permiss.id,
                item_type: 'UserFolder',
                created_at: item.created_time,  # Aggiungi questo
                updated_at: item.modified_time   # Aggiungi questo
              }, unique_by: %i[item_id permission_id item_type])
            else
              hp = HasPermission.upsert({
                item_id: id,
                permission_id: permiss.id,
                item_type: 'UserFile',
                created_at: item.created_time,  # Aggiungi questo
                updated_at: item.modified_time   # Aggiungi questo
              }, unique_by: %i[item_id permission_id item_type])
            end
          end
        end

        if item.owners
          item.owners.each do |owner|
            Owner.upsert({
              displayName: owner.display_name,
              emailAddress: owner.email_address,
              created_at: item.created_time,  # Aggiungi questo
              updated_at: item.modified_time   # Aggiungi questo
            }, unique_by: :emailAddress)

            ow = Owner.find_by(displayName: owner.display_name, emailAddress: owner.email_address)

            HasOwner.upsert({
              item: id,
              owner_id: ow.id,
              created_at: item.created_time,  # Aggiungi questo
              updated_at: item.modified_time   # Aggiungi questo
            }, unique_by: %i[item owner_id])
          end
        end
      end

      all_items.each do |item|
        idString = item.id.to_s
        user = @user
        if item.mime_type == 'application/vnd.google-apps.folder'
          folder = UserFolder.find_by(user_folder_id: idString)
          Possess.upsert({
            user_id: user.id,
            user_folder_id: folder.id,
            created_at: item.created_time,  # Aggiungi questo
            updated_at: item.modified_time   # Aggiungi questo
          }, unique_by: %i[user_id user_folder_id])
        end

        if item.parents
          parent = UserFolder.find_by(user_folder_id: item.parents[0])
          file = UserFile.find_by(user_file_id: idString)
          if parent && file
            Contains.upsert({
              user_folder_id: parent.id,
              user_file_id: file.id,
              created_at: item.created_time,  # Aggiungi questo
              updated_at: item.modified_time   # Aggiungi questo
            }, unique_by: %i[user_folder_id user_file_id])
          end
        end

      end
    end

    #controllo sospensione
    def check_suspension
      @user = current_user
      if @user.suspended
        if @user.end_suspend < Time.now
          @user.update(suspended: false,end_suspend: nil)
        else
          redirect_to root_path, alert: t('admin.suspend-message') + current_user.end_suspend.strftime("%d/%m/%Y")
        end
      end
    end

  end
