Pod::Spec.new do |s|
  s.name             = 'CBHTTP'
  s.version          = '0.1.0'
  s.summary          = 'A simple networking library'
  s.description      = 'A simple networking library. Developed by Coinbase Wallet team.'

  s.homepage         = 'https://github.com/CoinbaseWallet/CBHTTP'
  s.license          = { :type => "AGPL-3.0-only", :file => 'LICENSE' }
  s.author           = { 'Coinbase' => 'developer@toshi.org' }
  s.source           = { :git => 'https://github.com/CoinbaseWallet/CBHTTP.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/coinbase'

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.0'
  s.source_files = 'CBHTTP/**/*.swift'

  s.dependency 'RxSwift', '~> 4.3.0'
  s.dependency 'RxCocoa', '~> 4.3.0'
  s.dependency 'Starscream', '~> 3.0.2'
end
