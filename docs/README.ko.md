# plem-marketplace

> **Language**: [English](../README.md) | 한국어

Claude Code 확장 기능(스킬, 에이전트, 훅, MCP 서버, LSP 서버)을 배포하기 위한 플러그인 마켓플레이스.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../LICENSE)

## 플러그인 목록

| 플러그인 | 버전 | 설명 |
| -------- | ---- | ---- |
| [plem-init](../plugins/plem-init) | 1.0.0 | plem 기반 로봇 프로젝트 초기화 위자드 |
| [zed-docs](../plugins/zed-docs) | 1.0.0 | ZED 카메라 ROS 2 통합 레퍼런스 |
| [register-plugin](../plugins/register-plugin) | 1.0.0 | 스킬 zip을 마켓플레이스 플러그인으로 등록/업데이트 |

## 빠른 시작

### 사용자

```shell
# 1. 마켓플레이스 추가 (최초 1회)
/plugin marketplace add WIM-Corporation/plem-marketplace

# 2. 플러그인 설치
/plugin install <plugin-name>@plem-marketplace

# 3. 리로드하여 활성화 (또는 Claude Code 재시작)
/reload-plugins

# 4. 사용
/<plugin-skill-name>
```

`/plugin` → **Discover** 탭에서 대화형으로 탐색/설치할 수도 있습니다.

### 플러그인 개발자

```shell
# 1. 플러그인 디렉토리 생성
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/skills/my-skill

# 2. 스킬 추가
cat > plugins/my-plugin/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: 이 스킬의 역할과 사용 시점
---

스킬 호출 시 Claude에게 전달할 지침.
EOF

# 3. marketplace.json에 등록
# .claude-plugin/marketplace.json의 plugins 배열에 항목 추가

# 4. 검증
claude plugin validate .

# 5. 로컬 테스트
claude --plugin-dir ./plugins/my-plugin
```

## 리포지토리 구조

```text
.
├── .claude-plugin/
│   └── marketplace.json       # 마켓플레이스 카탈로그
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json    # 플러그인 매니페스트 (선택)
│       ├── skills/            # Agent Skills (권장)
│       ├── agents/            # 서브에이전트
│       ├── hooks/             # 이벤트 핸들러
│       ├── .mcp.json          # MCP 서버
│       ├── .lsp.json          # LSP 서버
│       └── README.md
└── README.md
```

## 플러그인 추가 방법

1. `plugins/` 아래에 플러그인 디렉토리 생성
2. `skills/<name>/SKILL.md`에 최소 1개 스킬 추가
3. `.claude-plugin/marketplace.json`에 플러그인 항목 추가:

   ```json
   {
     "name": "my-plugin",
     "source": "./plugins/my-plugin",
     "description": "간단한 설명",
     "version": "1.0.0"
   }
   ```

4. README의 [플러그인 목록](#플러그인-목록) 테이블 업데이트
5. `claude plugin validate .`로 검증
6. 커밋 및 푸시

## 문서

- [플러그인 생성](https://code.claude.com/docs/ko/plugins)
- [플러그인 마켓플레이스](https://code.claude.com/docs/ko/plugin-marketplaces)
- [플러그인 기술 레퍼런스](https://code.claude.com/docs/ko/plugins-reference)
- [스킬](https://code.claude.com/docs/ko/skills)
- [훅](https://code.claude.com/docs/ko/hooks)
