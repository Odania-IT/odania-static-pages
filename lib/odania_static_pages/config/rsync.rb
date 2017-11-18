module OdaniaStaticPages
	class Config
		module Deploy
			class Rsync
				attr_reader :targets, :rsync_options, :state_file

				def initialize(targets: {green: '/tmp/rsync-deploy-test/blue', blue: '/tmp/rsync-deploy-test/blue'},
											 rsync_options: '-a --delete', state_file: '_current_state.yml')
					@targets = targets
					@rsync_options = rsync_options
					@state_file = state_file
				end

				def to_h
					{
						targets: @targets,
						rsync_options: @rsync_options,
						state_file: @state_file
					}.stringify_keys!
				end
			end
		end
	end
end
