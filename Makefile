.PHONY: default clean swiftbuild swifttest sync_linuxmain sync_xcodeproj test

default: sync_linuxmain sync_xcodeproj swiftbuild

clean:
	swift package clean

swiftbuild:
	swift build

swifttest: sync_linuxmain
	swift test

sync_linuxmain:
	swift test --generate-linuxmain

sync_xcodeproj: 
	swift package generate-xcodeproj

test: swifttest
