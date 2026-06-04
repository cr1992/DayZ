# 幂等地为 iOS Runner 工程接入 Patrol 所需的 RunnerUITests（UI Testing Bundle）target，
# 并把它挂进 Runner scheme 的 TestAction。避免手改 project.pbxproj（极易崩）。
#
# 为什么要这个脚本：Patrol 的 iOS 接入需要一个 UITest target，正常是 Xcode GUI 手点
# (File ▸ New ▸ Target ▸ UI Testing Bundle)。本脚本用 CocoaPods 自带的 xcodeproj gem
# 程序化完成，可复现、可重跑。配套还需：
#   1) ios/RunnerUITests/RunnerUITests.m（@import patrol; + PATROL_INTEGRATION_TEST_IOS_RUNNER 宏）
#   2) ios/Podfile 里 target 'Runner' 内嵌套  target 'RunnerUITests' do inherit! :complete end
#   3) pod install
#
# 跑法（xcodeproj 藏在 CocoaPods 的 GEM_HOME 里，系统 ruby 默认找不到）：
#   GEM_HOME=$(dirname $(dirname $(gem which cocoapods 2>/dev/null)) 2>/dev/null) \
#   ruby scripts/setup_patrol_ios.rb
# 实测可用的写法（Homebrew CocoaPods 1.16.x）：
#   GEM_HOME="$(brew --prefix)/Cellar/cocoapods/<ver>/libexec" GEM_PATH="$GEM_HOME" \
#   ruby scripts/setup_patrol_ios.rb
#
# 从仓库根目录运行。

require 'xcodeproj'

PROJECT_PATH = 'ios/Runner.xcodeproj'
UITEST_NAME = 'RunnerUITests'
BUNDLE_ID = 'com.dayz.RunnerUITests'
DEPLOYMENT_TARGET = '13.0'

project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner

# 幂等：已存在则先移除再重建
project.targets.find { |t| t.name == UITEST_NAME }&.remove_from_project

uitest = project.new_target(:ui_test_bundle, UITEST_NAME, :ios, DEPLOYMENT_TARGET)

# 源文件分组 + 桥接 .m（路径相对 ios/）
group = project.main_group.find_subpath(UITEST_NAME, true)
group.set_source_tree('SOURCE_ROOT')
group.set_path(UITEST_NAME)
uitest.add_file_references([group.new_reference("#{UITEST_NAME}.m")])

uitest.add_dependency(runner)

uitest.build_configurations.each do |config|
  bs = config.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['TEST_TARGET_NAME'] = 'Runner'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  bs['GENERATE_INFOPLIST_FILE'] = 'YES'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['CLANG_ENABLE_MODULES'] = 'YES'
  bs['SWIFT_VERSION'] = '5.0'
  bs['MARKETING_VERSION'] = '1.0'
  bs['CURRENT_PROJECT_VERSION'] = '1'
  # 不要硬设 ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES：让它继承 Pods xcconfig，
  # 否则 pod install 会警告覆盖、且可能导致 patrol 的 Swift 运行时链接问题。
  bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks']
end

project.save

# 把 RunnerUITests 挂进 Runner scheme 的 TestAction（去重，避免重跑留下悬空引用）
scheme_path = File.join(PROJECT_PATH, 'xcshareddata', 'xcschemes', 'Runner.xcscheme')
scheme = Xcodeproj::XCScheme.new(scheme_path)
testables_node = scheme.test_action.xml_element.elements['Testables']
scheme.test_action.testables.each do |t|
  name = t.buildable_references.first&.target_name
  testables_node.delete_element(t.xml_element) if name == UITEST_NAME
end
scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(uitest))
scheme.save_as(PROJECT_PATH, 'Runner', true)

puts "OK: #{UITEST_NAME} target=#{uitest.uuid}"
puts "targets=#{project.targets.map(&:name).join(', ')}"
puts "scheme_testables=#{scheme.test_action.testables.map { |t| t.buildable_references.first.target_name }.join(', ')}"
