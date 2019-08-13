Haml::Filters.register_tilt_filter 'AsciiDoc'
Haml::Filters::AsciiDoc.options[:safe] = :safe
Haml::Filters::AsciiDoc.options[:attributes] ||= {}
Haml::Filters::AsciiDoc.options[:attributes]['notitle!'] = ''
Haml::Filters::AsciiDoc.options[:attributes]['allow-uri-read'] = ''
