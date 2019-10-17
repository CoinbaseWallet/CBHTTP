format:
	ios/Pods/SwiftFormat/CommandLineTool/swiftformat ios/Source --header "Copyright (c) 2017-{year} Coinbase Inc. See LICENSE"
	android/gradlew ktlintFormat -p android

lint:
	#ios/Pods/SwiftLint/swiftlint --path ios
	android/gradlew ktlint -p android

deps:
	rm -rf libraries; git submodule update --init --force --recursive
ifdef update
	# Pull latest submodule version for each submodule
	git submodule foreach 'git checkout master && git reset --hard origin/master && git pull || :'
else
  	# Pull pinned submodule version for each submodule
	git submodule foreach 'git checkout $$sha1 || :'
endif
