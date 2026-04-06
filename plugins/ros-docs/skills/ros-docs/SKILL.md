---
name: ros-docs
description: "ROS 2 공식 문서 기반 레퍼런스. colcon 빌드, workspace overlay, source 환경설정, QoS, TF2, launch 파일, DDS 튜닝, 파라미터, callback group 등 ROS 2 관련 질문에 사용한다. ROS 2 초심자 질문, 환경 구성, 빌드 오류, 통신 문제, 노드 설정 등 ROS 2 생태계와 관련된 모든 질문에 반드시 이 스킬을 참조한다."
argument-hint: "[topic]"
---

# ROS 2 Humble -- Official Reference Skill

ROS 2 공식 문서(docs.ros.org/en/humble)에서 검증된 정보만 제공한다.
추론이나 추정 없이 공식 권장사항을 기반으로 답변한다.

## Quick Routing

사용자 질문에 따라 적절한 reference 문서를 읽어 답변한다:

| 사용자가 묻는 것 | 읽어야 할 문서 | 핵심 키워드 |
|----------------|--------------|------------|
| 환경 설정 / source / overlay / workspace / colcon | `references/workspace-and-build.md` | source, colcon, overlay, underlay, workspace, 빌드, 환경, setup.bash, prefix chain |
| QoS / 토픽 안 옴 / 데이터 손실 / 호환성 | `references/qos.md` | qos, reliability, durability, best_effort, reliable, volatile, transient_local, 토픽 |
| 노드 / 토픽 / 서비스 / 액션 / 파라미터 | `references/core-concepts.md` | node, topic, service, action, parameter, pub/sub, request/response, goal, feedback |
| TF2 / 좌표 변환 / 프레임 / broadcasting | `references/tf2.md` | tf2, transform, frame, broadcast, listener, static, coordinate |
| Launch 파일 / Python/XML/YAML launch | `references/launch.md` | launch, launch.py, launch.xml, substitution, event handler, DeclareLaunchArgument |
| DDS / 네트워크 튜닝 / 커널 버퍼 | `references/dds-tuning.md` | dds, cyclone, fast dds, connext, 커널 버퍼, rmem_max, multicast |
| Executor / callback group / 멀티스레드 | `references/executors.md` | executor, callback group, mutually exclusive, reentrant, deadlock, multi-threaded |
| 로깅 / 디버깅 / 트러블슈팅 | `references/logging-and-troubleshooting.md` | log, logger, RCLCPP_INFO, rqt_console, troubleshooting, 에러 |
| URDF / Xacro / robot_state_publisher | `references/tf2.md` (URDF 섹션) | urdf, xacro, robot_state_publisher, link, joint |
| 커스텀 메시지 / 인터페이스 / .msg .srv .action | `references/core-concepts.md` (Interfaces 섹션) | msg, srv, action, interface, 메시지 정의, rosidl, custom message |
| rosbag / 녹화 / 재생 / 데이터 기록 | `references/workspace-and-build.md` (rosbag2 섹션) | rosbag, bag, record, play, 녹화, 재생, mcap, db3 |
| Composable Node / 컴포넌트 / intra-process | `references/executors.md` (Composition 섹션) | component, composable, container, intra-process, component_container |
| 패키지 생성 / ament_cmake / ament_python | `references/workspace-and-build.md` (패키지 생성 섹션) | ros2 pkg create, ament_cmake, ament_python, package.xml, CMakeLists |
| RQt / GUI 도구 / rqt_graph | `references/logging-and-troubleshooting.md` (디버깅 도구 섹션) | rqt, rqt_graph, rqt_console, gui |
| rosdep / 의존성 관리 | `references/workspace-and-build.md` (rosdep 섹션) | rosdep, package.xml, depend, build_depend, exec_depend |
| Lifecycle Node / managed node / 상태 전이 | `references/advanced-patterns.md` | lifecycle, managed, configure, activate, deactivate, transition |
| 시뮬레이션 / Gazebo / RViz / 시각화 | `references/advanced-patterns.md` (시뮬레이션 섹션) | gazebo, rviz, simulation, 시뮬레이션, 시각화, visualization |
| Security / SROS2 / DDS-Security | `references/advanced-patterns.md` (Security 섹션) | security, sros2, keystore, enclave, 보안 |

인자가 없으면 아래 핵심 규칙을 기반으로 답변하고, 상세가 필요하면 해당 reference를 읽는다.

---

## 핵심 규칙

### Source 환경 — 가장 흔한 초심자 실수

ROS 2 명령(`ros2`, `colcon` 등)은 `setup.bash`를 source해야 동작한다.
**새 터미널을 열 때마다** source가 필요하다.

```bash
source /opt/ros/humble/setup.bash    # ROS 2 기본
source install/setup.bash             # 자체 빌드 워크스페이스
```

`install/setup.bash`는 **prefix chain**으로 underlay를 자동 포함한다.
빌드 후에는 `install/setup.bash` 하나만 source하면 된다.

> **주의**: `colcon build`는 빌드 시점에 source된 환경을 `install/setup.bash`에 기록한다.
> 불필요한 워크스페이스가 source된 상태에서 빌드하면 해당 경로가 prefix chain에 영구 잔존한다.
> 빌드할 때는 필요한 underlay만 source된 깨끗한 셸에서 실행한다.

### Overlay/Underlay 구조

```
┌─────────────────┐  내 워크스페이스 (install/)   ← overlay
├─────────────────┤  /opt/plem 등 공유 라이브러리   ← underlay
├─────────────────┤  /opt/ros/humble               ← 최하위 underlay
└─────────────────┘
```

- overlay의 패키지가 underlay의 동명 패키지를 **우선 적용**(override)
- `local_setup.bash`는 해당 워크스페이스만, `setup.bash`는 chain 전체를 source

### colcon build 필수 지식

```bash
colcon build --symlink-install    # 비컴파일 리소스 수정 시 재빌드 불필요
colcon build --packages-select my_pkg    # 특정 패키지만 빌드
colcon build --packages-up-to my_pkg     # 의존성 포함 빌드
```

- `COLCON_IGNORE` 파일을 패키지 디렉토리에 두면 해당 패키지 빌드 스킵
- `colcon build`와 `source install/setup.bash`는 **다른 터미널**에서 실행 권장
- 빌드 결과: `build/` (중간 파일), `install/` (실행 파일), `log/` (빌드 로그)

### QoS — Silent Failure 원인 1위

Publisher와 Subscriber의 QoS가 호환되지 않으면 **에러 없이 데이터가 안 온다**.

호환성 규칙 (공식):
| Publisher | Subscriber | 연결 |
|-----------|------------|------|
| Best Effort | Best Effort | O |
| Best Effort | Reliable | **X** |
| Reliable | Best Effort | O |
| Reliable | Reliable | O |

| Publisher | Subscriber | 연결 |
|-----------|------------|------|
| Volatile | Volatile | O |
| Volatile | Transient Local | **X** |
| Transient Local | Volatile | O |
| Transient Local | Transient Local | O |

기본 QoS 프로파일:
- **Default**: Keep Last(10), Reliable, Volatile
- **Sensor Data**: Best Effort, 작은 큐 (최신 데이터 우선)
- **Services**: Reliable, Volatile

### ROS_DOMAIN_ID

같은 네트워크에서 ROS 2 그룹을 분리한다. 기본값: 0.
안전 범위: **0~101** (Linux), 0~166 (macOS/Windows).

```bash
export ROS_DOMAIN_ID=42      # 같은 값의 노드끼리만 통신
export ROS_LOCALHOST_ONLY=1   # 같은 머신 내 통신만 허용
```

### 통신 패턴 선택 가이드

| 패턴 | 용도 | 특징 |
|------|------|------|
| **Topic** | 연속 데이터 (센서, 상태) | 다대다, 비동기 |
| **Service** | 짧은 요청/응답 (조회, 계산) | 1:1, 동기 |
| **Action** | 장시간 작업 (네비게이션) | 피드백+취소 가능 |

서비스는 장시간 작업에 사용하면 안 된다. 취소가 필요하면 Action을 사용한다.

### 파라미터

- 파라미터는 노드 수명에 종속된다 (노드 종료 시 소멸)
- 기본적으로 **선언된 파라미터만** 허용 (타입 안전성)
- 지원 타입: `bool`, `int64`, `float64`, `string`, `byte[]`, `bool[]`, `int64[]`, `float64[]`, `string[]`

```bash
ros2 param set /node_name param_name value    # 런타임 변경
ros2 param list /node_name                     # 전체 목록
ros2 param dump /node_name                     # YAML 내보내기
```

### Discovery

- 노드는 DDS를 통해 **자동으로** 서로를 발견한다
- 같은 `ROS_DOMAIN_ID`의 노드만 발견 가능
- QoS가 호환되어야 실제 연결이 수립된다

---

## 성능 이슈 Quick Fix

| 증상 | 원인 | 해결 | 상세 |
|------|------|------|------|
| 토픽 데이터 안 옴 | QoS 불일치 | Publisher/Subscriber QoS 호환 확인 | `references/qos.md` |
| 대용량 메시지 손실 | 커널 버퍼 부족 | `rmem_max` 증가 | `references/dds-tuning.md` |
| 멀티캐스트 실패 | UFW/방화벽 | UDP 224.0.0.0/4 허용 | `references/logging-and-troubleshooting.md` |
| 빌드 시 메모리 부족 | 병렬 빌드 | `--executor sequential` 또는 `MAKEFLAGS=-j1` | `references/workspace-and-build.md` |
| callback 데드락 | callback group | timer와 client를 다른 group에 배치 | `references/executors.md` |
| `ros2` 명령 안 됨 | source 안 함 | `source /opt/ros/humble/setup.bash` | `references/workspace-and-build.md` |
