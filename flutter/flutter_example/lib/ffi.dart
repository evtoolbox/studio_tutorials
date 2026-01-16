/*
-------------------------------------------------------------------------------
--                                                                           --
-- Copyright 2026 EligoVision. Interactive Technologies                      --
--                                                                           --
-- Permission is hereby granted, free of charge, to any person obtaining a   --
-- copy of this software and associated documentation files                  --
-- (the "Software"), to deal in the Software without restriction, including  --
-- without limitation the rights to use, copy, modify, merge, publish,       --
-- distribute, sublicense, and/or sell copies of the Software, and to permit --
-- persons to whom the Software is furnished to do so, subject to the        --
-- following conditions:                                                     --
--                                                                           --
-- The above copyright notice and this permission notice shall be included   --
-- in all copies or substantial portions of the Software.                    --
--                                                                           --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   --
-- OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                --
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    --
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      --
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,      --
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE         --
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                    --
--                                                                           --
-------------------------------------------------------------------------------
*/

import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef NativeStrCallback = Void Function(Pointer<Void>);
late void Function(Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Utf8>) nativeRegisterDartCb;

mixin FfiCallbacks {
		final Map<String, NativeCallable<NativeStrCallback>> _callbacks = {};

		void addCallback(String name, void Function(Pointer<Void>) cb) {
			_callbacks[name]?.close();
			_callbacks[name] = NativeCallable<NativeStrCallback>.listener(cb);
		}

		void registerCallbacks(String entrypoint) {
			_callbacks.forEach((name, callable) {
				final entryPoint = entrypoint.toNativeUtf8();
				final libUri = "".toNativeUtf8();
				final funcName = name.toNativeUtf8();
				nativeRegisterDartCb(entryPoint, libUri, callable.nativeFunction.address, funcName);
				malloc.free(entryPoint);
				malloc.free(libUri);
				malloc.free(funcName);
			});
		}

		void disposeCallbacks() {
			for (final cb in _callbacks.values) {
				cb.close();
			}
			_callbacks.clear();
		}

    String readUtf8(Array<Uint8> arr, int maxLen) {
      final bytes = <int>[];
      for (var i = 0; i < maxLen; i++) {
        final byte = arr[i];
        if (byte == 0) break;
        bytes.add(byte);
      }
      return String.fromCharCodes(bytes);
    }
	}