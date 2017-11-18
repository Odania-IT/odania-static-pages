module OdaniaStaticPages
	module Deploy
		class S3
			def initialize
				@config = OdaniaStaticPages.config
				@s3_config = @config.current_environment.deploy_module
				params = {
					region: @s3_config.region
				}
				params[:profile] = @s3_config.profile unless @s3_config.profile.nil?

				puts "Configuring AWS with params: #{params}"
				Aws.config.update(params)
			end

			def prepare
				tags = @s3_config.tags
				logging_stack_name = 'odania-logging'
				params = {
					BucketName: @s3_config.logging_bucket
				}
				Stacker.create_or_update_stack(logging_stack_name, File.join(@config.base_dir, 'cf-templates', 's3-logging.yml'), params, nil, nil, tags)

				params = {
					BucketName: @s3_config.state_bucket
				}
				Stacker.create_or_update_stack('odania-state', File.join(@config.base_dir, 'cf-templates', 's3-state.yml'), params, nil, nil, tags)

				params = {
					BucketNameGreen: @s3_config.bucket_name_green,
					BucketNameBlue: @s3_config.bucket_name_blue,
					LoggingStackName: logging_stack_name
				}
				Stacker.create_or_update_stack('odania-static-http', File.join(@config.base_dir, 'cf-templates', 's3-http.yml'), params, logging_stack_name, nil, tags)
			end

			def publish(color)
				puts 'Publishing website to s3'
				load_state
				color = color.nil? ? @state[:color] : color
				new_color = 'green'.eql?(color) ? 'blue' : 'green'
				puts " -> Current color: #{color}"
				@site_path = @config.output_site_path
				puts " -> Deploying to color: #{new_color} [Path: #{@site_path}]"

				@uploaded_files = []
				bucket_name = 'green'.eql?(new_color) ? @s3_config.bucket_name_green : @s3_config.bucket_name_blue
				recursive_file_upload bucket_name, @site_path
				delete_not_uploaded_files bucket_name

				@state[:color] = new_color
				save_state

				url = bucket_url bucket_name

				@config.current_environment.do_notify new_color, color
				puts
				puts "Finished deploying color #{new_color} to bucket #{bucket_name}"
				puts "Public url: #{url}"
			end

			private

			def client
				@s3_client = Aws::S3::Client.new if @s3_client.nil?
				@s3_client
			end

			def bucket_url(bucket_name)
				bucket = Aws::S3::Bucket.new bucket_name
				bucket.url
			end

			def s3_exists?(bucket, key)
				result = client.list_objects({bucket: bucket, prefix: key})

				result.contents.each do |content|
					return true if key.eql? content.key
				end

				false
			end

			def s3_files_in_bucket(bucket)
				is_truncated = true
				next_marker = nil
				result = []

				while is_truncated
					params = {bucket: bucket}
					params[:next_marker] = next_marker unless next_marker.nil?
					response = client.list_objects(params)

					response.contents.each do |content|
						result << content.key
					end

					next_marker = response.next_marker
					is_truncated = response.is_truncated
				end

				result
			end

			def recursive_file_upload(bucket, path)
				Dir.glob(File.join(path, '**')).each do |file|
					if File.directory? file
						recursive_file_upload bucket, file
					else
						target_file = file.gsub("#{@site_path}/", '')
						content_type = MimeMagic.by_extension File.extname file
						@uploaded_files << target_file
						puts "  *> #{file} => #{target_file} [Content-Type: #{content_type}]"

						File.open(file, 'rb') do |opened_file|
							client.put_object({
								acl: 'public-read',
								bucket: bucket,
								key: target_file,
								body: opened_file,
								content_type: content_type.to_s,
								server_side_encryption: 'AES256'
							})
						end
					end
				end
			end

			def delete_not_uploaded_files(bucket)
				s3_files = s3_files_in_bucket bucket

				new_files = @uploaded_files - s3_files
				files_to_delete = s3_files - @uploaded_files

				puts '*'*100
				puts @uploaded_files
				puts '*'*100
				puts s3_files
				puts '*'*100
				puts "New Files: #{new_files}"
				puts '*'*100
				puts "Files to delete: #{files_to_delete}"
			end

			def load_state
				@state = {color: 'blue'}
				if s3_exists?(@s3_config.state_bucket, 'state.yml')
					response = client.get_object({bucket: @s3_config.state_bucket, key: 'state.yml'})
					@state = YAML.load response.body.read
				end

				@state
			end

			def save_state
				client.put_object({
						bucket: @s3_config.state_bucket,
						key: 'state.yml',
						body: YAML.dump(@state),
						server_side_encryption: 'AES256'
				})
			end
		end
	end
end
