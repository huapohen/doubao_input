// Headless Xcode 27 has no Simulator.app window, so CoreSimulator keeps a hardware
// keyboard attached and iOS hides the software keyboard. This QA helper detaches it
// through SimDevice's private setHardwareKeyboardEnabled:keyboardType:error:.
// Usage: osascript -l JavaScript scripts/disconnect_simulator_keyboard.js <UDID> "$(xcode-select -p)"
ObjC.import('Foundation');
function run([udid, developerDir]) {
  $.NSBundle.bundleWithPath('/Library/Developer/PrivateFrameworks/CoreSimulator.framework').load;
  const context = $.NSClassFromString('SimServiceContext').sharedServiceContextForDeveloperDirError(developerDir, null);
  const device = context.defaultDeviceSetWithError(null).devicesByUDID.objectForKey($.NSUUID.alloc.initWithUUIDString(udid));
  if (!device || device.isNil()) throw new Error('no simulator ' + udid);
  const error = Ref();
  if (!device.setHardwareKeyboardEnabledKeyboardTypeError(false, 0, error)) {
    throw new Error(ObjC.unwrap(error[0].localizedDescription));
  }
  return 'hardware keyboard disconnected: ' + udid;
}
