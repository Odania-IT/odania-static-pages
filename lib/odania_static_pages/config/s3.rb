module OdaniaStaticPages
	class Config
		module Deploy
			class S3
				attr_reader :bucket_name_green, :bucket_name_blue, :logging_bucket, :state_bucket, :region, :profile

				def initialize(bucket_name_green: 'odania-http-green', bucket_name_blue: 'odania-http-blue',
											 logging_bucket: 'odania-logging', region: 'eu-central-1', state_bucket: 'odania-state',
											 profile: nil, tags: {deployed_by: 'odania-static-pages'})
					@bucket_name_green = bucket_name_green
					@bucket_name_blue = bucket_name_blue
					@logging_bucket = logging_bucket
					@state_bucket = state_bucket
					@region = region
					@profile = profile
					@tags = tags
				end

				def to_h
					{
						bucket_name_green: @bucket_name_green,
						bucket_name_blue: @bucket_name_blue,
						logging_bucket: @logging_bucket,
						state_bucket: @state_bucket,
						region: @region,
						profile: @profile,
						tags: @tags.stringify_keys!
					}.stringify_keys!
				end

				def tags
					result = []
					@tags.each_pair do |key, val|
						result << {key: key, value: val}
					end
					result
				end
			end
		end
	end
end
