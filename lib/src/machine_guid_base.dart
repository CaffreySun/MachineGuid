// ignore_for_file: unused_import, non_constant_identifier_names, unused_field
// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

String getMachineGuid() {
  if (!Platform.isWindows) {
    throw Exception('"getMachineGuid" only supports Windows.');
  }

  return using<String>((alloc) {
    final hkey = calloc<IntPtr>();

    _Native.RegOpenKeyEx(hkey);

    try {
      return _Native.RegQueryValueEx(alloc, hkey);
    } catch (e) {
      rethrow;
    } finally {
      _Native.RegCloseKey(hkey);
    }
  });
}

class _Native {
  // Load the advapi32.dll library
  static final _advapi32 = DynamicLibrary.open('Advapi32.dll');

  // Define the RegOpenKeyExW function signature
  static final _RegOpenKeyExA = _advapi32.lookupFunction<
      Int32 Function(IntPtr, Pointer<Utf8>, Uint32, Uint32, Pointer<IntPtr>),
      int Function(
          int, Pointer<Utf8>, int, int, Pointer<IntPtr>)>('RegOpenKeyExA');

  // Define the RegCloseKey function signature
  static final _RegCloseKey = _advapi32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('RegCloseKey');

  // Define the RegQueryValueExW function signature
  static final _RegQueryValueExA = _advapi32.lookupFunction<
      Int32 Function(IntPtr, Pointer<Utf8>, Pointer<IntPtr>, Pointer<Uint32>,
          Pointer<Uint8>, Pointer<Uint32>),
      int Function(int, Pointer<Utf8>, Pointer<IntPtr>, Pointer<Uint32>,
          Pointer<Uint8>, Pointer<Uint32>)>('RegQueryValueExA');

  // Define the HKEY_LOCAL_MACHINE constant
  static const _HKEY_LOCAL_MACHINE = 0x80000002;
  static const _KEY_QUERY_VALUE = 0x0001;
  static const _KEY_WOW64_64KEY = 0x0100;

  static const kSuccess = 0;
  static const kRegKey = "SOFTWARE\\Microsoft\\Cryptography";
  static const kValueKey = "MachineGuid";

  static void RegOpenKeyEx(Pointer<IntPtr> hkey) {
    final res = _RegOpenKeyExA(
      _HKEY_LOCAL_MACHINE,
      kRegKey.toNativeUtf8(),
      0,
      _KEY_QUERY_VALUE | _KEY_WOW64_64KEY,
      hkey,
    );
    if (res != _Native.kSuccess) {
      throw Exception('Failed to open registry: $res');
    }
  }

  static void RegCloseKey(Pointer<IntPtr> hkey) {
    _RegCloseKey(hkey.value);
  }

  static String RegQueryValueEx(Arena alloc, Pointer<IntPtr> hkey) {
    final dataTypePtr = alloc<Uint32>();
    dataTypePtr.value = 0;
    final dataSizePtr = alloc<Uint32>();

    var res = _RegQueryValueExA(
      hkey.value,
      kValueKey.toNativeUtf8(),
      nullptr,
      dataTypePtr,
      nullptr,
      dataSizePtr,
    );

    if (kSuccess != res) {
      throw Exception('Failed to get registry value size: $res');
    }

    final data = alloc<Uint8>(dataSizePtr.value);

    res = _RegQueryValueExA(
      hkey.value,
      kValueKey.toNativeUtf8(),
      nullptr,
      dataTypePtr,
      data,
      dataSizePtr,
    );
    if (kSuccess != res) {
      throw Exception('Failed to get registry value: $res');
    }

    return utf8.decode(data.asTypedList(dataSizePtr.value));
  }
}
