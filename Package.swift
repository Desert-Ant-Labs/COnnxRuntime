// swift-tools-version: 6.2
import PackageDescription

// A thin C shim over the ONNX Runtime C API, so Swift can drive on-device
// inference without reaching through ORT's function-pointer API table or its
// OrtStatus error protocol. See Sources/COnnxRuntime/include/COnnxRuntime.h.
//
// The target links `-lonnxruntime` without saying where to look: the import
// library and the DLL are the consumer's to vendor, and the headers checked in
// under include/onnxruntime must come from the same release as that DLL. The
// consumer passes the search path at link time (`-Xlinker /LIBPATH:<dir>` on
// Windows) and stages onnxruntime.dll next to its binaries. README.md says why
// PATH is not enough for that.
let package = Package(
    name: "COnnxRuntime",
    products: [
        .library(name: "COnnxRuntime", targets: ["COnnxRuntime"]),
    ],
    targets: [
        .target(
            name: "COnnxRuntime",
            linkerSettings: [.linkedLibrary("onnxruntime")]
        ),
    ]
)
