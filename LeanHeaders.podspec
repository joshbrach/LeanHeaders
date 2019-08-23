Pod::Spec.new do |s|
    s.name           = 'LeanHeaders'
    s.version        = '1.1.0'
    s.summary        = 'A command-line tool to slim down Objective-C Header files.'
    s.homepage       = 'https://github.com/joshbrach/LeanHeaders'
    s.license        = { type: 'GPL', file: 'LICENSE' }
    s.author         = { 'Joshua Brach' => 'Josh.Brach@Gmail.com' }
    s.source         = { http: "#{s.homepage}/releases/download/#{s.version}/LeanHeaders.zip" }
    s.preserve_paths = '*'
end
