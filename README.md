# COnnxRuntime

A thin C shim over the [ONNX Runtime](https://onnxruntime.ai) C API, packaged
for SwiftPM. It owns one session plus its output buffers and exposes a small
name/run/read surface, so Swift code never touches ORT's function-pointer API
table or its `OrtStatus` error protocol, neither of which Swift imports usefully.

It was split out of [desert-ant-core](https://github.com/Desert-Ant-Labs/desert-ant-core),
where it backs the `OnnxSession` inference backend and the Windows build of Voz.

## What it links against

The target asks for `-lonnxruntime` and nothing more. The consumer provides:

- The import library, `onnxruntime.lib`, on the linker search path
  (`-Xlinker /LIBPATH:<dir>` on Windows).
- `onnxruntime.dll` next to the executable at run time, plus `DirectML.dll` if
  the GPU provider is wanted.

The headers under `Sources/COnnxRuntime/include/onnxruntime` are from ONNX
Runtime 1.23.0 (`ORT_API_VERSION` 23). Move them and the DLL together: a shim
built against a newer API table than the DLL carries fails at
`OrtGetApiBase()->GetApi(ORT_API_VERSION)` with "The requested API version is
not available".

## Why the DLL has to sit next to the binary

PATH is not enough on Windows. The loader searches the application directory
and then System32 before PATH, and Windows ML ships its own
`C:\Windows\System32\onnxruntime.dll` (1.17 on a 26200 host). A PATH entry
loses to it silently, and the failure looks like a build error: the same
"requested API version [23] is not available" message as above. The application
directory outranks System32, so staging the vendored DLL there is what makes
it win.

## Execution providers

`dal_ort_create` takes an accelerator bitset (1 = CPU, 2 = GPU, 4 = NPU).
Requesting an accelerator is always safe: the shim adds the provider when the
platform has it and otherwise builds a CPU session. On Windows the GPU is
DirectML and comes from the `onnxruntime-directml` PyPI wheel, which is the only
place that build is published. The NPU provider is a separate DLL whose path is
passed in, or read from `DAL_ORT_NPU_EP`, because the Windows ML providers live
under `C:\Program Files\WindowsApps`, whose ACL denies a directory listing.

`dal_ort_accelerators` reports which providers were added to the session, not
which nodes they claimed. Proving placement needs a profile.

## Platforms

Windows is the only platform this has been built and run on. The shim keeps
standard C spellings (`getenv`, `strncpy`) rather than the MSVC `_s` variants,
so it should compile elsewhere, but nothing else has been tried.
