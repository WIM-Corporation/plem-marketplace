---
description: "ROS 2 workspace, colcon build, source, overlay/underlay, prefix chain, rosdep — 환경 구성과 빌드 시스템 전체 레퍼런스"
---

# Workspace & Build System

출처: https://docs.ros.org/en/humble/Tutorials/Beginner-Client-Libraries/Colcon-Tutorial.html,
https://docs.ros.org/en/humble/Tutorials/Beginner-Client-Libraries/Creating-A-Workspace/Creating-A-Workspace.html

## Workspace 구조

```
ros2_ws/
├── src/       # 소스 패키지 (git clone, ros2 pkg create)
├── build/     # 중간 빌드 파일 (CMake cache 등)
├── install/   # 설치된 실행 파일, 라이브러리, setup.bash
└── log/       # 빌드 로그
```

ROS 1의 `devel/` 디렉토리는 없다. `install/`이 그 역할을 대체한다.

## Overlay / Underlay

- **Underlay**: 의존성을 제공하는 하위 워크스페이스 (예: `/opt/ros/humble`)
- **Overlay**: 개발 중인 상위 워크스페이스 (예: `~/ros2_ws/install`)
- overlay의 패키지가 underlay의 동명 패키지를 **우선 적용**한다
- 여러 층의 overlay/underlay가 가능하다

### source 차이

| 파일 | 효과 |
|------|------|
| `setup.bash` | 해당 워크스페이스 + prefix chain의 모든 underlay를 source |
| `local_setup.bash` | 해당 워크스페이스만 source (underlay 미포함) |

실용적으로: `install/setup.bash` 하나만 source하면 chain 전체가 로드된다.

## Prefix Chain — 빌드 환경이 기록되는 메커니즘

`colcon build` 실행 시 **현재 source된 환경의 모든 워크스페이스 경로**가 `install/setup.bash`에 하드코딩된다.

```
빌드 시 환경:
  source /opt/ros/humble/setup.bash
  source /opt/plem/setup.bash         ← 이것도 기록됨
  colcon build

결과: install/setup.bash에 기록된 chain
  /opt/ros/humble → /opt/plem → 자체 install/
```

**오염 주의**: 불필요한 워크스페이스가 source된 상태에서 빌드하면 해당 경로가 prefix chain에 영구 잔존한다. 이 오염은 해당 `install/setup.bash`를 source하는 모든 워크스페이스에 전파된다.

**클린 빌드**:
```bash
rm -rf build install log
source /opt/ros/humble/setup.bash    # 필요한 underlay만!
colcon build --symlink-install
```

## colcon build 옵션

```bash
# 기본 빌드
colcon build

# symlink install — install/ 에 파일 복사 대신 심볼릭 링크 생성
# Python 스크립트, launch 파일, config YAML 등 비컴파일 리소스를
# 소스에서 수정하면 재빌드 없이 즉시 반영된다.
# C++ 코드는 여전히 재빌드 필요.
colcon build --symlink-install  # 비컴파일 리소스 수정 시 재빌드 불필요 (상세는 아래 설명 참고)

# 특정 패키지만
colcon build --packages-select my_pkg

# 의존성 포함 빌드
colcon build --packages-up-to my_pkg

# 콘솔 출력 보기
colcon build --event-handlers console_direct+

# 순차 빌드 (메모리 부족 시)
colcon build --executor sequential

# 테스트 빌드 제외
colcon build --cmake-args -DBUILD_TESTING=0

# Windows (경로 길이 제한)
colcon build --merge-install
```

### COLCON_IGNORE

패키지 디렉토리에 빈 `COLCON_IGNORE` 파일을 두면 해당 패키지와 하위 디렉토리를 빌드에서 제외한다.

```bash
touch src/some_pkg/COLCON_IGNORE    # some_pkg 빌드 스킵
```

내용은 비어있어도 된다. 파일 존재 여부만 확인한다.

### 빌드와 source는 다른 터미널에서

공식 권장: "Open a new terminal, separate from the source where you built." 같은 터미널에서 빌드 후 source하면 복잡한 문제가 발생할 수 있다.

## Environment 변수

```bash
# 필수
source /opt/ros/humble/setup.bash

# 확인
printenv | grep -i ROS
# → ROS_VERSION=2, ROS_DISTRO=humble, ROS_PYTHON_VERSION=3

# DDS 도메인 분리 (기본: 0, 안전 범위: 0-101)
export ROS_DOMAIN_ID=42

# 같은 머신 내 통신만 허용
export ROS_LOCALHOST_ONLY=1
```

### .bashrc에 등록

```bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc
```

## rosdep — 의존성 관리

rosdep은 `package.xml`의 의존성을 읽어 시스템 패키지를 자동 설치하는 메타 패키지 매니저이다. Linux/macOS만 지원.

### 초기화 (최초 1회)

```bash
sudo rosdep init
rosdep update
```

### 의존성 설치

```bash
# 워크스페이스 전체
rosdep install --from-paths src -y --ignore-src

# 특정 배포판 지정
rosdep install -i --from-path src --rosdistro humble -y
```

- `--from-paths src`: src/ 내 package.xml을 탐색
- `-y`: 모든 설치 프롬프트에 자동 동의
- `--ignore-src`: 워크스페이스 내에 이미 있는 패키지는 설치 스킵

### package.xml 의존성 태그

| 태그 | 용도 | 사용 시점 |
|------|------|----------|
| `<depend>` | 빌드+런타임 모두 | C++ 패키지의 기본 선택 |
| `<build_depend>` | 빌드 시에만 | 코드 생성기, 빌드 전용 도구 |
| `<build_export_depend>` | 내보내는 헤더의 의존성 | 헤더에 다른 패키지 헤더를 include할 때 |
| `<exec_depend>` | 런타임에만 | Python 패키지의 기본 선택 |
| `<test_depend>` | 테스트에만 | 테스트 프레임워크 |

### rosdep key 찾기

- ROS 패키지: 패키지 이름 그대로 사용
- 시스템 패키지: [rosdep/base.yaml](https://github.com/ros/rosdistro/blob/master/rosdep/base.yaml)
- Python 패키지: [rosdep/python.yaml](https://github.com/ros/rosdistro/blob/master/rosdep/python.yaml)

## 패키지 생성

출처: https://docs.ros.org/en/humble/Tutorials/Beginner-Client-Libraries/Creating-Your-First-ROS2-Package.html

```bash
cd ~/ros2_ws/src
ros2 pkg create --build-type ament_cmake --license Apache-2.0 my_cpp_pkg
ros2 pkg create --build-type ament_python --license Apache-2.0 my_py_pkg
ros2 pkg create --build-type ament_cmake --license Apache-2.0 --node-name my_node my_pkg  # Hello World 노드 포함
```

### CMake 패키지 구조

```
my_cpp_pkg/
├── CMakeLists.txt
├── include/my_cpp_pkg/
├── package.xml
└── src/
```

### Python 패키지 구조

```
my_py_pkg/
├── package.xml
├── resource/my_py_pkg        # 마커 파일
├── setup.cfg
├── setup.py
└── my_py_pkg/__init__.py
```

### setup.py (Python 패키지)

`package.xml`과 메타데이터(maintainer, license, version)가 **정확히 일치**해야 한다.

```python
entry_points={
    'console_scripts': [
        'my_node = my_py_pkg.my_node:main'
    ],
},
```

지원 빌드 타입: `ament_cmake`, `ament_python`, `cmake`

## rosbag2 — 데이터 녹화/재생

출처: https://docs.ros.org/en/humble/Tutorials/Beginner-CLI-Tools/Recording-And-Playing-Back-Data/Recording-And-Playing-Back-Data.html

### 녹화

```bash
# 특정 토픽
ros2 bag record /topic1 /topic2

# 파일명 지정
ros2 bag record -o my_bag /topic1

# 전체 토픽
ros2 bag record -a
```

출력: `rosbag2_YYYY_MM_DD-HH_MM_SS/` 디렉토리 (metadata.yaml + .db3 파일)

### 재생

```bash
ros2 bag play my_bag
```

원래 발행 주기로 토픽��� 재발행한다.

### 정보 확인

```bash
ros2 bag info my_bag
```

파일 크기, 저장 형식, 기간, 메시지 수, 토픽 목록을 출력한다.

### 저장 형식

- 기본: SQLite3 (`.db3`)
- 직렬화: CDR
- QoS 오버라이드 가능 (녹화/재생 시)
