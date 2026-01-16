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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

import 'ffi.dart';

late void Function(Pointer<Utf8>, Pointer<Utf8>) nativeHideHostView;
late void Function(Pointer<Utf8>, Pointer<Utf8>) nativeShowHostView;
late void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>) nativePushChunk;

final class LuaArgs extends Struct {
  @Array(256)
  external Array<Uint8> nodeName;
}


void lookupFF() {
  final dylib = Platform.isAndroid
      ? DynamicLibrary.open('libevi_plugin_flutter.so')
      : DynamicLibrary.open("evi_plugin_flutter.framework/evi_plugin_flutter");
	nativeHideHostView = dylib.lookupFunction<Void Function(Pointer<Utf8>, Pointer<Utf8>), void Function(Pointer<Utf8>, Pointer<Utf8>)>("evi_plugin_flutter_hostview_hide");
	nativeShowHostView = dylib.lookupFunction<Void Function(Pointer<Utf8>, Pointer<Utf8>), void Function(Pointer<Utf8>, Pointer<Utf8>)>("evi_plugin_flutter_hostview_display");
	nativeRegisterDartCb = dylib.lookupFunction<Void Function(Pointer<Utf8>, Pointer<Utf8>, IntPtr, Pointer<Utf8>),
	void Function(Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Utf8>)>("evi_plugin_flutter_register_callback");
	nativePushChunk = dylib.lookupFunction<Void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>), void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>("evi_plugin_flutter_push_chunk");
}

void nativePushChunkToLua(String entrypoint, String chunk) {
    final nLibName = "".toNativeUtf8();
    final nEntryPoint = entrypoint.toNativeUtf8();
    final nChunk = chunk.toNativeUtf8();
    nativePushChunk(nEntryPoint, nLibName, nChunk);
    calloc.free(nLibName);
    calloc.free(nEntryPoint);
    calloc.free(nChunk);
}

void main() {
  lookupFF();
  runApp(MaterialApp(home: const VisibilityWidget()));
}

@pragma("vm:entry-point")
void bottomWidgets() {
  lookupFF();
  runApp(MaterialApp(home: const BottomWidgets()));
}


class VisibilityWidget extends StatefulWidget {
  const VisibilityWidget({super.key});

  @override
  State<VisibilityWidget> createState() => _VisibilityWidgetState();
}

class _VisibilityWidgetState extends State<VisibilityWidget> {
  bool visible = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
          nativePushChunkToLua("main", visible ? "globals.model:hide(0x0)" : "globals.model:show(0xffffffff)");
          setState(() {
            visible = !visible;
          });
      },
      child: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.black, size: 40.0));
  }
}

class BottomWidgets extends StatefulWidget {
  const BottomWidgets({super.key});

  @override
  State<BottomWidgets> createState() => _BottomWidgetsState();
}

class _BottomWidgetsState extends State<BottomWidgets> with FfiCallbacks {
  bool isAudioPlaying = false;
  String clickText = "Нажмите на модель";

  @override
  void initState() {
			super.initState();

			addCallback("onAudioFinished", (Pointer<Void> data) {
				setState(() {
					isAudioPlaying = false;
				});
			});

      addCallback("onNodeClick", (Pointer<Void> data) {
        final struct = data.cast<LuaArgs>().ref;
				setState(() {
					clickText = readUtf8(struct.nodeName, 256);
				});
			});

			registerCallbacks("bottomWidgets");
		}

    @override
		void dispose() {
			disposeCallbacks();
			super.dispose();
		}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [ElevatedButton(onPressed: () {
            if (isAudioPlaying) {
              return;
            }
            nativePushChunkToLua("bottomWidgets", "globals.audio:play()");
            setState(() {
              isAudioPlaying = true;
            });
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(10)
        ),
        child: Text(isAudioPlaying ? "Аудио проигрывается..." : "Воспроизвести аудио")),
        Padding(
          padding: const EdgeInsets.only(top:12.0),
          child: Material(child: Text(clickText, style: TextStyle(color: Colors.black, fontSize: 12.0),)),
        )
    ]);
  }
}