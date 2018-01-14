module OdaniaStaticPages
	module Deploy
		class Rsync
			def initialize
				@config = OdaniaStaticPages.config
				@deploy_config = @config.current_environment.deploy_module
				@generator_config = @config.generator
				@local_state = '_local_state.yml'
			end

			def prepare
				puts 'Preparing rsync state'
				load_state
				save_state
			end

			def publish(color, do_rebuild)
				puts 'Rsync website'
				load_state
				color = color.nil? ? @state[:color] : color
				new_color = 'green'.eql?(color) ? 'blue' : 'green'
				puts " -> Current color: #{color}"
				@site_path = @config.output_site_path
				puts " -> Deploying to color: #{new_color} [Path: #{@site_path}]"

				@deploy_config.targets[new_color].each do |target|
					puts
					puts
					puts "Syncing target #{target} " + '-' * 50

					cmd = "cd #{@site_path} && rsync #{@deploy_config.rsync_options} . #{target}"
					puts "Executing: #{cmd}"
					puts `#{cmd}`.split("\n").join("\n    ")

					unless $?.success?
						puts 'Error during rsync!!'
						exit 1
					end
				end

				@state[:color] = new_color
				save_state

				@config.current_environment.do_notify new_color, color
				puts
				puts "Finished deploying color #{new_color}"
			end

			private

			def load_state
				@state = {color: 'blue'}
				cmd = "rsync #{@deploy_config.state_file} #{@local_state}"
				puts "Syncing state: #{cmd}"
				puts `#{cmd}`

				@state = YAML.load_file(@local_state).symbolize_keys! if $?.success?
				@state
			end

			def save_state
				File.write @local_state, YAML.dump(@state)
				cmd = "rsync #{@local_state} #{@deploy_config.state_file}"
				puts "Syncing state: #{cmd}"
				puts `#{cmd}`

				unless $?.success?
					puts 'Error saving state!!'
					exit 1
				end
			end
		end
	end
end
