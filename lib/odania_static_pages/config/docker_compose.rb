module OdaniaStaticPages
	class Config
		module Deploy
			class DockerCompose
				attr_reader :state_file, :compose_images, :expires, :varnish_secret

				def initialize(state_file: 'docker_compose_state.yml', compose_images: [], expires: '-1', varnish_secret: nil)
					@state_file = state_file
					@compose_images = compose_images
					@expires = expires
					@varnish_secret = varnish_secret.nil? ? SecureRandom.hex : varnish_secret
				end

				def to_h
					{
						state_file: @state_file,
						compose_images: @compose_images,
						expires: @expires
					}.stringify_keys!
				end
			end
		end
	end
end
