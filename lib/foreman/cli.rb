require "foreman"
require "foreman/helpers"
require "foreman/engine"
require "foreman/engine/cli"
require "foreman/export"
require "foreman/version"
require "shellwords"
require "yaml"
require "foreman/vendor/thor/lib/thor"

class Foreman::CLI < Foreman::Thor

  include Foreman::Helpers

  map ["-v", "--version"] => :version

  class_option :procfile, :type => :string, :aliases => "-f", :desc => "Default: Procfile"
  class_option :root,     :type => :string, :aliases => "-d", :desc => "Default: Procfile directory"

  desc "start [PROCESS]", "Start the application (or a specific PROCESS)"

  method_option :color,     :type => :boolean, :aliases => "-c", :desc => "Force color to be enabled"
  method_option :env,       :type => :string,  :aliases => "-e", :desc => "Specify an environment file to load, defaults to .env"
  method_option :formation, :type => :string,  :aliases => "-m", :banner => '"alpha=5,bar=3"', :desc => 'Specify what processes will run and how many. Default: "all=1"'
  method_option :timeout,   :type => :numeric, :aliases => "-t", :desc => "Specify the amount of time (in seconds) processes have to shutdown gracefully before receiving a SIGKILL, defaults to 5."
  method_option :timestamp, :type => :boolean, :default => true, :desc => "Include timestamp in output"

  class << self
    # Hackery. Take the run method away from Thor so that we can redefine it.
    def is_thor_reserved_word?(word, type)
      return false if word == "run"
      super
    end
  end

  def start(process=nil)
    check_procfile!
    load_environment!
    engine.load_procfile(procfile)
    engine.options[:formation] = "#{process}=1" if process
    engine.start
  rescue Foreman::Procfile::EmptyFileError
    error "no processes defined"
  end

  desc "check", "Validate your application's Procfile"

  def check
    check_procfile!
    engine.load_procfile(procfile)
    puts "valid procfile detected (#{engine.process_names.join(', ')})"
  rescue Foreman::Procfile::EmptyFileError
    error "no processes defined"
  end

  no_tasks do
    def engine
      @engine ||= begin
        engine_class = Foreman::Engine::CLI
        engine = engine_class.new(options)
        engine
      end
    end
  end

private ######################################################################

  def error(message)
    puts "ERROR: #{message}"
    exit 1
  end

  def check_procfile!
    error("#{procfile} does not exist.") unless File.file?(procfile)
  end

  def load_environment!
    if options[:env]
      options[:env].split(",").each do |file|
        engine.load_env file
      end
    else
      default_env = File.join(engine.root, ".env")
      engine.load_env default_env if File.file?(default_env)
    end
  end

  def procfile
    case
      when options[:procfile] then options[:procfile]
      when options[:root]     then File.expand_path(File.join(options[:root], "Procfile"))
      else "Procfile"
    end
  end

  def options
    original_options = super
    return original_options unless File.file?(".foreman")
    defaults = ::YAML::load_file(".foreman") || {}
    Foreman::Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
  end
end
