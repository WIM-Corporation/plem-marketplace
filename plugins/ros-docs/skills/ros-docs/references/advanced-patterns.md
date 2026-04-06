---
description: "ROS 2 고급 패턴 — Lifecycle Nodes, 시뮬레이션/시각화(Gazebo, RViz), Security(SROS2) 레퍼런스"
---

# Advanced Patterns

## Lifecycle Nodes (Managed Nodes)

출처: https://docs.ros.org/en/humble/Tutorials/Intermediate/Managing-Nodes-With-Lifecycles.html

Lifecycle node는 노드의 상태를 명시적으로 관리할 수 있는 패턴이다.
일반 노드와 달리 시작 즉시 동작하지 않고, 상태 전이를 통해 초기화 → 활성화 → 비활성화를 제어한다.

### 상태 머신

```
         [create]
            ↓
     ┌─ Unconfigured ─┐
     │                 │
  [cleanup]      [configure]
     │                 │
     ├── Inactive ─────┤
     │                 │
  [deactivate]    [activate]
     │                 │
     └── Active ───────┘
            │
       [shutdown] → Finalized
```

### 주요 상태

| 상태 | 설명 |
|------|------|
| **Unconfigured** | 생성 직후. 아직 설정 안 됨 |
| **Inactive** | 설정 완료, 실행 대기. 토픽 발행/구독 안 함 |
| **Active** | 정상 동작 중. 토픽 발행/구독 활성 |
| **Finalized** | 종료됨 |

### 전이 (Transitions)

| 전이 | 시작 → 끝 | 콜백 |
|------|-----------|------|
| `configure` | Unconfigured → Inactive | `on_configure()` |
| `activate` | Inactive → Active | `on_activate()` |
| `deactivate` | Active → Inactive | `on_deactivate()` |
| `cleanup` | Inactive → Unconfigured | `on_cleanup()` |
| `shutdown` | Any → Finalized | `on_shutdown()` |

### CLI 제어

```bash
# 상태 확인
ros2 lifecycle get /node_name

# 전이 실행
ros2 lifecycle set /node_name configure
ros2 lifecycle set /node_name activate
ros2 lifecycle set /node_name deactivate
```

### 사용 시점

- 센서/하드웨어 초기화가 필요한 노드
- 에러 복구 시 재초기화 필요
- 시스템 전체의 부팅 순서 제어
- 드라이버 노드 (카메라, 로봇 등)

### C++ 구현

```cpp
#include <rclcpp_lifecycle/lifecycle_node.hpp>

class MyLifecycleNode : public rclcpp_lifecycle::LifecycleNode {
public:
    MyLifecycleNode() : LifecycleNode("my_lifecycle_node") {}

    CallbackReturn on_configure(const rclcpp_lifecycle::State &) override {
        // 리소스 할당, 파라미터 읽기
        return CallbackReturn::SUCCESS;
    }

    CallbackReturn on_activate(const rclcpp_lifecycle::State &) override {
        // publisher/subscriber 활성화
        return CallbackReturn::SUCCESS;
    }

    CallbackReturn on_deactivate(const rclcpp_lifecycle::State &) override {
        // 동작 중지 (리소스 유지)
        return CallbackReturn::SUCCESS;
    }

    CallbackReturn on_cleanup(const rclcpp_lifecycle::State &) override {
        // 리소스 해제
        return CallbackReturn::SUCCESS;
    }
};
```

### package.xml 의존성

```xml
<depend>rclcpp_lifecycle</depend>
<depend>lifecycle_msgs</depend>
```

---

## 시뮬레이션 & 시각화

### RViz2

ROS 2의 기본 3D 시각화 도구. 토픽 데이터를 시각적으로 표시한다.

```bash
# 기본 실행
rviz2

# 설정 파일 로드
rviz2 -d my_config.rviz
```

주요 Display 타입:
- **RobotModel**: URDF 기반 로봇 모델 표시 (`/robot_description` 파라미터 필요)
- **TF**: 좌표 프레임 트리 시각화
- **PointCloud2**: 3D 포인트클라우드
- **Image**: 카메라 이미지
- **LaserScan**: 2D 라이더 스캔
- **Marker/MarkerArray**: 사용자 정의 시각화 (화살표, 텍스트, 메시 등)
- **Path**: 경로 시각화 (nav2 등)
- **Map**: 2D 점유 격자 지도

### Gazebo (시뮬레이션)

물리 시뮬레이션 엔진. URDF 로봇을 가상 환경에서 테스트할 수 있다.

#### URDF Gazebo 요구사항

- 모든 link에 `<inertial>` 필수 (없으면 Gazebo가 무시)
- `<collision>` 태그 필수 (물리 충돌용)
- `<gazebo>` 확장 태그로 마찰, 재질, 플러그인 설정

```xml
<gazebo reference="base_link">
  <material>Gazebo/Orange</material>
  <mu1>0.2</mu1>
  <mu2>0.2</mu2>
</gazebo>
```

#### 스폰

```bash
# Gazebo 실행
ros2 launch gazebo_ros gazebo.launch.py

# URDF 모델 스폰
ros2 run gazebo_ros spawn_entity.py -topic robot_description -entity my_robot
```

#### Gazebo 플러그인 (센서 시뮬레이션)

```xml
<!-- 카메라 플러그인 -->
<gazebo reference="camera_link">
  <sensor type="camera" name="camera">
    <plugin name="camera_controller" filename="libgazebo_ros_camera.so">
      <ros>
        <remapping>image_raw:=image</remapping>
      </ros>
    </plugin>
  </sensor>
</gazebo>
```

### RViz vs Gazebo

| 항목 | RViz2 | Gazebo |
|------|-------|--------|
| 용도 | **시각화** (데이터 표시) | **시뮬레이션** (물리 엔진) |
| 물리 | 없음 | 중력, 충돌, 마찰 |
| 센서 | 실제 센서 데이터 표시 | 가상 센서 데이터 생성 |
| URDF | 선택적 | 필수 (inertial, collision) |
| 주 사용 | 디버깅, 모니터링 | 알고리즘 테스트, 시험 |

> RViz와 Gazebo는 동시에 사용하는 경우가 많다.
> Gazebo에서 시뮬레이션하고 RViz에서 시각화하여 확인한다.

### RQt

GUI 기반 디버깅 프레임워크. 플러그인 구조:

```bash
rqt                                          # 메인 GUI (플러그인 선택)
rqt_graph                                    # 노드/토픽 그래프 시각화
ros2 run rqt_console rqt_console             # 로그 메시지 뷰어
ros2 run rqt_plot rqt_plot                   # 토픽 데이터 실시간 그래프
ros2 run rqt_image_view rqt_image_view       # 이미지 토픽 뷰어
ros2 run rqt_tf_tree rqt_tf_tree             # TF 트리 시각화 (apt install ros-humble-rqt-tf-tree 필요)
```

---

## Security (SROS2)

출처: https://docs.ros.org/en/humble/Tutorials/Advanced/Security/

ROS 2는 DDS-Security 표준을 통해 통신 암호화, 인증, 접근 제어를 지원한다.

### 기본 개념

- **Keystore**: 인증서와 키를 저장하는 디렉토리
- **Enclave**: 보안 정책이 적용되는 단위 (보통 노드별)
- **DDS-Security**: 플러그인 기반 보안 (인증, 암호화, 접근 제어)

### 설정 흐름

```bash
# 1. keystore 생성
ros2 security create_keystore ~/sros2_keystore

# 2. enclave 생성 (노드별)
ros2 security create_enclave ~/sros2_keystore /talker
ros2 security create_enclave ~/sros2_keystore /listener

# 3. 환경 변수 설정
export ROS_SECURITY_KEYSTORE=~/sros2_keystore
export ROS_SECURITY_ENABLE=true
export ROS_SECURITY_STRATEGY=Enforce    # 또는 Permissive

# 4. 노드 실행 (보안 적용)
ros2 run demo_nodes_cpp talker --ros-args --enclave /talker
```

### 환경 변수

| 변수 | 값 | 설명 |
|------|---|------|
| `ROS_SECURITY_KEYSTORE` | 경로 | keystore 디렉토리 |
| `ROS_SECURITY_ENABLE` | `true`/`false` | 보안 활성화 |
| `ROS_SECURITY_STRATEGY` | `Enforce`/`Permissive` | Enforce: 인증 실패 시 차단, Permissive: 경고만 |

### 주의사항

- Security 적용 시 모든 노드에 enclave가 필요하다
- `Permissive` 모드에서 먼저 테스트 후 `Enforce`로 전환 권장
- 기본 RMW(Fast DDS)에서 지원. Cyclone DDS도 지원.
