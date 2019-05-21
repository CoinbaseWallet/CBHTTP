platform :ios, '10.0'

def common_pods
  use_frameworks!

  pod 'RxSwift', '~> 4.4.0'
  pod 'RxCocoa', '~> 4.4.0'
  pod 'Starscream', '~> 3.1'
end

target 'CBHTTP' do
  common_pods
end

target 'CBHTTPTests' do
  common_pods
  pod 'Quick', '~> 1.3.2'
  pod 'Nimble', '~> 7.3.1'
  pod 'RxBlocking', '~> 4.3.1'
  pod 'OHHTTPStubs/Swift'
end
