#!/usr/bin/env ruby
require 'fileutils'
# Generate a buildable iOS app + keyboard extension project for clones/ios_native.
# Safe to re-run: it deletes and recreates the .xcodeproj.
require 'xcodeproj'
require 'pathname'

root = File.expand_path('../clones/ios_native', __dir__)
project_path = File.join(root, 'DoubaoInput.xcodeproj')
FileUtils.rm_rf(project_path)
project = Xcodeproj::Project.new(project_path)

app_target = project.new_target(:application, 'DoubaoInput', :ios, '15.0')
kb_target = project.new_target(:app_extension, 'Keyboard', :ios, '15.0')

def add_sources(project, target, paths)
  paths.sort.each do |rel|
    ref = project.main_group.new_file(rel)
    target.source_build_phase.add_file_reference(ref)
  end
end

def add_resources(project, target, paths)
  paths.sort.each do |rel|
    ref = project.main_group.new_file(rel)
    target.resources_build_phase.add_file_reference(ref)
  end
end

app_sources = Dir.chdir(root) { Dir['DoubaoInput/**/*.swift'] }
shared_sources = Dir.chdir(root) { Dir['Shared/**/*.swift'] }
kb_sources = Dir.chdir(root) { Dir['Keyboard/**/*.swift'] }

add_sources(project, app_target, app_sources + shared_sources)
add_sources(project, kb_target, kb_sources + shared_sources)
add_resources(project, app_target, ['Shared/pinyin_dict.json'])
add_resources(project, kb_target, ['Shared/pinyin_dict.json'])

[app_target, kb_target].each do |t|
  t.build_configurations.each do |c|
    c.build_settings['SWIFT_VERSION'] = '5.0'
    c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    c.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    c.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    c.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    c.build_settings['CODE_SIGN_IDENTITY'] = ''
    c.build_settings['DEVELOPMENT_TEAM'] = ''
    c.build_settings['ENABLE_BITCODE'] = 'NO'
    c.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  end
end

app_target.build_configurations.each do |c|
  c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.huapohen.doubaoinput.ios'
  c.build_settings['INFOPLIST_FILE'] = 'DoubaoInput/Info.plist'
  c.build_settings['PRODUCT_NAME'] = 'DoubaoInput'
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = ''
  c.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = ''
  c.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
end

kb_target.build_configurations.each do |c|
  c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.huapohen.doubaoinput.ios.keyboard'
  c.build_settings['INFOPLIST_FILE'] = 'Keyboard/Info.plist'
  c.build_settings['PRODUCT_NAME'] = 'Keyboard'
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = ''
  c.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  c.build_settings['SKIP_INSTALL'] = 'YES'
  c.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  c.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
end

app_target.add_dependency(kb_target)
embed = app_target.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
embed.add_file_reference(kb_target.product_reference)

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.add_build_target(kb_target)
scheme.set_launch_target(app_target)
scheme.save_as(project_path, 'DoubaoInput', true)

puts "generated #{project_path}"
puts "app sources: #{app_sources.size}, shared: #{shared_sources.size}, keyboard: #{kb_sources.size}"
