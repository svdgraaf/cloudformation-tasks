def check_aws_credentials
  [
    'AWS_ACCOUNT',
    'AWS_ACCESS_KEY_ID',
    'AWS_SECRET_ACCESS_KEY'
  ].each do |var|
    if !ENV[var] or ENV[var].strip.empty?
      abort "ERROR: Please set '#{var}' environment variable" \
            " (in '.env.private')"
    end
  end
end

def check_packer_settings
  ['SOURCE_AMI'].each do |var|
    if !ENV[var] or ENV[var].strip.empty?
      abort "ERROR: Please set '#{var}' environment variable"
    end
  end
end

