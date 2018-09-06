require 'i18n/locale_file_checker'
require 'colored2'

desc "Checks locale files for errors"
task "i18n:check", [:locale] => [:environment] do |_, args|
  failed_locales = []

  if args[:locale].present?
    if LocaleSiteSetting.valid_value?(args[:locale])
      locales = [args[:locale]]
    else
      puts "ERROR: #{locale} is not a valid locale"
      exit 1
    end
  else
    locales = LocaleSiteSetting.supported_locales
  end

  locales.each do |locale|
    begin
      all_errors = LocaleFileChecker.new.check(locale)
    rescue
      failed_locales << locale
      next
    end

    all_errors.each do |filename, errors|
      puts "", "=" * 80
      puts filename.bold
      puts "=" * 80

      errors.each do |error|
        message =
          case error[:type]
          when LocaleFileChecker::TYPE_MISSING_INTERPOLATION_KEYS
            "Missing interpolation keys".red
          when LocaleFileChecker::TYPE_UNSUPPORTED_INTERPOLATION_KEYS
            "Unsupported interpolation keys".red
          when LocaleFileChecker::TYPE_MISSING_PLURAL_KEYS
            "Missing plural keys".yellow
          end
        details = error[:details] ? ": #{error[:details]}" : ""

        puts error[:key] << " -- " << message << details
      end
    end
  end

  failed_locales.each do |failed_locale|
    puts "", "Failed to check locale files for #{failed_locale}".red
  end
  exit 1 unless failed_locales.empty?
end