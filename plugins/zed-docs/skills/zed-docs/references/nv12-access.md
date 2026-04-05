# NV12 Zero-Copy Access (GMSL2 전용)

ZED X / ZED X One GMSL2 카메라에서 NV12 raw 버퍼에 zero-copy로 접근하는 방법.
GStreamer, DeepStream, CUDA 커스텀 파이프라인 연동 시 사용한다.

## 전제조건

| 항목 | 요구사항 |
|------|---------|
| 플랫폼 | Jetson (aarch64) only |
| 카메라 | GMSL2 연결 카메라 (ZED X, ZED X Mini, ZED X One) |
| SDK 버전 | ZED SDK 5.2+ |
| 인터페이스 | USB 카메라(ZED 2 등)는 미지원 |

## API 활성화

소스 파일에서 ZED SDK 헤더 include **전에** 매크로를 정의한다:

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/Camera.hpp>
```

이 매크로 없이 `getRawBuffer()`를 호출하면 컴파일 에러가 발생한다.

## 사용 패턴 — ZED X (스테레오)

```cpp
sl::Camera zed;
sl::InitParameters init_params;
init_params.camera_resolution = sl::RESOLUTION::HD1200;
zed.open(init_params);

sl::Mat image;
zed.grab();
zed.retrieveImage(image, sl::VIEW::LEFT);

// Zero-copy raw buffer 접근
sl::RawBuffer raw = image.getRawBuffer();
NvBufSurface* nvbuf = static_cast<NvBufSurface*>(raw.data);
// nvbuf->surfaceList[0] 으로 NV12 데이터 접근
```

스테레오 카메라는 `sl::VIEW::LEFT`와 `sl::VIEW::RIGHT` 모두 사용 가능.

## 사용 패턴 — ZED X One (단안)

ZED X One은 `sl::CameraOne` 클래스를 사용한다 (`sl::Camera` 아님):

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/CameraOne.hpp>

sl::CameraOne zed;
sl::InitParametersOne init_params;
zed.open(init_params);

sl::Mat image;
zed.grab();
zed.retrieveImage(image, sl::VIEW_ONE::LEFT);

sl::RawBuffer raw = image.getRawBuffer();
NvBufSurface* nvbuf = static_cast<NvBufSurface*>(raw.data);
```

단안이므로 `sl::VIEW_ONE::RIGHT`는 사용 불가.

## 안전 규칙

**절대 호출 금지:**

| 함수 | 이유 |
|------|------|
| `NvBufSurfaceDestroy()` | SDK가 버퍼 수명을 관리. 호출 시 double-free 또는 SEGFAULT |
| `NvBufSurfaceUnMap()` | SDK 내부 매핑 해제됨. 이후 접근 시 SEGFAULT |

버퍼는 다음 `grab()` 호출 시 자동으로 재사용된다. 명시적 해제 불필요.

## 연동 패턴

### CUDA 직접 처리

```cpp
NvBufSurface* nvbuf = static_cast<NvBufSurface*>(raw.data);
// GPU 메모리 직접 접근 (memcpy 없음)
void* gpu_ptr = nvbuf->surfaceList[0].dataPtr;
// CUDA 커널에서 NV12 → RGB 변환 등 수행
```

### GStreamer / DeepStream

`NvBufSurface*`를 `NvDsBufSurface`로 캐스팅하여 DeepStream 파이프라인에 주입 가능.
GStreamer `appsrc`를 통해 커스텀 파이프라인에 프레임 공급.

## 참고

- 공식 문서 (ZED X): https://www.stereolabs.com/docs/cameras/zed-x/zed-x-nv12-access
- 공식 문서 (ZED X One): https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-nv12-access
