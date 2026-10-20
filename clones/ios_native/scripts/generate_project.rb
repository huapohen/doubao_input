#!/usr/bin/env ruby
# Generates DoubaoInput.xcodeproj with the app + keyboard extension targets.
# Requires the xcodeproj gem (gem install --user-install xcodeproj).
ENV['GEM_HOME'] ||= File.expand_path('~/.gem/ruby/2.6.0')
ENV['GEM_PATH'] ||= "#{ENV['GEM_HOME']}:/Library/Ruby/Gems/2.6.0:/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/gems/2.6.0"
require 'xcodeproj'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'DoubaoInput.xcodeproj')
FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes['LastUpgradeCheck'] = '1600'
project.root_object.attributes['ORGANIZATIONNAME'] = 'Clean Room Clone'

app_group = project.main_group.new_group('DoubaoInput', 'DoubaoInput')
keyboard_group = project.main_group.new_group('Keyboard', 'Keyboard')
shared_group = project.main_group.new_group('Shared', 'Shared')

app_files = Dir.glob(File.join(ROOT, 'DoubaoInput', '*.swift')).sort.map { |p| File.basename(p) }
keyboard_files = Dir.glob(File.join(ROOT, 'Keyboard', '*.swift')).sort.map { |p| File.basename(p) }
shared_files = Dir.glob(File.join(ROOT, 'Shared', '**', '*.swift')).sort.map { |p| p.sub(ROOT + '/', '') }

app_refs = app_files.map { |name| app_group.new_reference(name) }
keyboard_refs = keyboard_files.map { |name| keyboard_group.new_reference(name) }
shared_refs = shared_files.map do |relative|
  parts = relative.split('/') # Shared/Settings/AppSettings.swift
  group = shared_group
  parts[1..-2].each do |component|
    group = group.groups.find { |g| g.name == component } || group.new_group(component, component)
  end
  group.new_reference(parts.last)
end

dict_ref = shared_group.new_reference('pinyin_dict.json')

app_target = project.new_target(:application, 'DoubaoInput', :ios, '15.0')
ext_target = project.new_target(:app_extension, 'DoubaoKeyboard', :ios, '15.0')

app_target.add_file_references(app_refs + shared_refs)
ext_target.add_file_references(keyboard_refs + shared_refs)
app_target.resources_build_phase.add_file_reference(dict_ref)
ext_target.resources_build_phase.add_file_reference(dict_ref)

app_target.add_dependency(ext_target)
embed_phase = app_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.symbol_dst_subfolder_spec = :plug_ins
build_file = embed_phase.add_file_reference(ext_target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }

common = {
  'SWIFT_VERSION' => '5.0',
  'IPHONEOS_DEPLOYMENT_TARGET' => '15.0',
  'TARGETED_DEVICE_FAMILY' => '1,2',
  'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
  'SUPPORTS_MACCATALYST' => 'NO',
  'GENERATE_INFOPLIST_FILE' => 'NO',
  'MARKETING_VERSION' => '1.5.2',
  'CURRENT_PROJECT_VERSION' => '20261020',
  'CODE_SIGN_STYLE' => 'Automatic',
  'SWIFT_EMIT_LOC_STRINGS' => 'NO',
  'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
  'CLANG_ENABLE_MODULES' => 'YES'
}

app_target.build_configurations.each do |config|
  config.build_settings.merge!(common)
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.huapohen.doubaoinput.ios',
    'PRODUCT_NAME' => 'DoubaoInput',
    'INFOPLIST_FILE' => 'DoubaoInput/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'DoubaoInput/DoubaoInput.entitlements',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks',
    'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => ''
  )
end

ext_target.build_configurations.each do |config|
  config.build_settings.merge!(common)
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.huapohen.doubaoinput.ios.keyboard',
    'PRODUCT_NAME' => 'DoubaoKeyboard',
    'INFOPLIST_FILE' => 'Keyboard/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'Keyboard/Keyboard.entitlements',
    'SKIP_INSTALL' => 'YES',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  )
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.add_build_target(ext_target)
scheme.set_launch_target(app_target)
scheme.save_as(PROJECT_PATH, 'DoubaoInput', true)

puts "Generated #{PROJECT_PATH}"
puts "App sources: #{app_files.count}, keyboard: #{keyboard_files.count}, shared: #{shared_files.count}"
