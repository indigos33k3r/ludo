APP = Ludo
BUNDLENAME = $(APP)-$(OS)-$(ARCH)-$(VERSION)

CORES = bluemsx fbneo fceumm gambatte genesis_plus_gx handy mednafen_ngp mednafen_pce_fast mednafen_psx mednafen_saturn mednafen_supergrafx mednafen_vb mednafen_wswan mgba np2kai o2em pcsx_rearmed picodrive pokemini prosystem snes9x stella vecx virtualjaguar

ifeq ($(ARCH), arm)
	CORES := $(filter-out mednafen_saturn,$(CORES))
endif

DYLIBS = $(addprefix cores/, $(addsuffix _libretro.dylib,$(CORES)))
DLLS = $(addprefix cores/, $(addsuffix _libretro.dll,$(CORES)))
SOBJS = $(addprefix cores/, $(addsuffix _libretro.so,$(CORES)))

ifeq ($(OS), OSX)
	BUILDBOTURL=http://buildbot.libretro.com/nightly/apple/osx/$(ARCH)/latest
endif
ifeq ($(OS), Linux)
	ifeq ($(ARCH), arm)
		BUILDBOTURL=http://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest
	else
		BUILDBOTURL=http://buildbot.libretro.com/nightly/linux/$(ARCH)/latest
	endif
endif
ifeq ($(OS), Windows)
	BUILDBOTURL=http://buildbot.libretro.com/nightly/windows/$(ARCH)/latest
endif

ludo:
	go build

ludo.exe:
	go build -ldflags '-H=windowsgui'

cores/%_libretro.dylib cores/%_libretro.dll cores/%_libretro.so:
	mkdir -p cores
	wget $(BUILDBOTURL)/$(@F).zip -O $@.zip
	unzip $@.zip -d cores
	rm $@.zip

$(APP).app: ludo $(DYLIBS)
	mkdir -p $(APP).app/Contents/MacOS
	mkdir -p $(APP).app/Contents/Resources/$(APP).iconset
	cp pkg/Info.plist $(APP).app/Contents/
	echo "APPL????" > $(APP).app/Contents/PkgInfo
	cp -r database $(APP).app/Contents/Resources
	cp -r assets $(APP).app/Contents/Resources
	cp -r cores $(APP).app/Contents/Resources
	rm -rf $(APP).app/Contents/Resources/database/.git
	rm -rf $(APP).app/Contents/Resources/assets/.git
	sips -z 16 16   assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_16x16.png
	sips -z 32 32   assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_16x16@2x.png
	sips -z 32 32   assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_32x32.png
	sips -z 64 64   assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_32x32@2x.png
	sips -z 128 128 assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_128x128.png
	sips -z 256 256 assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_128x128@2x.png
	sips -z 256 256 assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_256x256.png
	sips -z 512 512 assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_256x256@2x.png
	sips -z 512 512 assets/icon.png --out $(APP).app/Contents/Resources/$(APP).iconset/icon_512x512.png
	cp ludo $(APP).app/Contents/MacOS
	iconutil -c icns -o $(APP).app/Contents/Resources/$(APP).icns $(APP).app/Contents/Resources/$(APP).iconset
	rm -rf $(APP).app/Contents/Resources/$(APP).iconset

empty.dmg:
	mkdir -p template
	hdiutil create -fs HFSX -layout SPUD -size 200m empty.dmg -srcfolder template -format UDRW -volname $(BUNDLENAME) -quiet
	rmdir template

# For OSX
dmg: empty.dmg $(APP).app
	mkdir -p wc
	hdiutil attach empty.dmg -noautoopen -quiet -mountpoint wc
	rm -rf wc/$(APP).app
	ditto -rsrc $(APP).app wc/$(APP).app
	ln -s /Applications wc/Applications
	WC_DEV=`hdiutil info | grep wc | grep "Apple_HFS" | awk '{print $$1}'` && hdiutil detach $$WC_DEV -quiet -force
	rm -f $(BUNDLENAME)-*.dmg
	hdiutil convert empty.dmg -quiet -format UDZO -imagekey zlib-level=9 -o $(BUNDLENAME).dmg

# For Windows
zip: ludo.exe $(DLLS)
	mkdir -p $(BUNDLENAME)/
	./rcedit-x64 ludo.exe --set-icon assets/icon.ico
	cp ludo.exe $(BUNDLENAME)/
	cp -r database $(BUNDLENAME)/
	cp -r assets $(BUNDLENAME)/
	cp -r cores $(BUNDLENAME)/
	7z a $(BUNDLENAME).zip $(BUNDLENAME)\

# For Linux
tar: ludo $(SOBJS)
	mkdir -p $(BUNDLENAME)/
	cp ludo $(BUNDLENAME)/
	cp -r database $(BUNDLENAME)/
	cp -r assets $(BUNDLENAME)/
	cp -r cores $(BUNDLENAME)/
	tar -zcf $(BUNDLENAME).tar.gz $(BUNDLENAME)\

clean:
	rm -rf $(BUNDLENAME).app ludo wc empty.dmg $(BUNDLENAME).dmg $(BUNDLENAME)-* cores/
