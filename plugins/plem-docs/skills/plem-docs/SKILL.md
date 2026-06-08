---
name: plem-docs
description: "Provides the agent with the PLEM robot-control platform's Developer Manual — fetched live from the Depot server and version-matched to the PLEM build installed on the device (Context7-style). Use when the user works with a PLEM / Neuromeka Indy robot: trajectory control and FollowJointTrajectory goals, the ROS 2 topics, actions, and namespaces a PLEM robot exposes, launch files and the plem TUI (freedrive, brake), single- or multi-robot setup, emergency stop and recovery, safety, MoveIt motion planning, writing a custom PLEM controller plugin, the platform architecture, or initializing a PLEM-based ROS 2 project (.repos, colcon). Recognize robot model names like indy7 or indy12 as PLEM context even when the user doesn't say 'PLEM' or 'docs'. This is PLEM-specific — generic ROS 2 or ZED-SDK questions belong to other tools."
argument-hint: "[topic...]"
---

# plem-docs — 설치 버전에 맞는 PLEM 매뉴얼 (라이브)

설치된 PLEM 버전에 **정확히 일치하는** PLEM Developer Manual을 Depot에서 실시간으로 가져온다.
정적 번들이 아니라 라이브 서빙이므로 stale 되지 않는다 — Context7과 동일한 발상이다.

Depot은 버전별로 immutable revision을 보관하고 공개 경로로 익명 서빙한다. 이 스킬은
**(1) 디바이스에 설치된 PLEM 버전을 감지**하고 **(2) 그 버전의 `llms.txt`/챕터를 Depot에서 받아**
답변의 근거로 쓴다.

## Step 1 — 버전 감지 + 인덱스 가져오기 (번들 스크립트)

버전 감지 → 정규화 → Depot fetch → `latest` 폴백은 매 호출 동일하므로, 테스트된 단일
구현을 `scripts/plem-docs-fetch.sh`(이 SKILL.md와 같은 디렉터리)로 번들했다. 이걸 쓴다:

```bash
# 인자 없으면 llms.txt(인덱스). 예: interfaces.md, safety.md, llms-full.txt
bash "<이 스킬 디렉터리>/scripts/plem-docs-fetch.sh" [파일명]
```

스크립트가 하는 일 (스크립트를 못 쓰는 환경이면 아래 인라인을 그대로 실행):

```bash
DEPOT="${PLEM_DEPOT_URL:-https://depot.wimcorp.dev}"
FILE="llms.txt"                                            # 또는 interfaces.md 등

ver="$(dpkg-query -W -f='${Version}' plem 2>/dev/null)"   # plem 메타패키지 = 버전 SSoT
ver="${ver##*:}"; ver="${ver%%-*}"                        # epoch/revision strip (1:0.2.8-1 → 0.2.8)

curl -fsSL "${DEPOT}/docs/${ver:-latest}/${FILE}" \
  || curl -fsSL "${DEPOT}/docs/latest/${FILE}"            # 미발행/미설치 → latest(302)
```

왜 이렇게:
- **버전 SSoT**: `plem` 메타패키지 버전이 곧 매뉴얼 버전이다 (둘 다 `packaging/VERSION`에서 파생; 매뉴얼 빌더 `version.py`도 `plem`만 질의). `plem-core` 등 하위 패키지는 substvar(`PLEM_CORE_VERSION`)가 메타(`PLEM_META_VERSION`)와 달라 쓰지 않는다.
- **정규화**: 현재 빌드는 접미사가 없지만, epoch/revision이 붙어도(`1:0.2.8-1`) 업스트림 `0.2.8`로 매핑해 엉뚱한 `latest` 폴백을 막는다.
- **`-fsSL`**: `-L`로 302를 따라가고 `-f`로 404 시 실패시켜 `latest` 폴백을 트리거한다. `latest`로 갔다면 문서가 설치 버전보다 최신일 수 있음을 사용자에게 알린다.

## Step 2 — 필요한 문서만 읽기 (토큰 최적화)

`llms.txt`는 그 버전의 **권위 있는 목차**다. 라우팅이 불확실하면 먼저 받아 실제 챕터명·상대
링크를 확인하고, 챕터가 명확하면(예: `interfaces`) 곧장 그 파일을 받아도 된다 — 불필요한
왕복을 강요하지 않는다. 어느 경로든 같은 스크립트에 파일명을 넘긴다 (버전 정합·폴백 그대로 적용됨).

| 상황 | 가져올 것 |
|---|---|
| 특정 주제 1개 (예: 인터페이스, 안전) | 해당 챕터만: `plem-docs-fetch.sh <chapter>.md` |
| 여러 주제 / 프로젝트 전반 | 전체 본문 1회: `plem-docs-fetch.sh llms-full.txt` |

핵심: **타겟 챕터를 우선**하고, `llms-full.txt`는 정말 광범위할 때만 가져온다 (불필요한 컨텍스트 낭비 방지).

버전마다 `llms.txt`가 챕터 목록의 권위다. 아래는 참고용 빠른 경로다:
`overview` · `architecture` · `launch` · `interfaces` · `single-robot` · `multi-robot` ·
`stop-recovery` · `safety` · `custom-torque-controller-plugin`(플러그인 작성 가이드)

> `custom-torque-controller-plugin`은 외부 문서 pull-in이라 빌드에 따라 없을 수 있다 — 핵심 챕터들과 달리 조건부다. `llms.txt`를 권위로 삼아 실제 존재하는 챕터만 따라간다.

```bash
# 예: 인터페이스 챕터만
bash "<이 스킬 디렉터리>/scripts/plem-docs-fetch.sh" interfaces.md
```

## 라우팅 — PLEM vs 서드파티

이 마켓플레이스는 더 이상 서드파티 문서를 정적 번들로 들고 있지 않다. 라이브 소스로 라우팅한다:

| 질문 영역 | 소스 |
|---|---|
| **PLEM 플랫폼** (아키텍처·런치·인터페이스·단일/멀티로봇·정지/복구·안전·궤적제어·플러그인) | **Depot** `llms.txt` → 챕터 (이 스킬) |
| **ZED SDK** (`sl::Camera`, depth, object detection, `pyzed`, ROS 2 wrapper) | Context7 → 없으면 `stereolabs.com/docs` |
| **ROS 2** (colcon, QoS, TF2, launch, DDS, executor, lifecycle) | Context7 → 없으면 `docs.ros.org` (PLEM 배포판) |

서드파티는 라이브 문서로 라우팅한다 (정적 사본을 들고 staleness를 감수하던 옛 `zed-sdk`/`ros-docs` 스킬 대체):

1. **Context7 MCP가 있으면**: `resolve-library-id`로 라이브러리 ID를 찾고, `query-docs`로 문서를 받는다.
   *(도구 이름은 Context7 버전에 따라 `query-docs` 또는 구버전 `get-library-docs` — 노출된 MCP 도구 목록을 따른다.)*
2. **Context7가 없거나 그 라이브러리가 인덱싱돼 있지 않으면**: 공식 문서 사이트를 직접 웹으로 조회한다 —
   ROS 2는 PLEM이 현재 타깃하는 배포판(현 시점 `humble`)의 `docs.ros.org`, ZED는 `stereolabs.com/docs`.

Context7는 "라이브러리 등록(submit)" 방식이라 특정 패키지가 인덱싱돼 있다는 보장이 없다 — 위 폴백을 항상 갖춘다.

## 디스커버리 엔드포인트 (참고)

- `GET ${DEPOT}/llms.txt` — 사이트 루트 디스커버리 (→ 최신 인덱스 302, `Link: rel="llms-txt"` 헤더)
- `GET ${DEPOT}/.well-known/llms.txt` — 표준 well-known 별칭
- `GET ${DEPOT}/docs/latest` — 최신 버전 인덱스로 리다이렉트

## 동작 원칙

- **버전 정합 우선**: 설치된 PLEM과 *같은 버전*의 문서를 근거로 답한다. 버전이 다르면(폴백 포함) 그 사실을 밝힌다.
- **근거 우선**: PLEM 고유 사실(토픽·인터페이스·시퀀스·세이프티 동작 등)은 매뉴얼에 근거해 답하고, 매뉴얼에 없는 PLEM 고유 동작을 확정된 것처럼 지어내지 않는다 — 버전 정합의 핵심이다.
- **확장 자동 반영**: 새 챕터·새 버전은 `llms.txt`와 버전 감지로 자동 반영된다 (스킬 수정 불필요).
- **매뉴얼 미접근**(네트워크 실패 / 미발행 404): 먼저 그 사실을 알린다. 무조건 거부하지 말고, 일반 ROS 2·로보틱스 지식으로 도울 수 있으면 돕되 "버전 매뉴얼로 확인되지 않은 일반 안내"임을 명시한다. 금지선은 'PLEM 고유 사실을 매뉴얼 없이 단정하는 것' 하나다.

## 사용 패턴

```
/plem-docs                 → 질문 키워드로 자동 라우팅 (버전 감지 → llms.txt → 챕터)
/plem-docs interfaces      → 인터페이스 챕터 직접 조회
/plem-docs 안전 정지        → safety + stop-recovery 챕터
```
