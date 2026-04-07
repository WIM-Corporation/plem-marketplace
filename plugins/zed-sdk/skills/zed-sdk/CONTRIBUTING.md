# zed-sdk 스킬 유지보수 가이드

이 문서는 `zed-sdk` 스킬의 수정, 개선, 확장을 위한 컨벤션을 정의한다.

## 콘텐츠 레이어 구분

이 스킬은 두 종류의 콘텐츠를 **물리적으로 분리된 디렉토리**에서 관리한다:

| 레이어 | 디렉토리 | 출처 | 수정 기준 |
|--------|---------|------|----------|
| **공식문서 원문** | `references/{sdk-overview,ros2,cameras,development,embedded,integrations}/` | stereolabs.com/docs | SDK 버전 업데이트 시 해당 파일만 재fetch로 교체 |
| **plem 실무 가이드** | `references/plem/` | 실무 경험 | 실무에서 발견 시 수시 추가/수정 |

**절대 규칙**: 공식문서 디렉토리(sdk-overview, ros2 등)에 plem 특화 내용을 넣지 않는다. plem 내용은 반드시 `references/plem/`에만 작성한다.

## plem 실무 가이드 작성 규칙

### 파일 구성

```
references/plem/
├── robot-integration.md     # TF 정합, depth_stabilization, URDF, mount YAML
├── namespace-conventions.md # 토픽 패턴, QoS, param_overrides
├── dds-tuning.md            # CycloneDDS, 커널 버퍼
├── yolo-plem.md             # 농작물 config, ONNX, TensorRT
├── optimization.md          # ROI, capping, 주파수 튜닝
└── usage-recording.md       # headless, SVO, rosbag, 벤치마크
```

### 내용 기준

plem/ 파일에 포함할 내용:
- 공식문서에 없는 **pitfall/gotcha** (silent failure, 에러 없이 멈추는 경우 등)
- plem **네임스페이스/네이밍 규칙** (`/{robot_id}/cam/...`)
- plem 생태계 고유 **파라미터 조합** (`depth_stabilization:0` + `publish_tf:false`)
- 실측 **벤치마크** (Orin AGX에서 실제 FPS, 용량 등)
- **코드 예시** (rosbridge CBOR, quaternion→RPY 변환 등)
- plem 도구 연동 (`plem_server`, `plem-init` 스크립트 등)

포함하지 않는 내용:
- 공식문서에 이미 있는 내용의 단순 반복
- 개인 의견이나 미검증 추측
- 특정 프로젝트에만 해당하는 일회성 설정

## 공식문서 업데이트 절차

ZED SDK 버전이 업데이트되면:

1. **변경된 페이지 식별**: Stereolabs changelog 확인
2. **해당 reference 파일만 재fetch**: 전체 재생성 불필요
   ```
   # 예: depth sensing 페이지가 변경된 경우
   에이전트로 해당 4페이지만 재fetch → sdk-overview/depth-sensing.md 교체
   ```
3. **plem/ 유효성 검증**: 새 공식문서 내용이 `references/plem/` 파일의 가이드와 모순되지 않는지 확인. 공식문서에 plem 내용을 삽입하지 않는다 — plem 내용은 `references/plem/`에만 존재한다.

## 파일 구조 규칙

```
zed-sdk/
├── SKILL.md              # 라우팅 테이블 (<250자 description, <500줄)
├── CONTRIBUTING.md       # 이 파일
├── evals/
│   └── evals.json        # 20개 테스트 케이스
└── references/
    ├── sdk-overview/     # 9 files — SDK 핵심 기능
    ├── ros2/             # 5 files — ROS 2 Wrapper
    ├── cameras/          # 3 files — 카메라 하드웨어
    ├── development/      # 3 files — 설치/개발
    ├── embedded/         # 2 files — ZED Link/Box
    ├── integrations/     # 3 files — Docker/YOLO/Isaac
    └── plem/             # 6 files — plem 생태계 실무 가이드
```

### 새 reference 파일 추가 시

1. 적절한 하위 디렉토리에 생성
2. YAML frontmatter 필수: `description`, `source_urls`, `fetched`
3. Table of Contents 포함 (300줄 초과 시 필수)
4. `##` 헤더로 source 페이지 구분
5. SKILL.md Quick Routing 테이블에 라우팅 항목 추가

### reference 파일 명명

- 소문자 + 하이픈: `object-detection.md`, `zed-node.md`
- 공식문서 섹션명과 일치시킨다
- 너무 긴 이름 지양: `positional-tracking.md` (O), `positional-tracking-with-area-memory.md` (X)

## SKILL.md 수정 규칙

- `description` 250자 이내 유지 (truncation 방지)
- Quick Routing 테이블은 키워드 기반 — 새 파일 추가 시 반드시 라우팅 항목 추가
- 보조 라우팅 섹션: 주 라우팅으로 부족한 edge case용

## Eval 실행

```bash
# evals/evals.json의 20개 케이스로 라우팅 정확도 검증
# 에이전트가 각 프롬프트에 대해:
# 1. SKILL.md 라우팅 테이블로 파일 식별
# 2. 해당 파일을 읽어 내용이 질문에 답할 수 있는지 확인
# 3. PASS/PARTIAL/FAIL 판정
```

새 reference 추가나 대규모 수정 후에는 eval을 재실행하여 라우팅 정확도를 확인한다.

## plem/ 실무 가이드 확장

새로운 실무 팁이 발생하면 `references/plem/`의 적절한 파일에 직접 추가한다.
기존 6개 파일의 주제와 맞지 않으면 새 파일을 생성하고 SKILL.md 라우팅 테이블에 항목을 추가한다.
