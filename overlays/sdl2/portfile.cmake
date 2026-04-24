set(SDL2_VERSION 2.0.20)
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libsdl-org/SDL
    REF 53dea9830964eee8b5c2a7ee0a65d6e268dc78a1 #vrelease-2.0.22
    SHA512 809ac18aeb739cfc6558dc11a7b3abbdad62a8e651ae2bfc157f26947b0df063a34c117ea8bd003428b5618fa6ce21a655fda073f1ef15aa34bc4a442a578523
    HEAD_REF master
    PATCHES
        0001-sdl2-Enable-creation-of-pkg-cfg-file-on-windows.patch
        0002-sdl2-skip-ibus-on-linux.patch
        0003-sdl2-disable-sdlmain-target-search-on-uwp.patch
        0004-Define-crt-macros.patch
)

if(VCPKG_TARGET_IS_OSX)
    set(SDL_DARWIN_TARGET "x86_64-apple-macos10.13")
    set(SDL_DARWIN_OBJC_FLAGS "-target ${SDL_DARWIN_TARGET} -fPIC")
    set(SDL_DARWIN_CMAKE_OPTIONS
        -DCMAKE_OSX_ARCHITECTURES=x86_64
        -DCMAKE_OBJC_FLAGS=${SDL_DARWIN_OBJC_FLAGS}
        -DCMAKE_OBJCXX_FLAGS=${SDL_DARWIN_OBJC_FLAGS}
    )

    set(SDL_CMAKELISTS_PATH "${SOURCE_PATH}/CMakeLists.txt")
    file(READ "${SDL_CMAKELISTS_PATH}" SDL_CMAKELISTS_SOURCE)
    string(REPLACE [[  check_c_compiler_flag(-Wdeclaration-after-statement HAVE_GCC_WDECLARATION_AFTER_STATEMENT)
  if(HAVE_GCC_WDECLARATION_AFTER_STATEMENT)
    check_c_compiler_flag(-Werror=declaration-after-statement HAVE_GCC_WERROR_DECLARATION_AFTER_STATEMENT)
    if(HAVE_GCC_WERROR_DECLARATION_AFTER_STATEMENT)
      list(APPEND EXTRA_CFLAGS "-Werror=declaration-after-statement")
    endif()
    list(APPEND EXTRA_CFLAGS "-Wdeclaration-after-statement")
  endif()
]]
[[  check_c_compiler_flag(-Wdeclaration-after-statement HAVE_GCC_WDECLARATION_AFTER_STATEMENT)
  if(HAVE_GCC_WDECLARATION_AFTER_STATEMENT)
    list(APPEND EXTRA_CFLAGS "-Wdeclaration-after-statement")
  endif()
]]
        SDL_CMAKELISTS_SOURCE "${SDL_CMAKELISTS_SOURCE}")
    file(WRITE "${SDL_CMAKELISTS_PATH}" "${SDL_CMAKELISTS_SOURCE}")

    set(HID_MAC_PATH "${SOURCE_PATH}/src/hidapi/mac/hid.c")
    file(READ "${HID_MAC_PATH}" HID_MAC_SOURCE)

    string(REPLACE [[static void free_hid_device(hid_device *dev)
{
	if (!dev)
		return;
	
	/* Delete any input reports still left over. */
	struct input_report *rpt = dev->input_reports;
]]
[[static void free_hid_device(hid_device *dev)
{
	struct input_report *rpt;
	if (!dev)
		return;
	
	/* Delete any input reports still left over. */
	rpt = dev->input_reports;
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")

    string(REPLACE [[static int get_string_property(IOHIDDeviceRef device, CFStringRef prop, wchar_t *buf, size_t len)
{
	CFStringRef str;
]]
[[static int get_string_property(IOHIDDeviceRef device, CFStringRef prop, wchar_t *buf, size_t len)
{
	CFStringRef str;
	CFIndex str_len;
	CFRange range;
	CFIndex used_buf_len;
	CFIndex chars_copied;
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[		CFIndex str_len = CFStringGetLength(str);
		CFRange range;
		range.location = 0;
		range.length = (str_len > len)? len: str_len;
		CFIndex used_buf_len;
		CFIndex chars_copied;
		chars_copied = CFStringGetBytes(str,
]]
[[		str_len = CFStringGetLength(str);
		range.location = 0;
		range.length = (str_len > len)? len: str_len;
		chars_copied = CFStringGetBytes(str,
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")

    string(REPLACE [[static int get_string_property_utf8(IOHIDDeviceRef device, CFStringRef prop, char *buf, size_t len)
{
	CFStringRef str;
]]
[[static int get_string_property_utf8(IOHIDDeviceRef device, CFStringRef prop, char *buf, size_t len)
{
	CFStringRef str;
	CFIndex str_len;
	CFRange range;
	CFIndex used_buf_len;
	CFIndex chars_copied;
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[		CFIndex str_len = CFStringGetLength(str);
		CFRange range;
		range.location = 0;
		range.length = (str_len > len)? len: str_len;
		CFIndex used_buf_len;
		CFIndex chars_copied;
		chars_copied = CFStringGetBytes(str,
]]
[[		str_len = CFStringGetLength(str);
		range.location = 0;
		range.length = (str_len > len)? len: str_len;
		chars_copied = CFStringGetBytes(str,
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")

    string(REPLACE [[struct hid_device_info  HID_API_EXPORT *hid_enumerate(unsigned short vendor_id, unsigned short product_id)
{
	struct hid_device_info *root = NULL; // return object
	struct hid_device_info *cur_dev = NULL;
	CFIndex num_devices;
	int i;
]]
[[struct hid_device_info  HID_API_EXPORT *hid_enumerate(unsigned short vendor_id, unsigned short product_id)
{
	struct hid_device_info *root = NULL; // return object
	struct hid_device_info *cur_dev = NULL;
	CFIndex num_devices;
	int i;
	CFSetRef device_set;
	IOHIDDeviceRef *device_array;
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[	CFSetRef device_set = IOHIDManagerCopyDevices(hid_mgr);
]]
[[	device_set = IOHIDManagerCopyDevices(hid_mgr);
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[	IOHIDDeviceRef *device_array = (IOHIDDeviceRef*)calloc(num_devices, sizeof(IOHIDDeviceRef));
]]
[[	device_array = (IOHIDDeviceRef*)calloc(num_devices, sizeof(IOHIDDeviceRef));
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")

    string(REPLACE [[static void *read_thread(void *param)
{
	hid_device *dev = (hid_device *)param;
	
	/* Move the device's run loop to this thread. */
	IOHIDDeviceScheduleWithRunLoop(dev->device_handle, CFRunLoopGetCurrent(), dev->run_loop_mode);
	
	/* Create the RunLoopSource which is used to signal the
	 event loop to stop when hid_close() is called. */
	CFRunLoopSourceContext ctx;
]]
[[static void *read_thread(void *param)
{
	hid_device *dev = (hid_device *)param;
	CFRunLoopSourceContext ctx;
	SInt32 code;
	
	/* Move the device's run loop to this thread. */
	IOHIDDeviceScheduleWithRunLoop(dev->device_handle, CFRunLoopGetCurrent(), dev->run_loop_mode);
	
	/* Create the RunLoopSource which is used to signal the
	 event loop to stop when hid_close() is called. */
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[	/* Run the Event Loop. CFRunLoopRunInMode() will dispatch HID input
	 reports into the hid_report_callback(). */
	SInt32 code;
	while (!dev->shutdown_thread && !dev->disconnected) {
]]
[[	/* Run the Event Loop. CFRunLoopRunInMode() will dispatch HID input
	 reports into the hid_report_callback(). */
	while (!dev->shutdown_thread && !dev->disconnected) {
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")

    string(REPLACE [[hid_device * HID_API_EXPORT hid_open_path(const char *path, int bExclusive)
{
  	int i;
	hid_device *dev = NULL;
	CFIndex num_devices;
]]
[[hid_device * HID_API_EXPORT hid_open_path(const char *path, int bExclusive)
{
  	int i;
	hid_device *dev = NULL;
	CFIndex num_devices;
	CFSetRef device_set;
	IOHIDDeviceRef *device_array;
	struct hid_device_list_node *node;
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[	CFSetRef device_set = IOHIDManagerCopyDevices(hid_mgr);
]]
[[	device_set = IOHIDManagerCopyDevices(hid_mgr);
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[	IOHIDDeviceRef *device_array = (IOHIDDeviceRef *)calloc(num_devices, sizeof(IOHIDDeviceRef));
]]
[[	device_array = (IOHIDDeviceRef *)calloc(num_devices, sizeof(IOHIDDeviceRef));
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")
    string(REPLACE [[				struct hid_device_list_node *node = (struct hid_device_list_node *)calloc(1, sizeof(struct hid_device_list_node));
]]
[[				node = (struct hid_device_list_node *)calloc(1, sizeof(struct hid_device_list_node));
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")

    string(REPLACE [[int HID_API_EXPORT hid_get_feature_report(hid_device *dev, unsigned char *data, size_t length)
{
	CFIndex len = length;
	IOReturn res;
	
	/* Return if the device has been unplugged. */
	if (dev->disconnected)
		return -1;
	
	int skipped_report_id = 0;
	int report_number = data[0];
]]
[[int HID_API_EXPORT hid_get_feature_report(hid_device *dev, unsigned char *data, size_t length)
{
	CFIndex len = length;
	IOReturn res;
	int skipped_report_id = 0;
	int report_number = data[0];
	
	/* Return if the device has been unplugged. */
	if (dev->disconnected)
		return -1;
]]
        HID_MAC_SOURCE "${HID_MAC_SOURCE}")

    file(WRITE "${HID_MAC_PATH}" "${HID_MAC_SOURCE}")
endif()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" SDL_STATIC)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" SDL_SHARED)
string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "static" FORCE_STATIC_VCRT)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        vulkan  SDL_VULKAN
        x11     SDL_X11_SHARED
)

if ("x11" IN_LIST FEATURES)
    message(WARNING "You will need to install Xorg dependencies to use feature x11:\nsudo apt install libx11-dev libxft-dev libxext-dev\n")
endif()

if(VCPKG_TARGET_IS_UWP)
    set(configure_opts WINDOWS_USE_MSBUILD)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    ${configure_opts}
    OPTIONS ${FEATURE_OPTIONS}
        -DSDL_STATIC=${SDL_STATIC}
        -DSDL_SHARED=${SDL_SHARED}
        -DSDL_FORCE_STATIC_VCRT=${FORCE_STATIC_VCRT}
        -DSDL_LIBC=ON
        -DSDL_HIDAPI_JOYSTICK=ON
        ${SDL_DARWIN_CMAKE_OPTIONS}
    MAYBE_UNUSED_VARIABLES
        SDL_FORCE_STATIC_VCRT
)

vcpkg_cmake_install()

if(EXISTS "${CURRENT_PACKAGES_DIR}/cmake")
    vcpkg_cmake_config_fixup(CONFIG_PATH cmake)
elseif(EXISTS "${CURRENT_PACKAGES_DIR}/lib/cmake/SDL2")
    vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/SDL2)
elseif(EXISTS "${CURRENT_PACKAGES_DIR}/SDL2.framework/Resources")
    vcpkg_cmake_config_fixup(CONFIG_PATH SDL2.framework/Resources)
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/bin/sdl2-config"
    "${CURRENT_PACKAGES_DIR}/debug/bin/sdl2-config"
    "${CURRENT_PACKAGES_DIR}/SDL2.framework"
    "${CURRENT_PACKAGES_DIR}/debug/SDL2.framework"
)

file(GLOB BINS "${CURRENT_PACKAGES_DIR}/debug/bin/*" "${CURRENT_PACKAGES_DIR}/bin/*")
if(NOT BINS)
    file(REMOVE_RECURSE
        "${CURRENT_PACKAGES_DIR}/bin"
        "${CURRENT_PACKAGES_DIR}/debug/bin"
    )
endif()

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_UWP AND NOT VCPKG_TARGET_IS_MINGW)
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/lib/manual-link")
        file(RENAME "${CURRENT_PACKAGES_DIR}/lib/SDL2main.lib" "${CURRENT_PACKAGES_DIR}/lib/manual-link/SDL2main.lib")
    endif()
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/debug/lib/manual-link")
        file(RENAME "${CURRENT_PACKAGES_DIR}/debug/lib/SDL2maind.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/manual-link/SDL2maind.lib")
    endif()

    file(GLOB SHARE_FILES "${CURRENT_PACKAGES_DIR}/share/sdl2/*.cmake")
    foreach(SHARE_FILE ${SHARE_FILES})
        vcpkg_replace_string("${SHARE_FILE}" "lib/SDL2main" "lib/manual-link/SDL2main")
    endforeach()
endif()

vcpkg_copy_pdbs()

set(DYLIB_COMPATIBILITY_VERSION_REGEX "set\\(DYLIB_COMPATIBILITY_VERSION (.+)\\)")
set(DYLIB_CURRENT_VERSION_REGEX "set\\(DYLIB_CURRENT_VERSION (.+)\\)")
file(STRINGS "${SOURCE_PATH}/CMakeLists.txt" DYLIB_COMPATIBILITY_VERSION REGEX ${DYLIB_COMPATIBILITY_VERSION_REGEX})
file(STRINGS "${SOURCE_PATH}/CMakeLists.txt" DYLIB_CURRENT_VERSION REGEX ${DYLIB_CURRENT_VERSION_REGEX})
string(REGEX REPLACE ${DYLIB_COMPATIBILITY_VERSION_REGEX} "\\1" DYLIB_COMPATIBILITY_VERSION "${DYLIB_COMPATIBILITY_VERSION}")
string(REGEX REPLACE ${DYLIB_CURRENT_VERSION_REGEX} "\\1" DYLIB_CURRENT_VERSION "${DYLIB_CURRENT_VERSION}")

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/sdl2.pc" "-lSDL2main" "-lSDL2maind")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/sdl2.pc" "-lSDL2 " "-lSDL2d ")
endif()

vcpkg_fixup_pkgconfig()

file(INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
