require 'digest/md5'
require 'fileutils'
require 'tempfile'
require 'yaml'

abort 'Usage: ruby Clash/migrate-rule-cache.rb MIHOMO_HOME' unless ARGV.size == 1

mihomo_home = File.expand_path(ARGV.first)
abort "Mihomo home directory does not exist: #{mihomo_home}" unless Dir.exist?(mihomo_home)

template = File.join(__dir__, 'config', 'base.yml')
providers = YAML.safe_load(File.read(template), aliases: true).fetch('rule-providers')
missing = []

providers.each do |name, provider|
  path = provider['path']
  next unless provider['type'] == 'http' && path&.start_with?('./rule_provider/')

  destination = File.join(mihomo_home, path)
  next if File.size?(destination) && File.file?(destination)

  if File.exist?(destination) || File.symlink?(destination)
    missing << name
    next
  end

  source = File.join(mihomo_home, 'rules', Digest::MD5.hexdigest(provider.fetch('url')))
  unless File.file?(source) && File.size?(source)
    missing << name
    next
  end

  cache_dir = File.dirname(destination)
  FileUtils.mkdir_p(cache_dir)
  Tempfile.create('.rule-cache-', cache_dir) do |temporary|
    FileUtils.copy_file(source, temporary.path, true)
    begin
      File.link(temporary.path, destination)
      puts "Copied #{name}"
    rescue Errno::EEXIST
      missing << name unless File.file?(destination) && File.size?(destination)
    end
  end
end

abort "No usable cache copied or found for: #{missing.join(', ')}" unless missing.empty?
